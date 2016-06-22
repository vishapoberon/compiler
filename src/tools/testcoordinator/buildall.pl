#!perl -w
use strict;
use warnings;
use POSIX "strftime";

my $branch = "v2docs";

my %machines = (
  "pi"     => ['pi@pie',        "projects/oberon/vishap/voc", "sudo"],
  "darwin" => ['dave@dcb',      "projects/oberon/vishap/voc", "sudo"],
  "lub32"  => ['dave@lub32',    "vishap/voc",                 "sudo"],
  "ob32"   => ['root@nas-ob32', "vishap/voc",                 ""    ],
  "fb64"   => ['root@oberon',   "vishap/voc",                 ""    ],
  "ub64"   => ['dave@nas-ub64', "vishap/voc",                 "sudo"]
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
  my ($login, $dir, $sudo) = @{$machines{$machine}};
  my $cmd = "ssh $login \"cd $dir && $sudo git checkout $branch && $sudo git pull && $sudo make full\" ";
  logged($cmd, $machine);
}

while ((my $pid = wait) > 0) {print "Child pid $pid completed.\n";}
print "Buildall complete.\n";
exit;



#branch=v2docs
#ssh pi@pie "cd projects/oberon/vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh dave@dcb "cd projects/oberon/vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh dave@nas-ub64 "cd vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh dave@lub32 "cd vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh root@nas-ob32 "cd vishap/voc && git checkout $branch && make clean" &
#ssh root@oberon "cd vishap/voc && git checkout $branch && make clean" &

#for MACHINE in "${!VOCLOGIN[@]}"
#do
#SETBRANCH="${VOCSUDO[$MACHINE]} git checkout $branch"
#PULL="${VOCSUDO[$MACHINE]} git pull"
#MAKE="${VOCSUDO[$MACHINE]} make full"
#ssh ${VOCLOGIN[$MACHINE]} "cd ${VOCDIR[$MACHINE]} && $SETBRANCH && $PULL && $MAKE" | perl -pe "use POSIX strftime; print strftime \"%H:%M:%S $MACHINE: \", localtime" | tee log/$MACHINE.log &
#done
