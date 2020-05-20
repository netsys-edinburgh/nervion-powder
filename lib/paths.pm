package oaipaths;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( $OAI_BASEDIR $OAI_PNDIR $OAI_ETCDIR $OAI_LIBDIR $OAI_BINDIR $OAI_EPCDIR $OAI_RANDIR $OAI_LOGDIR $OAI_LOCKDIR $OAI_SYSETC );

our $OAI_BASEDIR  = "/local/repository";
our $OAI_PNDIR    = "$OAI_BASEDIR";
our $OAI_ETCDIR   = "$OAI_PNDIR/etc";
our $OAI_LIBDIR   = "$OAI_PNDIR/lib";
our $OAI_BINDIR   = "$OAI_PNDIR/bin";
our $OAI_EPCDIR   = "/opt/oai/openair-cn";
our $OAI_RANDIR   = "/opt/oai/openairinterface5g";
our $OAI_LOGDIR   = "/var/log/oai";
our $OAI_LOCKDIR  = "/var/lock";
our $OAI_SYSETC   = "/usr/local/etc/oai";

# Add the correct library directory to the include list.
if (-d $OAI_LIBDIR) {
    unshift(@INC, $OAI_LIBDIR);
    # Try to make the OAI log directory if it doesn't exist.
    if (!-d $OAI_LOGDIR) {
	system("mkdir $OAI_LOGDIR > /dev/null 2>&1");
    }
}

# Perl goo
1;
