#!perl -w
use strict;
use warnings;
use POSIX "strftime";
use Cwd;

my $branch = "master";

my %machines = (
  "pi"      => ['pi@pie',          "sudo", "projects/oberon/vishap/voc", "make full"],
  "darwin"  => ['dave@dcb',        "sudo", "projects/oberon/vishap/voc", "make full"],
  "wind"    => ['-p5932 dave@wax', "",     "vishaps/voc",                "export CC=gcc && make full;"
                                                                       . "export CC=i686-w64-mingw32-gcc && make full;"
                                                                       . "cd ~;"
                                                                       . "sh start64.sh \\\"cd vishaps/voc && git checkout $branch && git pull;"
                                                                                         . "export CC=gcc && make full;"
                                                                                         . "export CC=x86_64-w64-mingw32-gcc && make full\\\""],
  "android" => ['-p8022 root@and', "",     "vishap/voc",                 "export CC=gcc && make full"],
  "lub32"   => ['dave@lub32',      "sudo", "vishap/voc",                 "make full"],
  "ob32"    => ['root@nas-ob32',   "",     "vishap/voc",                 "make full"],
  "ce64"    => ['-p5922 obe@www',  "sudo", "vishap/voc",                 "make full"],
  "ub64"    => ['dave@nas-ub64',   "sudo", "vishap/voc",                 "make full"],
  "fb64"    => ['root@oberon',     "",     "vishap/voc",                 "make full"]
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
  my ($login, $sudo, $dir, $mkcmd) = @{$machines{$machine}};
  my $cmd = "ssh $login \"cd $dir && $sudo git checkout $branch && $sudo git pull && $sudo $mkcmd\" ";
  logged($cmd, $machine);
}

while ((my $pid = wait) > 0) {print "Child pid $pid completed.\n";}


# # All builds have completed. Now scan the logs for pass/fail and build the passing report.


my %status = ();

my $fn;
my $date;
my $time;
my $branch;
my $os;
my $compiler;
my $datamodel;
my $compilerok;
my $libraryok;
my $sourcechange;
my $tests;
my $key;
my $ver;

sub clearvars {
  $time         = "";  $branch       = "";  $os           = "";  $compiler     = "";
  $datamodel    = "";  $compilerok   = "";  $libraryok    = "";  $sourcechange = "";
  $tests        = "";  $key          = "";  $ver          = "";
}

sub logstatus {
  my ($fn) = @_;
  if ($compiler ne "") {
    $status{"$os-$compiler-$datamodel"} =
      [$fn, $date, $time, $os, $compiler, $datamodel, $branch, $compilerok, $libraryok, $sourcechange, $tests];
  }
  clearvars();
}

sub parselog {
  ($fn) = @_;
  clearvars();
  open(my $log, $fn) // die "Couldn't open build log $fn.";
  while (<$log>) {
    if (/^([0-9\/]+) ([0-9.]+) .+\.log$/) {$date = $1}
    if (/^([0-9.]+) /)                    {$time = $1}
    # 19.39.58 Configuration: 1.95 [2016/07/14] for gcc LP64 on centos
    if (/^[^ ]+ Configuration: ([0-9a-zA-Z.]+) \[[0-9\/]+\] for (.+) *$/) {
      logstatus($fn);
      $ver = $1;
      printf "--- Config for $fn: $1 for $2.\n";
    }
    if (/^[^ ]+ --- Cleaning branch ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) ---$/) {
      ($branch, $os, $compiler, $datamodel) = ($1, $2, $3, $4, $5);
    }
    if (/^([0-9.]+) --- Compiler build started ---$/)                         {$compilerok   = "Failed";}
    if (/^([0-9.]+) --- Compiler build successfull ---$/)                     {$compilerok   = "Built";}
    if (/^([0-9.]+) --- Library build started ---$/)                          {$libraryok    = "Failed";}
    if (/^([0-9.]+) --- Library build successfull ---$/)                      {$libraryok    = "Built";}
    if (/^([0-9.]+) --- Generated c source files match bootstrap ---$/)       {$sourcechange = "Unchanged";}
    if (/^([0-9.]+) --- Generated c source files differ from bootstrap ---$/) {$sourcechange = "Changed";}
    if (/^([0-9.]+) --- Confidence tests started ---$/)                       {$tests        = "Failed";}
    if (/^([0-9.]+) --- Confidence tests passed ---$/)                        {$tests        = "Passed";}
  }
  close($log);
  logstatus($fn);
}

