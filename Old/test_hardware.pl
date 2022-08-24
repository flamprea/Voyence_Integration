#!perl –w

use SOAP::Lite;
use Data::Dumper;
use Voyence::DumpXML qw(dump_xml_bl); # BladeLogic modified version of Data:DumpXML

#Check Command line arguments
my $numArgs = $#ARGV + 1;
if ($numArgs ne 1) {
	print "Usage: <script.pl> hostname ";
	exit 1;
}

#Parse the command line - First and only argument is the hostname.
my $hostName= "$ARGV[0]";

# Initialize
my $soap_host = 'localhost';
my $soap_user = 'sysadmin';
my $soap_pw = 'sysadmin';

my $soap_proxy = 'http://' . $soap_user . ':' . $soap_pw . '@' . $soap_host . ':8881/ws/api/36/services/ApiService';
my $soap_uri = 'http://api.common.configmgr.powerup.com';

#print "$soap_proxy \n";
#print "$soap_uri \n";

# Build the Connection
my $soap_client = new SOAP::Lite	
        uri => $soap_uri,
	proxy => $soap_proxy,
	autotype => 0;

# Get the Device Hardware Information
# create a network RII object for net
$net_rii = {
        resourceName => "BladeLogic Network",
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

# Make the Call
$soap_response = $soap_client->getDeviceHardware($net_param,$dev_param);
    
# Evaluate and Print
  unless ($soap_response->fault) {
    my $dev_hash = $soap_response->result;
           
    #$Data::Dumper::Terse = 1;          # don't output names where feasible
    #$Data::Dumper::Indent = 1;         # mild pretty print
    #print Dumper($dev_hash);
    #print "\n\n\n";
    
    # Dump the Data Structure into XML
    # The rest of the work is done inside the DumpXMLBL module
    $xml = dump_xml_bl($dev_hash);
    print "$xml";
	
  } else {
    print join ', ', 
      $soap_response->faultcode, 
      $soap_response->faultstring;
  }
  
exit 0;
