#Uninstall module
#

package au::uninstall;

use strict;
use warnings;

use Exporter;
use au::log;
use Data::YAML;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(%updates);

##########
# readUpdates
# Reads updates in from our exe folder and categorizes them via regex
##########
sub readUpdates
{
  my $yr = Data::YAML::Reader->new;
  $yr->read( ".\\exe\\index.txt" );
}

return 1;