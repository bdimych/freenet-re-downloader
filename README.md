### freenet-re-downloader (frd)

Freenet (???link???) is well known public distributed storage system,
it works like big cache - nodes will keep the file while someone downloads it,
so, if you want to extend file's lifetime you need to download it regularly,
and this script does this.

It is intended to be run on Linux server together with freenet node,
it works in the background and constantly (re)starts downloading selected files by simulating browser requests to the node's web interface.

### Installation

Script doesn't require installation, but some packages are required.

### Required packages

First of all freenet node is required - see installation instructions ???link to installation instruction???

and packages used in the script (Ubuntu 16.04):
sudo apt install python2.7 wget libhtml-parser-perl

### Settings

settings are written in the beginning of the script:

**nodeurl=http://127.0.0.1:8888**
url of the node's web interface,

**downdir=/home/???/freenet/installed/downloads**
where freenet saves downloaded files,

**frddir=/home/???/freenet/frd**
the script can be run from any directory but it cd-s to this directory on start,

**frddir_max_size=50100200300**
the script copies downloaded files to the $frddir/completed/ so $frddir can become very big,
and this is the limit - if it is reached then the script will start to delete some files in order to free up space,

**sleep=100**
script's main task is to check and re-download selected files,
it is designed to work 24/7 in the background and every $sleep seconds it will do next check,

**logmaxsize=100100100**
on start, the script cd-s to $frddir and redirects it's output to the log file,
and since it is running 24/7 the log file constantly grows,
and this is the limit - after this limit the script will create new log file and put compressed old log file to the $frddir/logs-archive/ directory,

**freenetRestartIntervalDays=20**
freenet is quite stable software and can work during months without problems,
but sometimes it can stuck, so the script will restart freenet every this number of days,

**freenetRunScript=/home/???/freenet/installed/run.sh**
TBD

completedTooLongAgoDays=7
TBD

max_simult_downloads=3
TBD

min_free_space=6100200300
TBD

files_file=/home/???/freenet/frd/my-files.txt
TBD

### Run
TBD
the script can be run from any directory,

### Control
TBD

