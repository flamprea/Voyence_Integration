#!perl –w

# Script Name: Voyence Hardware Information
# Version: 2.0
# Date: July 31, 2007
# Author: Frank Lamprea
# BladeLogic, Inc.

# Description:
# Retrieve Device information via a SOAP call to the Voyence Webservices API (getOperationalDeviceInfo)
# Once the data is returned the structure is converted to XML then XPATH to INI format

use SOAP::Lite;
use Data::Dumper;
use Data::DumpXML qw(dump_xml);
use XML::XPath;

#Check Command line arguments
my $numArgs = $#ARGV + 1;
if ($numArgs ne 1) {
	print "Usage: <script.pl> hostname \n";
        print "script.pl server1\n";
	exit 1;
}

# Parse the command line - First and only argument is the hostname.
my $hostName= "$ARGV[0]";

# Initialize
# HARDCODED -- Must fix
my $soap_host = 'voyance';
my $soap_user = '';
my $soap_pw = '';
my $network = 'BladeLogic Network';

#Parse the command line - First and only argument is the hostname.
my $hostName= "$ARGV[0]";
my $extendedOutput = "false";

my $soap_proxy = 'http://' . $soap_user . ':' . $soap_pw . '@' . $soap_host . ':8881/ws/api/36/services/ApiService';
my $soap_uri = 'http://api.common.configmgr.powerup.com';

	# Build the Connection
	my $soap_client = new SOAP::Lite	
		uri => $soap_uri,
		proxy => $soap_proxy,
		autotype => 0;
	
	# View All Information about a Dvice
	# create a network RII object for net
	$net_rii = {
		resourceName => "$network",
		resourceType => 'NETWORK',
		resourceKey => undef};
	bless $net_rii, 'ResourceIdentityInfo';
	
	# create a device RII object for new device
	$dev_rii = {
		resourceName => "$hostName",
		resourceType => 'DEVICE',
		resourceKey => undef};
	bless $dev_rii, 'ResourceIdentityInfo';
	
		# build param 0
		$net_param = new SOAP::Data
		name => 'in0',
		attr => {'xsi:type' => ref($net_rii)},
		value => $net_rii;
		
		# build param 1
		$dev_param = new SOAP::Data
		name => 'in1',
		attr => {'xsi:type' => ref($dev_rii)},
		value => $dev_rii;

# Make the Call and capture the Data Structure
$soap_response = $soap_client->getOperationalDeviceInfo($net_param,$dev_param,"$extendedOutput");
    
# The result is a complex Data Structure that is difficult to
# manipulate. Converting to XML allows for easy XPath transforms
# to rearrange the data.
  unless ($soap_response->fault) {
    my $dev_hash = $soap_response->result;
    
    # Dump the Data Structure into XML
    # The rest of the work is done inside the DumpXMLBL module
    $xml = dump_xml($dev_hash);
    #print "$xml";
	
                
  } else {
    print join ', ', 
      $soap_response->faultcode, 
      $soap_response->faultstring;
      exit 1;
  }

# We'll store the entire INI in a variable, arrange it, and print out at the end.
my $iniOutput = '';
my $secHeading = '';
my $secBody = '';

# Transform the XML to an Extended Object "Friendly" format
# Create an XPath Object
my $xp = XML::XPath->new(xml => $xml);

# Determine the High Level Nodes which are returned as Hashes from Voyence SOAP
my $nodeset = $xp->find('//hash');

# Iterate through the Nodes to find key=value pairs
# Generally these are nested in Arrays
foreach my $node ($nodeset->get_nodelist){
	
	# Reset the 'Body'... we're moving on to the next section
	$secBody = '';
	
	# The Hash is a "Section Heading"... print it out
	$secHeading = "[" . $node->find('@class');
            
	# Find all the Keys in this Hash
	my $keyset = $node->find('key | str');
	my $elemType = '';
                        
	# Loop through the Keys and find the value for each one
	foreach my $key ($keyset->get_nodelist) {
		    
	    # If the Last Key had no Value go to the next
	    # line, else you would have key=key
	    if ($key->getLocalName eq $elemType) {
		    $secBody = $secBody . "\n";                
	    }
		
	    # Setup "key="
	    if ($key->getLocalName eq "key") {
		    $secBody = $secBody . $key->string_value . "=";
		    $elemType = 'key';
	    }
	    # Seup "value\n"
	    elsif ($key->getLocalName eq "str") {
		    $secBody = $secBody . $key->string_value . "\n";
		    $elemType = 'str';
	    }
	    else {
		    print "Error: Unknown Element\n";
		    exit 1;
	    }
	    
	}

	$secHeading = $secHeading . "]\n";
	
	# Append the output to the "master" copy
	# Strip out the Resource and Revision Identity Info
	# Also, since this is only one tree with Name/Value pair
	# we will not Print the Heading out.
	unless (($secHeading =~ m/ResourceIdentityInfo/) || ($secHeading =~ m/RevisionNumberInfo/)) {
		
		# Normally the heading is included, but we'll leave it out to
		# flatten out the file
		#$iniOutput = $iniOutput . $secHeading . $secBody;
		
		$iniOutput = $iniOutput . $secBody;
		
	}
		
}

print $iniOutput;

exit 0;
