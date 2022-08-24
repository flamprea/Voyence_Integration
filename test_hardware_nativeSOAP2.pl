#!perl –w

# Script Name: Voyence Hardware Information
# Version: 2.0
# Date: July 31, 2007
# Author: Frank Lamprea
# BladeLogic, Inc.

# Description:
# Retrieve Device information via a SOAP call to the Voyence Webservices API (getDeviceHardware)
# Once the data is returned the structure is converted to XML then XPATH to INI format

use SOAP::Lite;
use Data::Dumper;
use Data::DumpXML qw(dump_xml);
use XML::XPath;

# Check Command line arguments
my $numArgs = $#ARGV + 1;
if ($numArgs ne 1) {
	print "Usage: <script.pl> hostname ";
	exit 1;
}

# Parse the command line - First and only argument is the hostname.
my $hostName= "$ARGV[0]";

# Initialize
# HARDCODED -- Must fix
my $soap_host = 'voyance';
my $soap_user = 'sysadmin';
my $soap_pw = 'sysadmin';
my $network = 'BladeLogic Network';

my $soap_proxy = 'http://' . $soap_user . ':' . $soap_pw . '@' . $soap_host . ':8881/ws/api/36/services/ApiService';
my $soap_uri = 'http://api.common.configmgr.powerup.com';

# Build the Connection
my $soap_client = new SOAP::Lite	
        uri => $soap_uri,
	proxy => $soap_proxy,
	autotype => 0;

        # Get the Device Hardware Information
        # create a network RII object for net
        $net_rii = {
                resourceName => "$network",
                resourceType => "NETWORK",
                resourceKey => undef};
        bless $net_rii, 'ResourceIdentityInfo';
        
        # create a device RII object for new device
        $dev_rii = {
                resourceName => "$hostName",
                resourceType => "DEVICE",
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
$soap_response = $soap_client->getDeviceHardware($net_param,$dev_param) or die "No Response from SOAP: $!\n";
    
# The result is a complex Data Structure that is difficult to
# manipulate. Converting to XML allows for easy XPath transforms
# to rearrange the data.
  unless ($soap_response->fault) {
    my $dev_hash = $soap_response->result;
           
    # Dump the Data Structure into XML
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

	# ***THIS IS WHERE WE WRITE OUT THE INI FILE***
	# Append a Unique value to each Heading
	if ( ($secBody =~ m/poolName=(.+)/i) || ($secBody =~ m/deviceName=(.+)/i) ) {
		(my $name, my $value) = split /=/, $&, 2;
		$secHeading = $secHeading . " - $value]\n";
	}
	else {
		$secHeading = $secHeading . "]\n";
	}
	
	# Append the output to the "master" copy
	$iniOutput = $iniOutput . $secHeading . $secBody;
		
}

print $iniOutput;
exit 0;