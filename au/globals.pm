#Uninstall module
#

package au::globals;

use strict;
use warnings;

use Exporter;
use Cwd;
use YAML::Tiny;
use Log::Message::Simple qw[msg error debug carp croak cluck confess];
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %updates);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(%updates updateFile wd human);

##########
# wd( void )
# Returns: Wraps cwd and returns a Windows-friendly path to the current directory
#   the script is in. 
##########
sub wd
{
  my $cwd = cwd;
  
  $cwd =~ s/\//\\/g;
  $cwd .= "\\";
  
  return $cwd;
}

%updates = readUpdates( );

##########
# readUpdates( void )
#   Reads updates in from our exe folder and categorizes them via regex
# Returns: hash of 
##########
sub readUpdates
{
  my $yr = YAML::Tiny->new;
  my $cfile = wd()."\\exe\\index.txt";
  
  $yr = YAML::Tiny->read( $cfile )
    or die( YAML::Tiny->errstr() );

  my %updates =  %{$yr->[0]};
  
  foreach my $upkey (keys %updates)
  {
    my %update = %{$updates{$upkey}};
    next if 'av' ~~ $update{'flags'};
    
    my $file = updateFile(%update);
    
  }
  
  return %updates;
}

##########
# updateFile( %updateKey ) (Pass it the update key from readUpdates)
# Returns: a full path to the update file for this program, screams and returns undef
#   if one doesn't exist.
##########

sub updateFile
{
  my %update = @_;
  my @files = glob wd()."\\exe\\*";
  
  foreach my $file (@files)
  {
    $file =~ /[\w_\-\\:]*\\([\w_\-]+.\w+)/i;
    my $fname = $1;
    #print $fname." and ".$update{'regex'}."\n";
    if( $fname =~ $update{'regex'} )
    {
      return $file;
    }
  }
  
  #FIXEME: Should insert version
  $update{'name'} =~ s/\$[A-Za-z]//g;
  
  carp( "Unknown update: ".$update{'name'}."\n" );
  return undef;
}

##########
# human( $updatekey{'name'} ) (Pass it the update key's name value from readUpdates)
# Returns: a human readable name for that update
##########
sub human
{
  my $name = $_[0];
  
  if( not defined $name )
  {
    carp( "No argument passed to human.\n" );
  }
  
  #FIXME: This should get the version
  $name =~ s/\$[0-9A-Za-z]//g;
  
  #Trim whitespace
  $name =~ s/[ ]+$//;
  
  return $name;
}

return 1;
