#Uninstall module
#

package au::uninstall;

use strict;
use warnings;

use Exporter;
use Data::Dumper;
use au::log;
use Win32::TieRegistry( Delimiter => "/" );
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(isInstalled);

##########
# isInstalled
# IN: qr/regex/ to search for
##########
sub isInstalled
{
  my ($regex) = $_[0];
  my @uninKeys = ( 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/',
                   'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall/' );
 
  foreach my $ukey (@uninKeys)
  {      
    foreach my $hkey (keys %{$Registry->{$ukey}})
    {
      my $key = $Registry->{$ukey}->{$hkey};
      
      printl("Uninstalling " . $key->{'DisplayName'} . ": ");
     # if($key->{'UninstallString'} =~ /^C\:\\.*\.[A-Za-z0-9]+$/
      #   && !(-e $key->{'UninstallString'}))
     # {
        #output("broken install\n");
        #delete $Registry->{$app_key};
        next;
     # }

      #$my $result = run_command("\"" . $uninst->{'UninstallString'} . "\" -ms");
      #sleep(5);

      if(1)#$result)
      {
        #output("done\n");
      }
      else
      {
        #output("failed! Manually removing!\n");
      }
    }
  }
}

return 1;