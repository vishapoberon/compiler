#!/usr/bin/perl -w


use strict;
use warnings;


use CGI qw(:standard escapeHTML);
use JSON;


my $postdata = from_json(param('POSTDATA'));

my $url  = $postdata->{'repository'}->{'url'};
my $ref  = $postdata->{'ref'};
my $name = $postdata->{'head_commit'}->{'author'}->{'name'};

my $branch = $ref;  $branch =~ s'^.*\/'';
my $repo   = $url;  $repo   =~ s'^.*\/'';


print header(),
  start_html("Vishap Oberon github post push web hook."),
  p("Repository $repo, branch $branch, name $name."),
  end_html();


open(LOG, ">>/tmp/postpush.log") or die "Could not create postpush.log";
flock(LOG, 2)                    or die "Could not lock postpush.log";
printf LOG "Repository $repo, branch $branch, name $name.\n";
close(LOG);
