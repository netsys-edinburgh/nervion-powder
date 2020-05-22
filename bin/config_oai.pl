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

# Function prototypes
sub logdie($);
sub logwarn($);
sub logprint($);
sub gatherInfo();
sub DBImport($$$$);
sub connectDB($$$);
sub lookupIP(@);
sub blockCnetVMARP();
sub setHostName();
sub loadManifest();
sub get_max_id($$;$);
sub replaceMacro($$);
sub provisionUEs($);
sub configureOAI();
sub runOAI();

# Global vars to store config info used throughout the script.
my $ctrlif;
my %ifaces = ();
my $hname;
my $realm;
my $enb_id;
my %interfaces = ();
my %ipaddrs = ();
my %ipmasks = ();
my %fqdns = ();

# Constants
my $OAI_DB_USER = "root";
my $OAI_DB_PASS = "linux";
my $OAI_DB_NAME  = "oai_db";
my $OAI_INIT_SQL = "$OAI_ETCDIR/oai_init_db.sql";
my $OAI_DB_INIT_FF = "$BOOTDIR/OAI_DB_INIT_DONE";
my $OAI_CONFIG_FF = "$BOOTDIR/OAI_CONFIG_DONE";
my $OAI_PROVISION_FF = "$BOOTDIR/OAI_UE_PROVISIONING_DONE";
my $EMULAB_VMRANGE = "172.16.0.0/12";

my $MSISDN_PREFIX = "3363806";
my $PNET_KI = "0x00112233445566778899AABBCCDDEEFF";
my $PNET_OPKEY = "01020304050607080910111213141516";
my $RAND_VAL = "0x00000000000000000000000000000000";
my $PNET_REALM = "phantomnet.org";
my $PNET_MCC = "208";
my $PNET_MNC = "93";
my $DEF_TAC = "1";

#Binh: OAISIM's eNodeB and UE subscriber information
my $OAISIM_IMSI = "000001234";
my $OAISIM_MSISDN = "33611111111";
my $OAISIM_IMEI = "35611302209414";
my $OAISIM_KEY = "0x8BAF473F2F8FD09487CCCBD7097C6862";
my $OAISIM_SQN = "00000281454575617153";
my $OAISIM_RAND = "0x0902263F8411A90F160A540F8950173A";
my $OAISIM_OPKEY = "0x8E27B6AF0E692E750F32667A3B14605D";

my $MYSQL_CLI = "/usr/bin/mysql";
my $TOUCH = "/usr/bin/touch";
my $GENIGET = "/usr/bin/geni-get";
my $CAT = "/bin/cat";
my $HOSTNAME = "/bin/hostname";
my $ARPTABLES = "/sbin/arptables";

my %OAI_ROLES = ( 
    # Combined EPC role on one node (HSS, MME, SPGW)
    'EPC' => 1,
    # SDR eNodeB role
    'ENB' => 1,
    # Emulated eNodeB + UE
    'SIM_ENB' => 1,
);

my %OAI_CONFFILES = (
    'EPC' => ['hss.conf', 'mme.conf', 'spgw.conf', 'hss_fd.conf', 'mme_fd.conf'],
    'ENB' => ['enb.conf'],
    'SIM_ENB' => ['enb.conf'],
);

