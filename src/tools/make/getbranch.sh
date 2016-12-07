set -x
git reset --hard    # Clear the staging area
git clean -dfx      # Remove all untracked files
git pull            # Update the local repository
git checkout -f $1  # Switch to requested branch
