### freenet-re-downloader (frd)

Freenet (???link???) is well known public distributed storage system,
it works like big cache - nodes will keep the file while someone will download it,
so, if you want to extend file's lifetime you need to download it regularly,
and this script can help.

It is intended to be run on Linux server together with freenet node,
it works in the background and constantly (re)starts downloading selected files by simulating browser requests to the freenet web interface.

### Installation

Script doesn't require installation,
but some packages are required.

### Required packages

First of all freenet node is required - see installation instructions ???link to installation instruction???

and packages used in the script (Ubuntu 16.04):
sudo apt install python2.7 wget libhtml-parser-perl

### Settings

settings are placed in the beginning of the script:

**nodeurl=http://127.0.0.1:8888**
url of the freenet web interface,

**downdir=/home/???/freenet/installed/downloads**
where freenet saves downloaded files,

**frddir=/home/???/freenet/frd**
the script can be run from any directory but on start it cd-s to this directory,

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
but sometimes it still can stuck, so the script will restart freenet every this number of days,

**freenetRunScript=/home/???/freenet/installed/run.sh**
path to the freenet start script,

**completedTooLongAgoDays=7**
the script has list of files for downloading and on every iteration (see above "sleep") it selects file randomly,
so, there is no guarantee that all files will be downloaded exactly with constant frequency,
and if some file was last downloaded more than this number of days ago, then the script begins checking this file more frequently,

**max_simult_downloads=3**
if download queue is too big then downloads get slower and freenet even can behave unreliably,
so, the script won't start new downloads if this limit is reached,

**min_free_space=6100200300**
the same purpose as "frddir_max_size" above - free up space if limit reached,
(but here is vice versa - not maximal size but minimal free space)

**files_file=/home/???/freenet/frd/my-files.txt**


### Run
TBD
the script can be run from any directory,

### Control
TBD