my @REPLACE_PATS = (
    { PATTERN => qr/(%(\w+?)_IPMASK%)/, FUNC => \&replaceMacro, MAP => \%ipmasks },
    { PATTERN => qr/(%(\w+?)_IP%)/, FUNC => \&replaceMacro, MAP => \%ipaddrs },
    { PATTERN => qr/(%(\w+?)_INTF%)/, FUNC => \&replaceMacro, MAP => \%interfaces },
    { PATTERN => qr/(%(\w+?)_FQDN%)/, FUNC => \&replaceMacro, MAP => \%fqdns },
    { PATTERN => qr/(%REALM%)/, FUNC => \&replaceMacro, REPLSTR => \$realm },
    { PATTERN => qr/(%HSS_OPKEY%)/, FUNC => \&replaceMacro, REPLSTR => \$PNET_OPKEY },
    { PATTERN => qr/(%HOSTNAME%)/, FUNC => \&replaceMacro, REPLSTR => \$hname },
    { PATTERN => qr/(%MCC%)/, FUNC => \&replaceMacro, REPLSTR => \$PNET_MCC },
    { PATTERN => qr/(%MNC%)/, FUNC => \&replaceMacro, REPLSTR => \$PNET_MNC },
    { PATTERN => qr/(%TAC%)/, FUNC => \&replaceMacro, REPLSTR => \$DEF_TAC },
    { PATTERN => qr/(%ENB_ID%)/, FUNC => \&replaceMacro, REPLSTR => \$enb_id },
);

my %ROLEDEFS = (
    'EPC' => {
	'S11_MME_INTF' => 'lo',
	'S11_MME_IP' => '127.0.11.1',
	'S11_MME_IPMASK' => '127.0.11.1/8',
	'S11_SGW_INTF' => 'lo',
	'S11_SGW_IP' => '127.0.11.2',
	'S11_SGW_IPMASK' => '127.0.11.2/8',
	'S6A_HSS_INTF' => 'lo',
	'S6A_HSS_IP' => '127.0.0.1',
	'S6A_HSS_IPMASK' => '127.0.0.1/8',
    },

    'ENB' => {},
    'SIM_ENB' => {},
);

my @MME_HOSTLIST = ('mme-s1-lan', 'epc-s1-lan');

#
# Display help and exit.
#
sub help() {
    logprint("Usage: config_oai [-n] [-d] -r <role>\n");
    logprint("  -r : OAI role.  One of: ". join(", ", keys %OAI_ROLES) ."\n");
    logprint("  -d : Enable debugging messages.\n");

    exit 1;
}

#
# Enforce running script as root.
#
($UID == 0)
    or die "You must run this script as root (e.g., via sudo)!\n";

#
# Setup logfile
#
open LOGFILE, ">", "$OAI_LOGDIR/startup.log";
logprint("----------------------\n");
logprint("Setting up OAI servers\n");
logprint("----------------------\n");

#
# Parse command line arguments.
#
my %opts = ();
if (!getopts("dr:",\%opts)) {
    help();
}

my $role        = $opts{'r'}
    or do { warn "Must specify OAI role!\n"; help() };
my $debug       = $opts{'d'} ? 1 : 0;

if (!exists($OAI_ROLES{$role})) {
    warn "Invalid role specified: $role\n";
    exit 1;
}

#
# Top-level logic flow.
#
gatherInfo();
configureOAI();
TOPSW: for ($role) {
    /^EPC$/ && do {
	require DBI;
	DBImport($OAI_DB_USER, $OAI_DB_PASS, $OAI_DB_NAME, $OAI_INIT_SQL);
	my $dbh = connectDB($OAI_DB_USER, $OAI_DB_PASS, $OAI_DB_NAME);
	provisionUEs($dbh);
	blockCnetVMARP();
	last TOPSW;
    };

    /^ENB$/ && do {
	# Nothing to do here.
	last TOPSW;
    };

    /^SIM_ENB$/ && do {
	# Nothing to do here.
	last TOPSW;
    };


    # Default
    logdie("Unknown role: $role\n");
}
#runOAI();

#
# Helper to lookup a list of hosts, searching for an IP.
#
sub lookupIP(@) {
    my (@hlist) = @_;
    my $ipaddr = undef;

    foreach my $name (@hlist) {
	my $res = gethostbyname($name);
	if ($res) {
	    $ipaddr = inet_ntoa($res);
	    last;
	}
    }

    return $ipaddr;
}

