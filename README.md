### freenet-re-downloader

Freenet https://freenetproject.org is well known opensource distributed storage system,\
it works like big cache - nodes keep the file (more precisely chunks of file) while users continue downloading this file,\
so, if you want to extend file's lifetime you need to download it regularly,\
and this script can automate this task.

It is intended to be run on Linux server together with freenet node,\
it works in the background and constantly re-starts downloading selected files by simulating browser requests to the freenet web interface.

### Installation

Script doesn't require installation, but some packages are required.

### Required packages

First of all freenet node is required - see installation instructions https://freenetproject.org/pages/download.html

and those packages are used in the script (Ubuntu 16.04):
```
sudo apt install python2.7 wget libhtml-parser-perl
```

### Settings

settings are placed right in the script:

`nodeurl=http://127.0.0.1:8888`\
url of freenet web interface,

`downdir=/home/???/freenet/installed/downloads`\
where freenet saves downloaded files,

`frddir=/home/???/freenet/frd`\
the script can be run from any directory, but on start it cd-s to this directory,

`frddir_max_size=50100200300`\
the script copies downloaded files from $downdir to $frddir/completed/ so $frddir can become very big,\
and you can set this limit - if limit is reached then the script will delete some files and free up space,\
(if set to 0 then downloaded files will be just deleted without copying,)

`sleep=100`\
script's main task is to check and re-download selected files,\
it sleeps in the background and every $sleep seconds it will perform next check,

`logmaxsize=100100100`\
on start the script cd-s to $frddir and redirects all output to the log file,\
and since it is running 24/7 the log file constantly grows,\
and this is it's limit - after this limit the script will create new log and put (and compress) old log to the $frddir/logs-archive/ directory,

`freenetRestartIntervalDays=20`\
freenet is quite stable and can run during months,\
but sometimes it still can stuck, so the script can restart freenet process every this number of days,

`freenetRunScript=/home/???/freenet/installed/run.sh`\
path to freenet starting script,

`completedTooLongAgoDays=7`\
the script takes list of files and on every iteration (see above "sleep") it selects file randomly,\
so, there is no guarantee that all files will be downloaded absolutely regularly,\
if some file was last downloaded more than this number of days ago, then the script will start to check it more frequently,\
(and if twice number of days then it will try to re-upload file (if it still exists in the $frddir/completed/,)

`max_simult_downloads=3`\
if download queue is too big then downloads become slower and freenet can behave unreliably,\
the script will not start new downloads above this number,

`min_free_space=6100200300`\
the same purpose as "frddir_max_size" - to free up space,\
but here is vice versa - not maximal size but minimal free space,

`files_file=/home/???/freenet/frd/my-files.txt`\
path to file with list of files,\
the list is just bash array where every 4 elements represent one file: (name1 size1 md51 chk1 name2 size2...),\
example:
```
files+=(
  '65daysofstatic - Radio Protector.mp3'   7799421   caa8d9d2c1f1362fa4748f72145ec48b
  CHK@5rgnpjkCjtql8cbpeABKeC37mkw4XQ28I4cbp6XDWGs,-UJMj1KsmcDVvsq-oAgyh6dSDvQVS-~wMky1i5BNox8,AAMC--8
)
```

### Run

the script can be run from any directory,\
it can be run normally in foreground but you will see nothing because it redirects all output to the log file,\
to run it in the background use `nohup bash ./pdbs-180820-freenet-re-downloader.sh &`\
or you can add crontab job with @reboot keyword - see `man 1 crontab` and `man 5 crontab`\
e.g.\
`crontab -e`\
and add this line:\
`@reboot bash /home/???/freenet-re-downloader.sh`

### Control

the script redirects all output to the log file $frddir/frd-log-&lt;starting-date-and-time&gt;.txt\
the log is always detailed, there are no levels of verbosity,\
so, you can use standard `grep` and `less`\
e.g. to see general overview of how it is going:
```
grep -i -P 'check file|err|warn' /home/???/freenet/frd/frd-log-*.txt | less
```
another informative file is $frddir/frd-completed.txt\
the script writes here one line every time when one file has been downloaded successfully,\
so you can see for example the list of files sorted by last downloaded time:
```
perl -ne '/\((.+?)\) '\''(.+?)'\'' /; $x{$2}=$1; END {for (keys %x) {print "$x{$_} $_\n"}}' /home/???/freenet/frd/frd-completed.txt | sort
```

### TODO:

- find out how to calculate CHK and create helper script which will be able to add files to the list automatically without need of manual uploads and waiting when freenet will show CHK in browser,

- make more intelligent seletion of which file should be checked on next iteration,\
now the file is selected randomly and there is only one hard threshold $completedTooLongAgoDays,\
but it looks logically to invent some "weight" of file depending on last download time + some rating of importance,

- using API https://github.com/freenet/wiki/wiki/FCPv2 might be better than simulating browser requests,

- now the script works only with CHK links but there are also SSK and USK links,

