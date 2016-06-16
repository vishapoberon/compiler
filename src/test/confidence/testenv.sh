## '.' this file from individual test.sh files.
#set -e
if which cygpath >/dev/null
then export PATH="$(cygpath "$1")/bin":$PATH
else export PATH="$1/bin":$PATH
fi
# Set ibrary paths for darwin and termux(android)
export DYLD_LIBRARY_PATH=$1/lib:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=$1/lib:$LD_LIBRARY_PATH
rm -f *.o *.obj *.exe *.sym *.c *.h result