#
# Print message to log file and stderr, then exit with an error code of 1
#
sub logdie($) {
    my ($message) = @_;
    print LOGFILE "ERROR: " . $message;
    print STDERR "ERROR: " . $message;
    exit(1);
}

#
# Print message to log file and stderr and flag it as a warning
#
sub logwarn($) {
    my ($message) = @_;
    print LOGFILE "WARNING: " . $message;
    print STDERR "WARNING: " . $message;
}

#
# Print a message to log file and stdout
#
sub logprint($) {
    my ($message) = @_;
    print LOGFILE $message;
    print $message;
}

#
# Gather information about the experiment/environment.  Leave the results
# in global variables.
#
sub gatherInfo() {
    $hname = setHostName();
    $ctrlif = get_emulab_controlif();
    %ifaces = get_ifmap(1);
    $realm = $PNET_REALM; # XXX: hardcoding is not awesome.

    SW1: for ($role) {
	# Combined core node (HSS, MME, and SPGW).
	/^EPC$/ && do {
	    $interfaces{'SGI_PGW'} = $ctrlif;
	    $interfaces{'S1_MME'} = $ifaces{'s1-lan'}->{'IFACE'};
	    $ipaddrs{'S1_MME'} = $ifaces{'s1-lan'}->{'IPADDR'};
	    $ipmasks{'S1_MME'} = $ipaddrs{S1_MME} . '/24'; # XXX: hardcoding.
	    $interfaces{'S1U_SGW'} = $ifaces{'s1-lan'}->{'IFACE'};
	    $ipaddrs{'S1U_SGW'} = $ifaces{'s1-lan'}->{'IPADDR'};
	    $ipmasks{'S1U_SGW'} = $ipaddrs{S1U_SGW} . '/24'; # XXX: hardcoding.
	    $interfaces{'S11_MME'} = $ROLEDEFS{'EPC'}->{'S11_MME_INTF'};
	    $ipaddrs{'S11_MME'} = $ROLEDEFS{'EPC'}->{'S11_MME_IP'};
	    $ipmasks{'S11_MME'} = $ROLEDEFS{'EPC'}->{'S11_MME_IPMASK'};
	    $interfaces{'S11_SGW'} = $ROLEDEFS{'EPC'}->{'S11_SGW_INTF'};
	    $ipaddrs{'S11_SGW'} = $ROLEDEFS{'EPC'}->{'S11_SGW_IP'};
	    $ipmasks{'S11_SGW'} = $ROLEDEFS{'EPC'}->{'S11_SGW_IPMASK'};
	    $interfaces{'S6A_HSS'} = $ROLEDEFS{'EPC'}->{'S6A_HSS_INTF'};
	    $ipaddrs{'S6A_HSS'} = $ROLEDEFS{'EPC'}->{'S6A_HSS_IP'};
	    $ipmasks{'S6A_HSS'} = $ROLEDEFS{'EPC'}->{'S6A_HSS_IPMASK'};
	    $fqdns{'MME'} = "$hname.$realm";
	    $fqdns{'HSS'} = "hss.$realm";
	    last SW1;
	};

	# SDR eNodeB node.
	/^ENB$/ && do {
	    $interfaces{'S1_ENB'} = $ifaces{'s1-lan'}->{'IFACE'};
	    $ipaddrs{'S1_ENB'} = $ifaces{'s1-lan'}->{'IPADDR'};
	    $ipmasks{'S1_ENB'} = $ipaddrs{S1_ENB} . '/24'; # XXX: hardcoding.
 	    $interfaces{'S1U_ENB'} = $ifaces{'s1-lan'}->{'IFACE'};
	    $ipaddrs{'S1U_ENB'} = $ifaces{'s1-lan'}->{'IPADDR'};
	    $ipmasks{'S1U_ENB'} = $ipaddrs{S1_ENB} . '/24'; # XXX: hardcoding.
	    $ipaddrs{'S1_MME'} = lookupIP(@MME_HOSTLIST);
	    $hname =~ /(\d+)$/;
	    $enb_id = "0x" . $1;
	    last SW1;
	};

	# EMULATED (OAISIM) eNodeB node, exactly the same configuration as SDR eNodeB.
	/^SIM_ENB$/ && do {
	    $interfaces{'S1_ENB'} = $ifaces{'s1-lan'}->{'IFACE'};
	    $ipaddrs{'S1_ENB'} = $ifaces{'s1-lan'}->{'IPADDR'};
	    $ipmasks{'S1_ENB'} = $ipaddrs{S1_ENB} . '/24'; # XXX: hardcoding.
 	    $interfaces{'S1U_ENB'} = $ifaces{'s1-lan'}->{'IFACE'};
	    $ipaddrs{'S1U_ENB'} = $ifaces{'s1-lan'}->{'IPADDR'};
	    $ipmasks{'S1U_ENB'} = $ipaddrs{S1_ENB} . '/24'; # XXX: hardcoding.
	    $ipaddrs{'S1_MME'} = lookupIP(@MME_HOSTLIST);
	    $hname =~ /(\d+)$/;
	    $enb_id = "0x00e";  #XXX: hardcoding.
	    last SW1;
	};

	# Default
	logdie("Unknown role: $role\n");
    }
}

