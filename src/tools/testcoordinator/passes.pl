#!perl -w
use strict;
use warnings;
use POSIX "strftime";

# Now parse the combined logs extracting build pass messages
# lub32 20.47.55 --- Branch v2docs ubuntu gcc ILP32 confidence tests passed ---

open(my $buildlog, "</tmp/buildall.log") // die "Could not read buildall.log.";
open(my $passes,   ">log/buildpasses.log") // die "Could not create buildpasses.log.";
while (<$buildlog>) {
  if (/ --- Branch .* confidence tests passed ---/) {
    print $passes $_;
  }
}
close($buildlog);
close($passes);