opendir DIR, "log" // die "Could not open log directory.";
my @logs = readdir DIR;
closedir DIR;

for my $logname (sort @logs) {
  $logname = "log/" . $logname;
  #print "Consider $logname\n";
  if (-f $logname) {parselog($logname);}
}

my $fontheight = 12;
my $lineheight = 15;

sub svgtext {
  my ($f, $x, $y, $colour, $msg) = @_;
  print $f '<text x="', $x;
  print $f '" y="', ($y+1)*$lineheight + $fontheight*0.4;
  print $f '" font-family="Verdana" font-size="', $fontheight, 'px" fill="';
  print $f $colour;
  print $f '">';
  print $f $msg;
  print $f "</text>\n";
}

my $rows = keys %status;

my $width  = 630;
my $height = ($rows+2.2) * $lineheight;

open(my $svg, ">build-status.svg") // die "Could not create build-status.svg.";
print $svg '<svg width="680" height="', $height, '"';
print $svg ' xmlns="http://www.w3.org/2000/svg" version="1.1"';
print $svg ' xmlns:xlink="http://www.w3.org/1999/xlink"', ">\n";
print $svg '<rect x="3" y="3" width="', $width-6, '" height="', $height-6, '"';
print $svg ' rx="20" ry="20" fill="#404040"';
print $svg ' stroke="#20c020" stroke-width="4"/>', "\n";

my $col1  = 20;
my $col2  = 97;
my $col3  = 160;
my $col4  = 220;
my $col5  = 280;
my $col6  = 330;
my $col7  = 380;
my $col8  = 440;
my $col9  = 490;
my $col10 = 570;

svgtext($svg, $col1,  0, "#e0e0e0", "Date");
svgtext($svg, $col3,  0, "#e0e0e0", "Branch");
svgtext($svg, $col4,  0, "#e0e0e0", "Platform");
svgtext($svg, $col7,  0, "#e0e0e0", "Compiler");
svgtext($svg, $col8,  0, "#e0e0e0", "Library");
svgtext($svg, $col9,  0, "#e0e0e0", "C Source");
svgtext($svg, $col10, 0, "#e0e0e0", "Tests");

my $i=1;
for my $key (sort keys %status) {
  my ($fn, $date, $time, $os, $compiler, $datamodel, $branch,
      $compilerok, $libraryok, $sourcechange, $tests) = @{$status{$key}};
  print $svg '<a xlink:href="', $fn, '">';
  svgtext($svg, $col1,  $i, "#c0c0c0", $date);
  svgtext($svg, $col2,  $i, "#c0c0c0", $time);
  svgtext($svg, $col3,  $i, "#c0c0c0", $branch);
  svgtext($svg, $col4,  $i, "#c0c0c0", $os);
  svgtext($svg, $col5,  $i, "#c0c0c0", $compiler);
  svgtext($svg, $col6,  $i, "#c0c0c0", $datamodel);
  svgtext($svg, $col7,  $i, "#60ff60", $compilerok);
  svgtext($svg, $col8,  $i, "#60ff60", $libraryok);
  svgtext($svg, $col9,  $i, "#60ff60", $sourcechange);
  svgtext($svg, $col10, $i, "#60ff60", $tests);
  print $svg '</a>';
  $i++;
}

print $svg "</svg>\n";

system 'chmod +r log/*';
system 'scp build-status.svg dave@hub:/var/www';
system 'scp log/* dave@hub:/var/www/log';
