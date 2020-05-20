#!/usr/bin/perl -w

use strict;
use English;
use Getopt::Std;
use XML::LibXML;
use Socket;

# Enable file output autoflush
$| = 1;

BEGIN {
    require "/etc/emulab/paths.pm";
    import emulabpaths;
    require "/local/repository/lib/paths.pm";
    import oaipaths;
}

# PhantomNet library
use epclib;

my $CAT = "/bin/cat";


#
# Enforce running script as root.
#
($UID == 0)
    or die "You must run this script as root (e.g., via sudo)!\n";

#
# Ensure multitail is installed
#

system("apt-get install multitail");

#
# Setup ssh commands
#
#
# Display help and exit.
#
sub help() {
    logprint("Usage: start_oai [-r sim]\n");

    exit 1;
}

my %opts = ();
if (!getopts("r:",\%opts)) {
    help();
}


my $role        = $opts{'r'};
my $simPresent = "0";
if ($role eq "sim") {
  $simPresent = "1";
}
my $enbStart;
if ($simPresent == "1")
{
  $enbStart = "/usr/bin/ssh -p 22 -o ServerAliveInterval=300 -o ServerAliveCountMax=3 -o BatchMode=yes -o StrictHostKeyChecking=no sim-enb ";
}
else
{
  $enbStart = "/usr/bin/ssh -p 22 -o ServerAliveInterval=300 -o ServerAliveCountMax=3 -o BatchMode=yes -o StrictHostKeyChecking=no enb1 ";
}
my $epcStart = "/usr/bin/ssh -p 22 -o ServerAliveInterval=300 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=no epc ";

my $nickname = `$CAT $BOOTDIR/nickname`;
chomp($nickname);

if ($nickname =~ /^epc/)
{
    $epcStart = "";
}
if ($nickname =~ /^enb/)
{
    $enbStart = "";
}

#
# Begin Services
#
print "Killing off any old services...\n";
system($epcStart . "/local/repository/bin/hss.kill.sh");
system($epcStart . "/local/repository/bin/mme.kill.sh");
system($epcStart . "/local/repository/bin/spgw.kill.sh");
if ($simPresent == "1")
{
system($enbStart . "/local/repository/bin/sim_enb.kill.sh");
}
else
{
system($enbStart . "/local/repository/bin/enb.kill.sh");
}

print "Starting HSS...\n";
system($epcStart . "/local/repository/bin/hss.start.sh");
sleep(5);

print "Starting MME...\n";
system($epcStart . "/local/repository/bin/mme.start.sh");
sleep(5);

print "Starting SPGW...\n";
system($epcStart . "/local/repository/bin/spgw.start.sh");
sleep(30);

if ($simPresent == "1")
{
  print "Starting SIM ENB...\n";
  system($enbStart . "/local/repository/bin/sim_enb.start.sh");
}
else
{
  print "Starting ENB...\n";
  my $devices = `${enbStart}lsusb`;
  if ($devices =~ /2500:0020/)
  {
    system($enbStart . "/local/repository/bin/enb.start.sh");
  }
  else
  {
    print "ERROR: Could not detect USRP B210 radio on the enb1 node. This is usually a transient error. Reboot the enb1 node and try again.\n";
    exit(1);
  }
}
#
# Display Output of services
#
system("multitail ".
       #       "-l \"$epcStart tail -f /var/log/oai/hss.log\" ".
       "-l \"$epcStart tail -f /var/log/oai/mme.log\" ".
       #       "-l \"$epcStart tail -f /var/log/oai/spgw.log\" ".
       "-l \"$enbStart tail -f /var/log/oai/enb.log\"");