#
# RUN SQL statements from a file.
#
sub DBImport($$$$) {
    my ($user, $pass, $dbname, $sqlpath) = @_;

    # Already done?
    return if (-e $OAI_DB_INIT_FF);

    logdie("SQL file does not exist: $sqlpath")
	unless (-f $sqlpath);

    my $res = system("$MYSQL_CLI --user=$user --password=$pass $dbname < $sqlpath");
    if ($res) {
	$res = $res >> 8;
	logdie("Error running mysql client: $res");
    }

    logprint("OAI DB initialized.\n");

    # Mark one-time action as complete.
    system("$TOUCH $OAI_DB_INIT_FF") == 0 or
	logdie("Could not touch DB init flag file!");
}

#
# Connect to the OAI DB.
#
sub connectDB($$$) {
    my ($user, $pass, $dbname) = @_;

    return DBI->connect("dbi:mysql:dbname=$dbname", $user, $pass,
			{ RaiseError => 1 });
}

#
# Stop control network ARP requests for the VM control network from
# getting through to OAI and/or the GTP tunnel it sets up.  Otherwise
# it may end up stealing the VM control network IP.
#
sub blockCnetVMARP() {
    # system("$ARPTABLES -F") == 0
    #	 or logdie("Could not flush arptables!\n");
    system("$ARPTABLES -I INPUT -i $ctrlif -d $EMULAB_VMRANGE -j DROP") == 0
	or logdie("Failed to install VM control network ARP block rule!\n");
}

#
# Set the hostname to non-cannonical form of testbed nickname. We
# need to do this for FreeRadius.
#
sub setHostName() {
    my $nick = `$CAT $BOOTDIR/nickname`;
    chomp $nick;
    my ($sname,) = split(/\./, $nick);
    system("$HOSTNAME $sname") == 0
	or logdie("Could not set hostname to: $sname\n");
    return $sname;
}

#
# Load the GENI manifest
#
sub loadManifest() {
    my $dom;

    my $manistr = `$GENIGET manifest`;
    chomp $manistr;
    logdie("Error fetching experiment manifest, or no manifest available!\n")
	if ($? || !$manistr);

    eval { $dom = XML::LibXML->load_xml(string => $manistr,
					load_ext_dtd => 0, 
					no_network => 1,
					line_numbers => 1) };

    logdie("Invalid XML in manifest: $@\n")
	if ($@);

    return $dom;
}

