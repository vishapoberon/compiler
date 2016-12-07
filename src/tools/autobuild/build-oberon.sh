# Build Oberon
#
# Args
#
# $1 - whether to use sudo
# $2 - build directory
# $3 - CC

if test "$1" = "sudo"; then sudo=sudo; else sudo=""; fi

echo Testing: \$1="$1", \$2="$2", \$3="$3", \$sudo="$sudo"
exit

set -x
cd $2

$sudo git reset --hard    # Clear the staging area
$sudo git clean -dfx      # Remove all untracked files
$sudo git pull            # Update the local repository
$sudo git checkout -f $1  # Switch to requested branch

export CC=$3
$sudo make full