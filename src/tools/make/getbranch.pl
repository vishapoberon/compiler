#!perl -w
use strict;
use warnings;

# Exit with a clean enlistrment in the named branch.

my $branch = "master";
if (defined($ARGV[0]) && ($ARGV[0] ne "")) {$branch = $ARGV[0]}

set -x
git reset --hard        # Clear the staging area
git clean -dfx          # Remove all untracked files
git pull                # Update the local repository
git checkout -f $branch # Switch to requested branch
