# Checksum tests

md5=$((which md5;which md5sum)2>/dev/null)
if [ -f $1 ]
then
  $md5 *.o >newsums
  if diff -b $1 newsums
  then printf "\n--- Object file checksums match ---\n"; rm newsums
else printf "\n--- Object file checksum mismatch ---\n"; rm newsums; exit 1
  fi
else
  $md5 *.o >$1
  printf "\n--- Object files checksummed ---\n"
fi
