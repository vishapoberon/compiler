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

writelog "Postpush.";

my $postdata = from_json(param('POSTDATA'));

my $url  = $postdata->{'repository'}->{'url'};
my $ref  = $postdata->{'ref'};
my $name = $postdata->{'head_commit'}->{'author'}->{'name'};

my $branch = $ref;  $branch =~ s'^.*\/'';
my $repo   = $url;  $repo   =~ s'^.*\/'';

#my $repo="repo"; my $branch="branch"; my $name="name";

writelog "Repository $repo, branch $branch, name $name.";

print header(),
  start_html("Vishap Oberon github post push web hook."),
  p("Repository $repo, branch $branch, name $name."),
  end_html();

system 'ssh root@oberon perl vishap/voc/src/tools/testcoordinator/buildall.pl >/tmp/buildall.log &';

writelog "Buildall triggered."