#
# Get the maximum ID from a table (with an ID column).  Return '0'
# if no rows were found.
#
sub get_max_id($$;$) {
    my ($dbh, $tname, $idfield) = @_;
    $idfield ||= "id";

    # Grab largest ID value from requested table.
    my $sth = $dbh->prepare("SELECT MAX($idfield) FROM $tname");
    $sth->execute();
    my ($id,) = $sth->fetchrow();
    $id ||= 0;
    $sth->finish();

    return $id;
}

#
# Add any real UEs found in the manifest to the provisioning DB.
#
sub provisionRealUEs($$$$) {
    my ($dbh, $mme_id, $pgw_id, $pdn_id) = @_;

    # Extract GENI manifest from the testbed database.
    my $mani = loadManifest();

    # Loop through nodes in manifest, looking for those with UE attributes.
    my $root = $mani->documentElement();
    my @nodes = $root->getChildrenByLocalName("node");
    foreach my $node (@nodes) {
	my $vname = $node->getAttribute("client_id");
	my $imsi  = $node->getAttribute("sim_imsi");
	my $seqno = $node->getAttribute("sim_sequence_number");
	next unless ($vname && $imsi && $seqno);
	
	logprint("Provisioning UE '$vname': $imsi, $seqno\n");
 
	# Pad the sequence number out to 20 digits with leading zeros. Why?
	# Good question for the OAI folks...
	$seqno = sprintf("%020d", $seqno);

	# Create fake MSISDN number. Use last four digits of IMSI.
	my $msisdn = $imsi;
	$msisdn =~ s/^\d{11}(\d{4})$/${MSISDN_PREFIX}$1/;

	# Not clear what all of these params mean or how they are used in
	# practice; most were just copied from the OAI wiki.
	$dbh->do(
	    "INSERT INTO users (".
	    "  `imsi`, `msisdn`, `imei`, `imei_sv`,".
	    "  `ms_ps_status`, `rau_tau_timer`, `ue_ambr_ul`, `ue_ambr_dl`,".
	    "  `access_restriction`, `mme_cap`, `mmeidentity_idmmeidentity`,".
	    "  `key`, `RFSP-Index`, `urrp_mme`, `sqn`, `rand`, `OPc`) ".
	    "VALUES (".
	    "  '$imsi', '$msisdn', NULL, NULL,".
	    "  'PURGED', '120', '50000000', '100000000',".
	    "  '47', '0000000000', '$mme_id',".
	    "  $PNET_KI, '1', '0', '$seqno', $RAND_VAL, '')");
	# Ditto above.  My guess is that all zero IP addresses indicate
	# dynamic allocation.  The pool is handled via a row in the `pgw`
	# table.
	$pdn_id++;
	$dbh->do(
	    "INSERT INTO pdn (".
	    "  `id`, `apn`, `pdn_type`, `pdn_ipv4`, `pdn_ipv6`,".
	    "  `aggregate_ambr_ul`, `aggregate_ambr_dl`, `pgw_id`, ".
	    "  `users_imsi`, `qci`, `priority_level`,`pre_emp_cap`,".
	    "  `pre_emp_vul`, `LIPA-Permissions`) ".
	    "VALUES (".
	    "  '$pdn_id', 'internet','IPV4', '0.0.0.0', '0:0:0:0:0:0:0:0',".
	    "  '50000000', '100000000', '$pgw_id',".
	    "  '$imsi', '9', '15', 'DISABLED',".
	    "  'ENABLED', 'LIPA-ONLY')");
    }

    return $pdn_id;
}

