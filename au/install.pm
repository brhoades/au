#Install module
#

package au::install;

use strict;
use warnings;

use Exporter;
use au::globals;
use au::special;
use Win32::TieRegistry( Delimiter => "/" );
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(isInstalled unInstall install);

##########
# isInstalled
# isInstalled( ['KeyName' => qr regextotestagainst]+  );
#   Can take any number of arguments in either the hash or the array.
#   Common possible keys w/ example text
#   DisplayName => "Mozilla Firefox 21.0 (x86 en-US)"
#   DisplayVersion => "21.0"
#   Publisher => "Mozilla"
#   UninstallString => "C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe"
# Returns: All uninstallkeys matching the critera in a array of hashrefs. If not found, a blank array.
##########
sub isInstalled
{
  if( not @_ )
  {
    carp( "Missing arguments: @_" );
    return 0;
  }
  
  my %arg = @_;
  my @ret;

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
      
      # We found something, gather up everything
      my %nreturn;
      
      # Remove leading / before keys
      foreach my $tkey (keys %$key)
      {
        my $nkey = $tkey;
        $nkey  =~ s/^\///;
        
        $nreturn{$nkey} = $key->{$tkey};
      }
      
      push @ret, \%nreturn;
    }
  }
  
  return @ret;
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

sub unInstall
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
  
  my %upkey = %{$args{'UpdateKey'}};
  my %unkey = %{$args{'UninstallKey'}};
  
  pr( "Uninstalling ".$unkey{'DisplayName'}.":\n" );
  
  # At this point we assume I didn't screw anything up
  # FIXME: I will
  if( not defined $upkey{'uninstall'} )
  {
    #FIXME: Make a funciton for this
    if( defined $upkey{'preun'} )
    {
      pr( "\tPre: " );
      $ret &= eval( $upkey{'preun'} );
      pr( "done\n" );
    }
    
    $ret &= system( $unkey{'UninstallString'} );
    
    if( defined $upkey{'postun'} )
    {
      pr( "\tPost: " );
      $ret &= eval( $upkey{'postun'} );
      pr( "\tdone\n" );
    }
    
    if( $ret )
    {
      pr( "\tDone!\n" );
    }
    else
    {
      pr( "\tFailed!\n" );
      return $ret;
    }
  }
  elsif( $upkey{'uninstall'} =~ m/\$2/ )
  {
    my $un = $upkey{'uninstall'};
    $un =~ s/\$2/"$unkey{'UninstallString'}"/;
    my $ret = 1;
    
    #FIXME: Make a funciton for this
    if( defined $upkey{'preun'} )
    {
      pr( "\tPre: " );
      $ret &= eval( $upkey{'preun'} );
      pr( "done\n" );
    }
    
    $ret &= system( $un );
    
    if( defined $upkey{'postun'} )
    {
      pr( "\tPost: " );
      $ret &= eval( $upkey{'postun'} );
      pr( "\tdone\n" );
    }
    
    if( $ret )
    {
      pr( "\tDone!\n" );
    }
    else
    {
      pr( "\tFailed!\n" );
      return $ret;
    }
  }
  elsif( $upkey{'uninstall'} =~ m/\$1/ )
  {
    my $un = $upkey{'uninstall'};
    my $upfile = updateFile( %upkey );
    my $ret = 1;
    
    $un =~ s/\$1/"$upfile"/;
    
    #FIXME: Make a function for this
    if( defined $upkey{'preun'} )
    {
      pr( "\tPre: " );
      $ret &= eval( $upkey{'preun'} );
      pr( "done\n" );
    }
    
    $ret &= system( $un );
    
    if( defined $upkey{'postun'} )
    {
      pr( "\tPost: " );
      $ret &= eval( $upkey{'postun'} );
      pr( "\tdone\n" );
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
  my %args = @_;
  
  if( not defined $args{'UpdateKey'} )
  {
    carp( "Missing argument 'UpdateKey', got: @_" );
    return;
  }
  
  my %upkey = %{$args{'UpdateKey'}};
 
  pr( "Installing ".$upkey{'name'}.": ".(defined $upkey{'preun'} ? "\n" : "" ) );
  $|++;
  # At this point we assume I didn't screw anything up
  # FIXME: I will
  if( not defined $upkey{'install'} )
  {
    carp( "Called install with no install defined: @_" );
  }
  
  if( $upkey{'install'} =~ m/\$1/ )
  {
    my $in = $upkey{'install'};
    my $upfile = updateFile( %upkey );
    my $ret = 1;
    
    $in =~ s/\$1/"$upfile"/;
    $in =~ s/\\\%/\%/;
    
    #FIXME: Make a function for this
    if( defined $upkey{'preun'} )
    {
      pr( "\tPre: " );
      $ret &= eval( $upkey{'preun'} );
      pr( "done\n" );
    }
    
    pr( "\tMain: " ) if defined $upkey{'preun'};
    $ret &= system( $in );
    pr( "done\n" );
    
    if( defined $upkey{'postun'} )
    {
      pr( "\tPost: " );
      $ret &= eval( $upkey{'postun'} );
      pr( "\tdone\n" );
    }    
  }
  elsif( $upkey{'install'} =~ m/;$/ )
  {
    #No pres or posts since this is a function itself
    eval( $upkey{'install'} );
  }
  
  pr( "\n\n" );
  
  return 1;
}
