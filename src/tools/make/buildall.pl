#!perl -w
use strict;
use warnings;
use POSIX "strftime";
use Cwd;

my $branch = "v2docs";

my %machines = (
#  "pi"     => ['pi@pie',         "sudo", "projects/oberon/vishap/voc"],
#  "darwin" => ['dave@dcb',       "sudo", "projects/oberon/vishap/voc"],
#  "lub32"  => ['dave@lub32',     "sudo", "vishap/voc"],
#  "ob32"   => ['root@nas-ob32',  "",     "vishap/voc"],
#  "ce64"   => ['-p5922 obe@www', "sudo", "vishap/voc"],
#  "ub64"   => ['dave@nas-ub64',  "sudo", "vishap/voc"],
   "fb64"   => ['root@oberon',    "",     "vishap/voc"]
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


my %status = ();


sub parselog {
  my ($fn) = @_;
  #print "Parsing log $fn\n";
  my $date       = "";
  my $time       = "";
  my $branch     = "";
  my $os         = "";
  my $compiler   = "";
  my $datamodel  = "";
  my $compilerok = "";
  my $libraryok  = "";
  my $checksum   = "";
  my $tests      = "";
  open(my $log, $fn) // die "Couldn't open build log $fn.";
  while (<$log>) {
    if (/^([0-9\/]+) [0-9.]+ [^ ]+\.log$/) {$date = $1;}
    if (/^[^ ]+ --- Cleaning branch ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) ---$/) {
      ($branch, $os, $compiler, $datamodel) = ($1, $2, $3, $4, $5);
    }
    if (/^([0-9.]+) --- Compiler build successfull ---$/)    {$compilerok = "Built";}
    if (/^([0-9.]+) --- Library build successfull ---$/)     {$libraryok  = "Built";}
    if (/^([0-9.]+) --- Confidence tests passed ---$/)       {$tests      = "Passed";}
    if (/^([0-9.]+) --- Object file checksums match ---$/)   {$checksum   = "Unchanged";}
    if (/^([0-9.]+) --- Object file checksum mismatch ---$/) {$checksum   = "Changed";}
    if (/^([0-9.]+) --- Object files checksummed ---$/)      {$checksum   = "New";}
  }
  close($log);
  my $key = "$os-$compiler-$datamodel";
  if ($key ne "") {
    $status{$key} = [$fn, $date, $time, $os, $compiler, $datamodel, $branch, $compilerok, $libraryok, $checksum, $tests];
  }
}

opendir DIR, "log" // die "Could not open log directory.";
my @logs = readdir DIR;
closedir DIR;

for my $logname (sort @logs) {
  $logname = "log/" . $logname;
  #print "Consider $logname\n";
  if (-f $logname) {parselog($logname);}
}

my $fontheight = 10;
my $lineheight = 13;

sub svgtext {
  my ($f, $x, $y, $colour, $msg) = @_;
  print $f '<text x="', $x;
  print $f '" y="', ($y+1)*$lineheight + $fontheight/3;
  print $f '" font-family="Verdana" font-size="', $fontheight, 'px" fill="';
  print $f $colour;
  print $f '">';
  print $f $msg;
  print $f "</text>\n";
}

my $rows = keys %status;

my $width  = 680;
my $height = ($rows+2) * $lineheight;

open(my $svg, ">build-status.svg") // die "Could not create build-status.svg.";
print $svg '<svg width="680" height="', $height, '"';
print $svg ' xmlns="http://www.w3.org/2000/svg" version="1.1"';
print $svg ' xmlns:xlink="http://www.w3.org/1999/xlink"', ">\n";
print $svg '<rect x="3" y="3" width="', $width-6, '" height="', $height-6, '"';
print $svg ' rx="20" ry="20" fill="#404040"';
print $svg ' stroke="#20c020" stroke-width="4"/>', "\n";

my $col1 = 20;
my $col2 = 110;
my $col3 = 200;
my $col4 = 310;
my $col5 = 400;
my $col6 = 475;
my $col7 = 580;

svgtext($svg, $col1, 0, "#e0e0e0", "OS");
svgtext($svg, $col2, 0, "#e0e0e0", "Compiler");
svgtext($svg, $col3, 0, "#e0e0e0", "Data model");
svgtext($svg, $col4, 0, "#e0e0e0", "Compiler");
svgtext($svg, $col5, 0, "#e0e0e0", "Library");
svgtext($svg, $col6, 0, "#e0e0e0", "Checksum");
svgtext($svg, $col7, 0, "#e0e0e0", "Tests");

my $i=1;
for my $key (sort keys %status) {
  my ($fn, $date, $time, $os, $compiler, $datamodel, $branch,
      $compilerok, $libraryok, $checksum, $tests) = @{$status{$key}};
  print $svg '<a xlink:href="', $fn, '">';
  svgtext($svg, $col1, $i, "#c0c0c0", $os);
  svgtext($svg, $col2, $i, "#c0c0c0", $compiler);
  svgtext($svg, $col3, $i, "#c0c0c0", $datamodel);
  svgtext($svg, $col4, $i, "#60ff60", $compilerok);
  svgtext($svg, $col5, $i, "#60ff60", $libraryok);
  svgtext($svg, $col6, $i, "#60ff60", $checksum);
  svgtext($svg, $col7, $i, "#60ff60", $tests);
  print $svg '</a>';
  $i++;
}

print $svg "</svg>\n";

system 'scp build-status.svg dave@hub:/var/www';
system 'scp log/* dave@hub:/var/www/log';