#
# Provision simulated UEs.  For now this is run regardless of whether or
# not users have actually allocated them in the experiment.
#
sub provisionSimUEs($$$$) {
    my ($dbh, $mme_id, $pgw_id, $pdn_id) = @_;

    #
    #Binh: provisioning OAISIM's UE.
    #Always remove and reinstall the information because currently the 
    #OAISIM UE won't authenticate if the database is old.
    #
    my $oai_imsi = "$PNET_MCC$PNET_MNC$OAISIM_IMSI";

    $pdn_id++;
    $dbh->do(
	    "INSERT INTO users (".
	    "  `imsi`, `msisdn`, `imei`, `imei_sv`,".
	    "  `ms_ps_status`, `rau_tau_timer`, `ue_ambr_ul`, `ue_ambr_dl`,".
	    "  `access_restriction`, `mme_cap`, `mmeidentity_idmmeidentity`,".
	    "  `key`, `RFSP-Index`, `urrp_mme`, `sqn`, `rand`, `OPc`) ".
	    "VALUES (".
	    "  '$oai_imsi', '$OAISIM_MSISDN', NULL, NULL,".
	    "  'PURGED', '120', '50000000', '100000000',".
	    "  '47', '0000000000', '$mme_id',".
	    "  $OAISIM_KEY, '1', '0', '$OAISIM_SQN', $OAISIM_RAND, $OAISIM_OPKEY)");
    $dbh->do(
	    "INSERT INTO pdn (".
	    "  `id`, `apn`, `pdn_type`, `pdn_ipv4`, `pdn_ipv6`,".
	    "  `aggregate_ambr_ul`, `aggregate_ambr_dl`, `pgw_id`, ".
	    "  `users_imsi`, `qci`, `priority_level`,`pre_emp_cap`,".
	    "  `pre_emp_vul`, `LIPA-Permissions`) ".
	    "VALUES (".
	    "  '$pdn_id', 'internet','IPV4', '0.0.0.0', '0:0:0:0:0:0:0:0',".
	    "  '50000000', '100000000', '$pgw_id',".
	    "  '$oai_imsi', '9', '15', 'DISABLED',".
	    "  'ENABLED', 'LIPA-ONLY')");

    logprint("Provisioned OAISIM UE : $oai_imsi\n");

    return $pdn_id;
}


#
# Put the UEs allocated to this experiment into the OAI database.
#
sub provisionUEs($) {
    my ($dbh,) = @_;

    # Already done?
    return if (-e $OAI_PROVISION_FF);

    # Add top-level DB records for EPC services.
    my $mme_id = get_max_id($dbh, "mmeidentity", "idmmeidentity") + 1;
    $dbh->do("INSERT INTO mmeidentity VALUES ($mme_id, '$fqdns{MME}', '$realm', 0)");
    my $pgw_id = get_max_id($dbh, "pgw") + 1;
    my $ipv6 = "0:0:0:0:0:0:0:$pgw_id"; # XXX: completely bogus.
    $dbh->do("INSERT INTO pgw VALUES ($pgw_id, '$ipaddrs{S1U_SGW}', '$ipv6')");

    # Grab largest ID number from `pdn` table.
    my $pdn_id = get_max_id($dbh, "pdn");

    # Add real UE devices.
    $pdn_id = provisionRealUEs($dbh, $mme_id, $pgw_id, $pdn_id);

    # Add simulated UEs.
    $pdn_id = provisionSimUEs($dbh, $mme_id, $pgw_id, $pdn_id);

    # Mark that we're done.
    system("$TOUCH $OAI_PROVISION_FF") == 0 or
	logdie("Could not create OAI provisioning flag file!");

}

#
# Generic macro replacement helper function.
#
sub replaceMacro($$) {
    my ($cline, $pat) = @_;
    $cline =~ $pat->{PATTERN};
    my $macro = $1;
    my $epc_func = $2;
    my $repl = "";
    if (exists($pat->{MAP})) {
	$repl = $pat->{MAP}->{$epc_func};
    }
    elsif (exists($pat->{REPLSTR})) {
	$repl = ${$pat->{REPLSTR}};
    }
    $cline =~ s/$macro/$repl/g;

    return $cline;
}

