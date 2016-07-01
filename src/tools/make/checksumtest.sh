# Checksum tests

md5=md5
if which md5sum >/dev/null 2>&1; then md5=md5sum; fi
if [ -f $1 ]
then
  $md5 *.o | egrep -v "OP[CM]\\.o" >newsums
  if diff -b $1 newsums
  then printf "\n--- Object file checksums match ---\n"
  else printf "\n--- Object file checksum mismatch ---\n"
  fi
  rm newsums
else
  $md5 *.o | egrep -v "OP[CM]\\.o" >$1
  printf "\n--- Object files checksummed ---\n"
fi
