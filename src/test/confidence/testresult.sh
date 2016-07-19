#!/bin/sh
# '.' this from indiviual test.sh files
if diff -b expected result
then printf "PASSED: $PWD\n\n"
else printf "FAILED: $PWD\n\n"; exit 1
fi

# Compare generated code
if [ -f old.s -a -f new.asm ]
then
  egrep '^[0-9 ]{4} ([0-9a-f]{4}|    ) [0-9A-F]{2}[0-9A-F ]{6}' new.asm|cut -c 11- >new.s
  if ! diff -b old.s new.s
  then echo "--- Generated code changed ---"
  fi
fi
