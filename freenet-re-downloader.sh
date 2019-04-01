#!/bin/bash

# TODO: ?maybe join with pdb-scripts?

# (triple curly brackets are for code folding in jEdit)
# description: {{{

# purpose: constantly download selected files and thus extend their existance in freenet,

# detached background command which will continue after logging out ssh session:
# nohup bash ./pdbs-180820-freenet-re-downloader.sh &

# how to add startup task (https://stackoverflow.com/questions/4880290/how-do-i-create-a-crontab-through-a-script):
# (crontab -l 2>/dev/null; echo "@reboot bash /home/???/freenet-re-downloader.sh") | crontab -

# some useful commands:
# sort files by last completed date:
# cat frd/frd-completed.txt | perl -ne '/\((.+?)\) '\''(.+?)'\'' /; $x{$2}=$1; END {for (keys %x) {print "$x{$_} $_\n"}}' | sort

# show log with errors and warnings:
# command grep -P -i 'check file|err|warn' frd/frd-log-*.txt | less

# }}}

# TODO: check required programs and modules

exec 33> /tmp/${0##*/}.lock || { echo $(date) $0: could not open lock descriptor; exit 1; }
flock --exclusive --nonblock 33 || { echo $(date) $0: script is already running; exit 1; }

# TODO: separate configuration file
nodeurl=http://127.0.0.1:8888
downdir=/home/???/freenet/installed/downloads
frddir=/home/???/freenet/frd
frddir_max_size=50100200300
sleep=100
logmaxsize=100100100
freenetRunScript=/home/???/freenet/installed/run.sh
freenetRestartIntervalDays=20
completedTooLongAgoDays=7
max_simult_downloads=3
min_free_space=6100200300

files_file=/home/???/freenet/frd/my-files.txt
function read_files_array { # {{{
	if [[ ! -s "$files_file" ]]
	then
		error files_file "$files_file" not found
		exit 1
	fi
	local x=$(stat -c%Y "$files_file")
	[[ $x == $files_file_mtime ]] && return
	files_file_mtime=$x
	log read files array
	source "$files_file"
	# should be bash array (name1 size1 md5-1 chk1   name2 size2 md5-2 chk2...),
	# e.g.:
	# files=(
	#   ttt-181104-144823.7z  30743529  9044997a3d7e1dff9765fac373c96b13
	#   CHK@pdRzW0OhpcvujwSLJvhNvTn5te~BMra2ZOx9CulqgB0,zVS7bX7EJcljspurDLLyqTf8vtoO~-fAPDIAqMQYVo8,AAMC--8
	#
	#   '65daysofstatic - Radio Protector.mp3'   7799421   caa8d9d2c1f1362fa4748f72145ec48b
	#   CHK@5rgnpjkCjtql8cbpeABKeC37mkw4XQ28I4cbp6XDWGs,-UJMj1KsmcDVvsq-oAgyh6dSDvQVS-~wMky1i5BNox8,AAMC--8
	# )
	log files array size is ${#files[*]}
	if (( ${#files[*]} == 0 || ${#files[*]}%4 != 0 ))
	then
		error files array size must be multiple of 4
		exit 1
	fi
	seq 0 $(( ${#files[*]}/4 - 1 )) | while read ii; do echo "/${files[$ii*4]}"; done >all-file-names.txt
	find "$downdir" "$frddir/completed" -type f -not -name '*.freenet-tmp' | grep -v -F -f all-file-names.txt && warning unlisted files found
	tooLongAgoList=()
} # }}}

function mydate { date +%F-%T; }
function log { echo $(mydate): LOG: "$@"; }
function error { echo $(mydate): ERROR: "$@"; }
function warning { echo $(mydate): WARNING: "$@"; }
function sleep { log sleep $1; echo; command sleep $1; }
function urlencode { python -c 'import urllib; print urllib.quote(raw_input())'; }
function init { # {{{
	set -e
	cd $frddir

	# TODO: check settings

	x=$(mydate).txt
	exec 1>&- 2>&-
	exec 1>$x 2>&1
	echo $0 log $x started in "$PWD"

	[[ -d $downdir ]]
	mkdir -pv completed logs-archive
	ls -l frd-log-* && mv -v frd-log-* logs-archive
	xz -v logs-archive/*.txt

	logfile=frd-log-$x
	mv -v $x $logfile
	set +e
} # }}}

set -x
init
set +x

function next_i {
	declare -p tooLongAgoList
	canStartDownload=1
	if (( ${#tooLongAgoList[*]} > 0 ))
	then
		if (( $RANDOM > 32768/2 ))
		then
			i=${tooLongAgoList[0]}
			tooLongAgoList=(${tooLongAgoList[*]:1})
			return
		fi
		(( $RANDOM > 32768/2 )) && canStartDownload=
	fi
	i=$(( $(shuf -i0-$(( ${#files[*]}/4 - 1 )) -n1) * 4 ))
}
while [[ 1 ]] # {{{
do

	echo
	[[ $notfirst ]] && sleep $sleep
	notfirst=1
	# TODO: automatic restart if script file changed

	read_files_array
	next_i

	echo ========================================================================================================================
	log next loop
	echo

	# TODO: if no free space left then print warning and continue to the next loop

	log check log size # {{{
	set -x
	if (( $(stat -c%s $logfile) > $logmaxsize ))
	then
		warning log file size exceeds maximum - start new
		init
	fi
	set +x
	echo # }}}

	log check frddir_max_size and min_free_space # {{{
	du -bs $frddir >tmp.txt
	if (( $(awk '{print $1}' tmp.txt) > $frddir_max_size ))
	then
		warning frddir_max_size exceeded: $(< tmp.txt)
		find completed -type f -mtime -$completedTooLongAgoDays -ls -delete -quit
		find logs-archive -mtime +365 -ls -delete
	fi
	df --block-size=1 --output=avail,file $frddir >tmp.txt
	if (( $(awk 'END {print $1}' tmp.txt) < min_free_space ))
	then
		warning min_free_space reached: $(< tmp.txt)
		find completed -type f -mtime -$completedTooLongAgoDays -ls -delete -quit
		find logs-archive -mtime +365 -ls -delete
	fi
	echo # }}}

	log check freenet restart interval # {{{
	if ! ps -A -o pid,etimes,args | grep '\bwrapper.*Freenet.pid' >tmp.txt
	then
		warning freenet process not found - start
		# TODO: if freenet/wrapper.conf size == 0 restore it from backup copy (strange issue I saw several times with freenet v1478)
		$freenetRunScript start
		continue
	else
		cat tmp.txt
		read pid seconds rest <tmp.txt
		if (( $seconds > 60*60*24*$freenetRestartIntervalDays ))
		then
			warning freenet is running more than $freenetRestartIntervalDays days - restart
			$freenetRunScript stop
			continue
		fi
	fi
	echo # }}}

	log remove finished downloads # {{{
	rm -fv tmp.txt
	if ! wget -O tmp.txt $nodeurl/downloads/?fproxyAdvancedMode=1
	then
		error wget downloads/ failed
		sleep 1
		tail $logfile | grep 'Freenet is starting up' && { # https://www.google.com/search?q=freenet+not+enough+entropy
			warning increase entropy
			find / -ls >/dev/null 2>&1
		}
		continue
	else
		formpass=$(perl -n -e 'if (/formPassword.*?value="(.+)"/) {print $1; exit}' tmp.txt)
		if [[ -z $formpass ]]
		then
			error get form password failed
			continue
		elif ! wget -O tmp.txt --post-data "formPassword=$formpass&remove_finished_downloads_request=1" $nodeurl/downloads/
		then
			error remove finished downloads failed
			continue
		fi
	fi # }}}
	sleep 5

	log check failed downloads # {{{
	failed="$(sed -n -e '/<form.*failed-download/,/form>/p' tmp.txt)"
	if [[ $failed ]]
	then
		warning failed downloads found:
		perl -ne '$x.=$_; END {$x=~s/<.+?>/ /g; $x=~s/\s+/ /g; $x=~s/^\s+|\s+$//g; print "$x\n"}' <<<"$failed"
		postData="formPassword=$formpass&remove_request=1"
		while read n v
		do
			echo "$n: $v"
			[[ $n =~ identifier ]] && postData+="&$n=$(urlencode <<<"$v")"
			[[ $n =~ filename ]] && rm -v "$downdir/$v"
		done < <(echo "$failed" | perl -ne 'use HTML::Entities; /name="((?:identifier|filename)-\d+).+value="(.+)"/ && print decode_entities "$1 $2\n"')
		echo "$postData"
		if ! wget -O tmp.txt --post-data "$postData" $nodeurl/downloads/
		then
			error cancelling failed downloads failed
			continue
		fi
	fi # }}}
	sleep 5

	name="${files[i]}"
	size=${files[i+1]}
	md5=${files[i+2]}
	key="${files[i+3]}"

	log "check file $i: '$name' $size $md5" # {{{
	ls -l "$downdir/$name"
	exists=$?
	md5sum "$downdir/$name" | grep $md5
	md5sumok=$?
	sed -i -e 's/^[[:blank:]]*//' tmp.txt || continue # no space left is possible
	grep -F "$key" tmp.txt
	inTheList=$?
	if [[ $exists == 0 && $md5sumok != 0 ]]
	then
		error md5sum is different
	elif [[ $exists == 0 && $md5sumok == 0 && $inTheList == 0 ]]
	then
		error download complete but file is still present in the downloads list
	elif [[ $exists == 0 && $md5sumok == 0 && $inTheList != 0 ]] # {{{
	then
		log download complete
		echo $(date +'%s (%F %T)') "'$name' $size $md5 $key" >>frd-completed.txt
		mv -v "$downdir/$name" $frddir/completed
	# }}}
	elif [[ $exists != 0 && $inTheList != 0 ]] # {{{
	then
		x=$(perl -ne 'if (/<li><a href="#uncompletedDownload">Downloads in progress \((\d+)\)</) {print STDERR $_; print $1; exit}' <tmp.txt)
		if (( x >= max_simult_downloads ))
		then
			log max_simult_downloads exeeded
		elif [[ ! $canStartDownload ]]
		then
			log do not start download because of tooLongAgoList
		else
			log start download
			if ! wget -O tmp.txt --post-data "formPassword=$formpass&key=$(urlencode <<<"$key/$name")&return-type=disk&persistence=forever&download=1&path=$downdir" $nodeurl/downloads/
			then
				error start download failed
			fi
		fi
	# }}}
	elif [[ $inTheList == 0 ]] # {{{
	then
		grep -P 'CHK@|ago$|%$' tmp.txt | grep -F "freenet:$key" -A3 | tee tmp2.txt
		if grep 'h.*ago$' tmp2.txt
		then
			warning last progress was hours ago - restart
			if ! wget -O tmp.txt --post-data "formPassword=$formpass&remove_request=1&identifier-0=FProxy:$(urlencode <<<"$name")" $nodeurl/downloads/
			then
				error remove stuck download failed
			fi
		elif grep 'h.*ago$' tmp2.txt
		then
			warning last progress was hours ago
		fi
	# }}}
	fi
	echo # }}}

	log check when file was last time completed # {{{
	if ! grep $md5 frd-completed.txt >tmp.txt
	then
		warning file was never completed yet
		tooLongAgoList+=($i)
	elif (( $(date +%s) - $(awk 'END {print $1}' tmp.txt) > $completedTooLongAgoDays*24*60*60 ))
	then
		warning file last time completed was too long ago:
		tail tmp.txt
		tooLongAgoList+=($i)
		# TODO: if $inTheList then increase download priority,
	else
		tooLongAgoList=($(echo ${tooLongAgoList[*]} | sed "s/\b$i\b//g"))
	fi # }}}

done # }}}

