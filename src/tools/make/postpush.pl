#!/usr/bin/perl -w


use strict;
use warnings;
use POSIX "strftime";


use CGI qw(:standard escapeHTML);
use JSON;

sub writelog {
  my ($msg) = @_;

  open(LOG, ">>/tmp/postpush.log") or die "Could not create postpush.log";
  flock(LOG, 2)                    or die "Could not lock postpush.log";
  print LOG sprintf("%s %s\n", strftime("%Y/%m/%d %H.%M.%S", localtime), $msg);
  close(LOG);
}

my $postdata = from_json(param('POSTDATA'));

my $url  = $postdata->{'repository'}->{'url'};
my $ref  = $postdata->{'ref'};
my $name = $postdata->{'head_commit'}->{'author'}->{'name'};

my $branch = $ref;  $branch =~ s'^.*\/'';
my $repo   = $url;  $repo   =~ s'^.*\/'';

#my $repo="repo"; my $branch="branch"; my $name="name";

writelog "Post push github web hook for repository $repo, branch $branch, name $name.";


my $child = fork;
if (not defined $child) {die "Fork failed.";}
if ($child) {
  # parent process
  writelog "Started buildall, pid = $child.";
} else {
  # child process
  close(STDIN); close(STDOUT); close(STDERR);
  system 'wget https://raw.githubusercontent.com/vishaps/voc/v2docs/src/tools/make/buildall.pl';
  exec 'perl buildall.pl >/tmp/buildall.log';
  exit;
}

print header(),
  start_html("Vishap Oberon github post push web hook."),
  p("Repository $repo, branch $branch, name $name."),
  end_html();
