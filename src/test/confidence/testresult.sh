#!
# '.' this from indiviual test.sh files
if diff -b expected result
then printf "PASSED: $PWD\n\n"
else printf "FAILED: $PWD\n\n"; exit 1
fi
