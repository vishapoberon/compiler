#!perl -w
use strict;
use warnings;
use POSIX "strftime";




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
    if (/^([0-9.]+) --- Object file checksums match ---$/)   {$checksum   = "Match";}
    if (/^([0-9.]+) --- Object file checksum mismatch ---$/) {$checksum   = "Changed";}
    if (/^([0-9.]+) --- Object files checksummed ---$/)      {$checksum   = "New";}
  }
  close($log);
  my $key = "$os-$compiler-$datamodel";
  if ($key ne "") {
    $status{$key} = [$date, $time, $os, $compiler, $datamodel, $branch, $compilerok, $libraryok, $checksum, $tests];
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

my $emsperline = 1.2;

sub svgtext {
  my ($f, $x, $y, $colour, $msg) = @_;
  print $f '<text x="', $x;
  print $f '" y="', ($y+1)*$emsperline + 0.3;
  print $f 'em" font-family="Verdana" font-size="1em" fill="';
  print $f $colour;
  print $f '">';
  print $f $msg;
  print $f "</text>\n";
}

my $rows = keys %status;

open(my $svg, ">build-status.svg") // die "Could not create build-status.svg.";
print $svg '<svg width="680" height="';
print $svg ($rows+2) * $emsperline;
print $svg 'em" xmlns="http://www.w3.org/2000/svg" version="1.1">', "\n";
print $svg '<rect width="100%" height="100%" rx="20" ry="20" fill="#404040"/>', "\n";

my $col1 = 20;
my $col2 = 110;
my $col3 = 200;
my $col4 = 310;
my $col5 = 400;
my $col6 = 490;
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
  my ($date, $time, $os, $compiler, $datamodel,
      $branch, $compilerok, $libraryok, $checksum, $tests) = @{$status{$key}};
  svgtext($svg, $col1, $i, "#c0c0c0", $os);
  svgtext($svg, $col2, $i, "#c0c0c0", $compiler);
  svgtext($svg, $col3, $i, "#c0c0c0", $datamodel);
  svgtext($svg, $col4, $i, "#60ff60", $compilerok);
  svgtext($svg, $col5, $i, "#60ff60", $libraryok);
  svgtext($svg, $col6, $i, "#60ff60", $checksum);
  svgtext($svg, $col7, $i, "#60ff60", $tests);
  $i++;
}

print $svg "</svg>\n";

system 'scp -p build-status.svg dave@hub:/var/www';
