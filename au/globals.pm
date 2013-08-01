#Uninstall module
#

package au::globals;

use strict;
use warnings;

use Exporter;
use Cwd;
use YAML::Tiny;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %updates);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(%updates);

sub wd
{
  my $cwd = cwd;
  
  $cwd =~ s/\//\\/g;
  $cwd .= "\\";
  
  return $cwd;
}

##########
# readUpdates
# Reads updates in from our exe folder and categorizes them via regex
##########
sub readUpdates
{
  my $yr = YAML::Tiny->new;
  my $cfile = wd()."\\exe\\index.txt";
  
  $yr = YAML::Tiny->read( $cfile )
    or die( YAML::Tiny->errstr() );

  return %{$yr->[0]};
}

%updates = readUpdates( );

return 1;
