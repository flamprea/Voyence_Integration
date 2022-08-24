#!/usr/bin/perl -w

use strict;
use XML::Simple;

my $file = 'files/camelids.xml';
my $xs1 = XML::Simple->new();

my $doc = $xs1->XMLin($file);

foreach my $key (keys (%{$doc->{species}})){
   print $doc->{species}->{$key}->{'common-name'} . ' (' . $key . ') ';
   print $doc->{species}->{$key}->{conservation}->{status} . "\n";
}