#
# Do all of the things for OAI
#
sub configureOAI() {
    # Already done?
    return if (-e $OAI_CONFIG_FF);

    # Macro-replace and install OAI config files.
    foreach my $cfile (@{$OAI_CONFFILES{$role}}) {
	my $destdir = $OAI_SYSETC;
	if ($cfile =~ /_fd\.conf$/) {
	    $destdir .= "/freeDiameter";
	}
	open(SFILE, "<$OAI_ETCDIR/$cfile")
	    or logdie("Could not open source OAI config file: $OAI_ETCDIR/$cfile\n");
	open(TFILE, ">$destdir/$cfile")
	    or logdie("Could not open target OAI config file: $OAI_SYSETC/$cfile\n");
	while (my $cline = <SFILE>) {
	    chomp $cline;
	    foreach my $pat (@REPLACE_PATS) {
		if ($cline =~ $pat->{PATTERN}) {
		    $cline = $pat->{FUNC}($cline, $pat);
		}
	    }
	    if (defined($cline)) {
		print TFILE $cline . "\n";
	    }
	}
	close(SFILE);
	close(TFILE);
	logprint("Updated/installed OAI config file: $cfile\n");
    }

    # Role-specific tasks.
    ROLESW: for ($role) {
	/^EPC$/ && do {
	    # Generate freeDiameter certificates.
	    system("$OAI_EPCDIR/scripts/check_mme_s6a_certificate $OAI_SYSETC/freeDiameter $fqdns{MME} > $OAI_LOGDIR/check_mme_cert.log 2>&1") == 0
		or logdie("Failed to generate freeDiameter certs for MME!\n");
	    system("$OAI_EPCDIR/scripts/check_hss_s6a_certificate $OAI_SYSETC/freeDiameter $fqdns{HSS} > $OAI_LOGDIR/check_hss_cert.log 2>&1") == 0
		or logdie("Failed to generate freeDiameter certs for HSS!\n");
	    last ROLESW;
	};
	
	/^ENB$/ && do {
	    # Nothing else to do presently!
	    last ROLESW;
	};
	/^SIM_ENB$/ && do {
	    # Nothing else to do presently!
	    last ROLESW;
	};

    }
    
    # Mark that we're done.
    system("$TOUCH $OAI_CONFIG_FF") == 0 or
	logdie("Could not create OAI configuration flag file!");
}

sub startOAIService($) {
    my ($svcname) = @_;

    logprint("Starting OAI service: $svcname\n");

    system("$OAI_BINDIR/${svcname}.start.sh") == 0
	or warn "Could not start service: $svcname\n";

    return $?;
}

sub startSyncServer() {
    logprint("Starting Sync Server\n");
    system("killall emulab-syncd");
    system("/usr/local/etc/emulab/emulab-syncd") == 0
	or warn "Could not start sync server\n";
    return $?;
}

sub waitForSyncServer($) {
    my ($shouldIncrement) = @_;
    my $increment = "";
    if ($shouldIncrement) {
	$increment = " -i 1";
    }
    logprint("Waiting for Sync Server\n");
    system("/usr/local/etc/emulab/emulab-sync -n oai -s enb1-s1-lan $increment") == 0
	or warn "Waiting for sync server failed\n";
    return $?;
}

#
# Start up OAI components for our role.
#
sub runOAI() {
    ROLESW: for ($role) {
	/^EPC$/ && do {
	    startOAIService("hss");
	    sleep(5);
	    startOAIService("mme");
	    sleep(5);
	    startOAIService("spgw");
	    sleep(30);
	    waitForSyncServer(1);
	    last ROLESW;
	};

	/^ENB$/ && do {
	    startSyncServer();
	    waitForSyncServer(0);
	    startOAIService("enb");
	    last ROLESW;
	};

	/^SIM_ENB$/ && do {
	    waitForSyncServer(0);
	    startOAIService("sim_enb");
	    last ROLESW;
	};

	# Default
	logdie("Unknown role: $role\n");
    }

    logprint("OAI services started.\n");
}
