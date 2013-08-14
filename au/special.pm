#Uninstall module
#

package au::special;

use strict;
use warnings;

use Exporter;
use Win32::TieRegistry;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %updates);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(firefox jre prechrome postavast postflash);


sub firefox
{
  
}

sub jre
{
  my $j32 = $Registry->{'HKEY_LOCAL_MACHINE/SOFTWARE/JavaSoft'};
  my $out = ( $j32->{'SPONSORS'} = "DISABLE" );
  
  return( $out ? 1 : 0 );
}

sub jre64
{
  my $j64 = $Registry->{'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/JavaSoft'};
  my $out = ( $j64->{'SPONSORS'} = "DISABLE" );
  
  return( $out ? 1 : 0 );
}

sub prechrome
{
  
}

sub postavast
{
  
}

sub postflash
{
  
}

return 1;
