#!/usr/bin/perl -w

use strict;
use XML::XPath;

my $file = "C:\\Integration\\pl_xml_samples\\files\\camelids.xml";
my $xp = XML::XPath->new(filename => $file);

foreach my $species ($xp->find('//')->get_nodelist){
    print $species->find('common-name')->string_value;
    print ' (' . $species->find('@name') . ') ';
    print $species->find('conservation/@status');
    print "\n";
}
