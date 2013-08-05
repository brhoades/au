#Uninstall module
#

package au::globals;

use strict;
use warnings;

use Exporter;
use YAML::Tiny;
use File::Basename;
use Win32::Exe;
use Win32::Exe::Manifest;
use Win32::MSI::HighLevel;
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
  $0 =~ /([\w\\\:\-\.]+\\)[\w\.\-]+\.[\w]+/;

  return $1;
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
  my $cfile = wd()."exe\\index.txt";
  $yr = YAML::Tiny->read( $cfile )
    or die( YAML::Tiny->errstr() );

  my %updates =  %{$yr->[0]};
  
  foreach my $upkey (keys %updates)
  {
    my %update = %{$updates{$upkey}};
    next if 'av' ~~ $update{'flags'};
    
    my $file = updateFile(%update);
    $updates{$upkey}{'file'} = $file;
    
    if($update{'version'} == 1)
    {
      basename($file) =~ /$update{'regex'}/;
      my $version = $1;
      if( not defined $version )
      {
        carp "Please update regex for ".$update{'name'}." or switch its version type to 0\n";
      }
      $updates{$upkey}{'version'} = $1;
    }
    else
    {
      if($file =~ m/\.exe$/i)
      {
        my $exe = Win32::Exe->new($file);
        my $mani = $exe->get_manifest;
        print $mani->output."\n";
       #print $exe->get_version_info."\n\n";
        
        #print $details{'Version'};
      }
      elsif( $file =~ m/\.msi$/i )
      {
        my $msi = Win32::MSI::HighLevel->new("-file" => $file, "-mode" => Win32::MSI::HighLevel::Common::kMSIDBOPEN_READONLY);      
        
        print $msi->getProduct()."\n\n";
      }
      else
      {
        carp "Unknown file type for $file.\n"; 
      }
    }
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
    $file =~ /[A-Z]\:[\w_\s\-\\]*\\([\w_\-\s]+.\w+)/i;
    my $fname = $1;
    #print $fname." and ".$update{'regex'}."\n\n";
    if( $fname =~ m/$update{'regex'}/i )
    {
      return $file;
    }
  }
  
  $update{'name'} =~ s/\$\s[A-Za-z]//g;
  
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

##########
# cInfo( )
#   Prints out information about this computer.
# Returns: Nothing
##########
sub cInfo
{
  
  
}

return 1;
