# Library of useful functions for OpenEPC

package epclib;
use Exporter;
@ISA    = "Exporter";
@EXPORT = qw ( 
    MGMT_SUBNET NETA_SUBNET NETB_SUBNET NETC_SUBNET NETD_SUBNET
    OPENEPC_ROLES OPENEPC_CLIENTS 
    get_emulab_controlif get_ifmap update_openepc_vars 
    elabnet_to_epcnet epcnet_to_elabnet mk_screenrc
    populate_hss_subscribers
);

use strict;

# Drag in Emulab and PhantomNet paths.
BEGIN {
    require "/etc/emulab/paths.pm";
    import emulabpaths;
    require "/etc/phantomnet/paths.pm";
    import phantomnetpaths;
}

use libsetup;

my %ELAB2OEPC_NETS = (
    "mgmt" => "mgmt",
    "net-a" => "net_a",
    "net-b" => "net_b",
    "net-c" => "net_c",
    "net-d" => "net_d",
    "an-gprs" => "an_gprs",
    "an-umts" => "an_umts",
    "an-lte" => "an_lte",
    "an-wifi" => "an_wifi",
    "an-wimax" => "an_wimax",
    "enodeb-an-lte" => "net_c",
    "nodeb-an-umts" => "net_c",
    "epdg-an-wifi" => "net_c",
    "angw-an-wimax" => "net_c",
);

my %OEPC2ELAB_NETS = (
    "mgmt" => "mgmt",
    "net_a" => "net-a",
    "net_b" => "net-b",
    "net_c" => "net-c",
    "net_d" => "net-d",
    "an_gprs" => "an-gprs",
    "an_umts" => "an-umts",
    "an_lte" => "an-lte",
    "an_wifi" => "an-wifi",
    "an_wimax" => "an-wimax",
    "enodeb-net_c" => "an-lte",
    "nodeb-net_c" => "an-umts",
    "epdg-net_c" => "an-wifi",
    "angw-net_c" => "an-wimax",
);

sub OPENEPC_ROLES {
    return (
	"epc-enablers" => 1,
	"pgw" => 1,
	"enodeb" => 1,
	"sgw-mme-sgsn" => 1,
	"nodeb" => 1,
	"epdg" => 1,
	"angw" => 1,
	"epc-client" => 1,
	"any" => 1
	);
}

sub OPENEPC_CLIENTS {
    return (
	"alice" => 1,
	"bob" => 1
	);
}

sub MGMT_SUBNET() { return "192.168.254"; }
sub NETA_SUBNET() { return "192.168.1"; }
sub NETB_SUBNET() { return "192.168.2"; }
sub NETC_SUBNET() { return "192.168.3"; }
sub NETD_SUBNET() { return "192.168.4"; }

my $TOUCH = "/usr/bin/touch";
my $FINDIF = "$BINDIR/findif";
my $OPENEPC_VARFILE = "$OEPC_ETCDIR/configure_system_vars.sh";

my $debug = 0;
my %ifmap = ();

my $PASSDB = "$VARDIR/db/passdb";
my $SCREENRC_FILE = "/root/.screenrc";

my $IMSI_LENGTH = 15; # e.g., 001010123456789
my $SIM_SQN_LENGTH = 12;
my $MSISDN_PREFIX = "12345678";
my $ADD_SUBSCRIBER = "$OEPC_PNDIR/load_client_database.sh";
my $POPULATE_HSS_FFILE = "$BOOTDIR/OEPC_SUBSCRIBERS_ADDED";

#
# Utility func for the following two lib functions
#
sub prefix_search ($$) {
    my ($str, $href) = @_;
    foreach my $key (keys %$href) {
	return $href->{$key} if $str =~ /^$key/;
    }
    return undef;
}

#
# Return the OpenEPC network name given the Emulab network name.
# Match against the first part (prefix) of the network name.
#
sub elabnet_to_epcnet($$) {
    my ($role, $elnet) = @_;

    my $combined = "${role}-${elnet}";
    return
	prefix_search($combined, \%ELAB2OEPC_NETS) || 
	prefix_search($elnet, \%ELAB2OEPC_NETS);
}

#
# Return the Emulab network name given the OpenEPC network name.
# Match against the first part (prefix) of the network name.
#
sub epcnet_to_elabnet($$) {
    my ($role, $epcnet) = @_;

    my $combined = "${role}-${epcnet}";
    return
	prefix_search($combined, \%OEPC2ELAB_NETS) || 
	prefix_search($epcnet, \%OEPC2ELAB_NETS);
}

#
# Grab control net interface name.
#
sub get_emulab_controlif() {
    my $ctrlif = undef;

    if (-e "$BOOTDIR/controlif") {
	if (!open(CIF, "< $BOOTDIR/controlif")) {
	    warn "Can't open $BOOTDIR/controlif";
	    return undef;
	}
	$ctrlif = <CIF>;
	close(CIF);
	chomp $ctrlif;
    }
    return $ctrlif;
}

