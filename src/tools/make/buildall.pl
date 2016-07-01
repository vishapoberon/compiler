#!perl -w
use strict;
use warnings;
use POSIX "strftime";

my $branch = "v2docs";

my %machines = (
  "pi"     => ['pi@pie',         "sudo", "projects/oberon/vishap/voc"],
  "darwin" => ['dave@dcb',       "sudo", "projects/oberon/vishap/voc"],
  "lub32"  => ['dave@lub32',     "sudo", "vishap/voc"],
  "ob32"   => ['root@nas-ob32',  "",     "vishap/voc"],
  "fb64"   => ['root@oberon',    "",     "vishap/voc"],
  "ub64"   => ['dave@nas-ub64',  "sudo", "vishap/voc"],
  "ce64"   => ['-p5922 obe@www', "sudo", "vishap/voc"]
);


sub logged {
  my ($cmd, $id) = @_;
  my $child = fork;
  if (not defined $child) {die "Fork failed.";}
  if ($child) {
    # parent process
    print "Started $id, pid = $child\n";
  } else {
    # child process
    open(my $log, ">log/$id.log") // die "Could not create log file log/$id.log";
    print $log strftime("%Y/%m/%d %H.%M.%S ", localtime), "$id.log\n";
    print $log strftime("%H.%M.%S", localtime), "> $cmd\n";
    print $id, " ", strftime("%H.%M.%S", localtime), "> $cmd\n";
    open(my $pipe, "$cmd 2>&1 |") // die "Could not open pipe from command $cmd.";
    while (<$pipe>) {
      my $line = $_;
      print $id, " ", strftime("%H.%M.%S", localtime), " ", $line;
      print $log strftime("%H.%M.%S", localtime), " ", $line;
    }
    close($pipe);
    close($log);
    exit;
  }
}


unlink glob "log/*";

for my $machine (sort keys %machines) {
  my ($login, $sudo, $dir) = @{$machines{$machine}};
  my $cmd = "ssh $login \"cd $dir && $sudo git checkout $branch && $sudo git pull && $sudo make full\" ";
  logged($cmd, $machine);
}

while ((my $pid = wait) > 0) {print "Child pid $pid completed.\n";}


# # All builds have completed. Now scan the logs for pass/fail and build the passing report.
#
# my %status = ();
# open(my $logs, "/tmp/buildall.log") // die "Couldn't open combined build log.";
# while (<$logs>) {
#   if (/^([^ ]+) ([^ ]+) --- Branch ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) confidence tests passed ---/) {
#     $status{$1} = [$2, $3, $4, $5, $6];
#   }
# }
# close(my $logs);
#
#
# sub svgtext {
#   my ($f, $x, $y, $msg) = @_;
#   print($f "<text x=\"$x\" y=\"$y\" font-family=\"Verdana\" font-size=\"18\" font-fill=\"black\">";
#   print($f $msg);
#   print($f "</text>\n");
# }
#
#
# open(my $svg, ">passing.svg") // dir "Could not create passing.svg.");
# print $svg '<svg width="10cm" height="3cm" viewBox="0 0 1000 300" xmlns="http://www.w3.org/2000/svg" version="1.1">\n';
#
# my $i=1;
# for my $host (sort keys %status) {
#   svgtext($svg, 10, $i*20, $host);
#   $i++;
# }
#
# print $svg '</svg>\n';
