#Install module
#

package au::install;

use strict;
use warnings;

use Exporter;
use au::globals;
use Win32::TieRegistry( Delimiter => "/" );
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(isInstalled);

##########
# isInstalled
# isInstalled( ['KeyName' => qr regextotestagainst]+  );
#   Can take any number of arguments in either the hash or the array.
#   Common possible keys w/ example text
#   DisplayName => "Mozilla Firefox 21.0 (x86 en-US)"
#   DisplayVersion => "21.0"
#   Publisher => "Mozilla"
#   UninstallString => "C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe"
# Returns: The uninstall key for what's found. If not found, 0.
##########
sub isInstalled
{
  if( not @_ )
  {
    carp( "Missing arguments: @_" );
    return 0;
  }
  
  my %arg = @_;

  my @uninKeys = ( 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/',
                   'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall/' );
  
  # Loop through both locations
  foreach my $ukey (@uninKeys)
  {
    # Cycle through the keys in one spot
    foreach my $hkey (keys %{$Registry->{$ukey}})
    {
      my $key = $Registry->{$ukey}->{$hkey};
      my $return;

      # Check this one against our arguments
      foreach my $argk (keys %arg)
      {
        last unless defined $key->{$argk};
        
        if( !( $key->{$argk} =~ m/$arg{$argk}/i ) )
        {
          $return = 0;
          last;
        }
        else
        {
          if( defined $return )
          {
            $return &= 1;
          }
          else
          {
            $return = 1;
          }
        }
      }
      # Done, what did we find
      next unless $return;
      
      # We found something, gather up and leave
      my %nreturn;
      
      # Remove leading / before keys
      foreach my $tkey (keys %$key)
      {
        my $nkey = $tkey;
        $nkey  =~ s/^\///;
        
        $nreturn{$nkey} = $key->{$tkey};
      }
      
      return %nreturn;
    }
  }
  
  return 0;
}

##########
# unInstall
# unInstall( 'UpdateKey' => %updatekey,
#            'UninstallKey' => %uninstall ) this uses the uninstall 
#                                           key from isInstalled
#   Uninstalls a program and calls any pre/posts
#   Does not check for installation
# Returns: 0 on error, 1 on success
##########

sub uninstall
{
  my %args = @_;
  
  if( not defined $args{'UpdateKey'} )
  {
    carp( "Missing argument 'UpdateKey', got: @_" );
    return;
  }
  elsif( not defined $args{'UninstallKey'} )
  {
    carp( "Missing argument 'UninstallKey', got: @_" );
    return;
  }
  
  my %upkey = $args{'UpdateKey'};
  my %unkey = $args{'UninstallKey'};
  
  msg( "Uninstalling ".$unkey{'DisplayName'}.":\n" )
  
  # At this point we assume I didn't screw anything up
  # FIXME: I will
  if( not defined $upkey{'uninstall'} )
  {
    carp( "Called uninstall with no uninstall defined: @_" );
  }
  
  if( $upkey{'uninstall'} =~ m/\$2/ )
  {
    $un = $upkey{'uninstall'};
    $un =~ s/\$2/$unkey{'UninstallString'}/;
    my $ret = 1;
    
    if( defined $upkey{'preun'} )
    {
      msg( "\tPre: " );
      $ret =& eval( $upkey{'preun'} );
      msg( "done\n" );
    }
    
    $ret =& system( $un );
    
    if( defined $upkey{'postun'} )
    {
      msg( "\tPost: " );
      $ret =& eval( $upkey{'postun'} );
      msg( "\tdone\n";
    }
    
    if( $ret )
    {
      msg( "\tDone!\n" );
    }
    else
    {
      croak( "\tFailed!\n" );
      return $ret;
    }
  }
  elsif( $upkey{'uninstall'} =~ m/;$/ )
  {
    #No pres or posts since this is a function itself
    eval( $upkey{'uninstall'} );
  }
  
  return 1;
}

##########
# Install
# Install( 'UpdateKey' => %updatekey )
#   Installs a program and calls any pre/posts
#   Does not check for prior installation
# Returns: 0 on error, 1 on success
##########

sub install
{
  
}