#
# Create a map from Emulab lan name to local interface for all experimental
# lans that this node is a member of.
#
sub get_ifmap(;$) {
    my ($fullinfo,) = @_;
    $fullinfo ||= 0;

    # Have we generated the interface mappings already?
    if (scalar(keys %ifmap)) {
	return %ifmap;
    }

    my @ifconfigs = ();
    if (getifconfig(\@ifconfigs) != 0) {
	warn "Could not fetch Emulab interfaces configuration!";
	return undef;
    }

    foreach my $ifconfig (@ifconfigs) {
	my $ip  = $ifconfig->{IPADDR};
	my $mac = $ifconfig->{MAC};
	my $lan = $ifconfig->{LAN};

	next unless $mac && $lan;

	print "Debug: checking interface: $mac/$ip/$lan\n"
	    if $debug;

	my $iface = `$FINDIF -m $mac`;
	chomp $iface;
	if ($? != 0 || !$iface) {
	    warn "Emulab's findif tool failed for ip address: $ip\n";
	    next;
	}
	$ifconfig->{IFACE} = $iface;

	if ($fullinfo) {
	    $ifmap{$lan} = $ifconfig;
	}
	else {
	    $ifmap{$lan} = $iface;
	}
    }

    return %ifmap;
}

#
# Fetch the set of Emulab users and conjure a screen RC file for root with
# appropriate ACLs.
#
sub mk_screenrc() {
    my $firstuser = "";
    my %PWDDB = ();
    
    if (-e $SCREENRC_FILE) {
	if (!unlink $SCREENRC_FILE) {
	    warn "Could not unlink GNU SCREEN RC file: $!\n";
	    return 0;
	}
    }

    open(SCREENRC, ">$SCREENRC_FILE") or 
	die "Could not open $SCREENRC_FILE: $!";

    print SCREENRC "multiuser on\n";

    # Open up the Emulab user database hash and read out all the users,
    # adding them to root's SCREEN RC file (ACLs).
    dbmopen(%PWDDB, $PASSDB, 0) or
	die("Cannot open $PASSDB: $!");
    while (my ($user, undef) = each %PWDDB) {
	print "Debug: Adding user $user to screen RC ACLs.\n"
	    if $debug;
	# The first user will get an explicit permissions entry.
	if (!$firstuser) {
	    $firstuser = $user;
	    print SCREENRC "aclchg $user +rwx '#detach,#copy,#stuff,#meta'\n";
	}
	# Subsequent users will simply inherit the permission of the
	# initial user.
	else {
	    print SCREENRC "aclgrp $user $firstuser\n";
	}
    }

    dbmclose(%PWDDB);
    close SCREENRC;
    return 1;
}

#
# Update variables in the OpenEPC build configuration file
#
sub update_openepc_vars($$) {
    my ($var, $val) = @_;

    # Create empty config file if it doesn't exist.
    if (!-e $OPENEPC_VARFILE) {
	if (system("touch $OPENEPC_VARFILE") != 0) {
	    warn "Could not create $OPENEPC_VARFILE";
	    return 0;
	}
    }

    # Process the config file, looking for the variable to update.
    if (!-r $OPENEPC_VARFILE or !open(OVARS, "< $OPENEPC_VARFILE")) {
	warn "Could not open $OPENEPC_VARFILE for input."; 
	return 0;
    }
    if (!open(NVARS, "> ${OPENEPC_VARFILE}.new")) {
	warn "Can't open ${OPENEPC_VARFILE}.new for writing!";
	close(OVARS);
	return 0;
    }
    my $replaced = 0;
    while (my $ln = <OVARS>) {
	chomp $ln;
	if ($ln =~ /(.*)="(.*)"/) {
	    my ($cvar, $cval) = ($1, $2);
	    if ($cvar eq $var) {
		$ln = "${var}=\"${val}\"";
		$replaced = 1;
	    }
	}
	print NVARS "$ln\n"; 
    }
    close(OVARS);
    if (!$replaced) {
	print NVARS "\n${var}=\"${val}\"\n";
    }
    close(NVARS);

    # Move modified config file into place.
    if (!rename("${OPENEPC_VARFILE}.new", $OPENEPC_VARFILE)) {
	warn "Could not move updated configuration file into place!";
	return 0;
    }

    return 1;
}

sub populate_hss_subscribers() {
    my %subscribers;

    return 1
	if (-e $POPULATE_HSS_FFILE);

    if (getpnetnodeattrs(\%subscribers)) {
	warn "Could not lookup PhantomNet node attribute info!\n";
	return 0;
    }

    system("$TOUCH $POPULATE_HSS_FFILE");

    while (my ($dev, $kvhash) = each %subscribers) {
	my $imsi = $kvhash->{'sim_imsi'};
	my $sqn  = $kvhash->{'sim_sequence_number'};
	if (defined($imsi) && defined($sqn)) {
	    if (length($imsi) != $IMSI_LENGTH || $imsi !~ /^\d+(\d{4})$/) {
		warn "SIM IMSI attribute for $dev does not look like an IMSI: $imsi\n";
	        next;
	    }
	    my $imsi_id = $1;

	    if ($sqn !~ /^\d+$/ || length($sqn) > $SIM_SQN_LENGTH) {
		warn "SIM Sequence number for $dev does not look right: $sqn\n";
		next;
	    }
	    $sqn = sprintf("%0${SIM_SQN_LENGTH}s", $sqn);

	    if (system("$ADD_SUBSCRIBER $dev $imsi ${MSISDN_PREFIX}$imsi_id $imsi_id $sqn") != 0) {
		warn "Failed to add subscriber $dev to HSS!\n";
		return 0;
	    }
	}
    }

    return 1;
}

# Perl goo
1;
