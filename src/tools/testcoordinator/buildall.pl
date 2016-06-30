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



for my $machine (sort keys %machines) {
  my ($login, $sudo, $dir) = @{$machines{$machine}};
  my $cmd = "ssh $login \"cd $dir && $sudo git checkout $branch && $sudo git pull && $sudo make full\" ";
  logged($cmd, $machine);
}

while ((my $pid = wait) > 0) {print "Child pid $pid completed.\n";}
print "Buildall complete.\n";
exit;
