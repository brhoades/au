#Uninstall module
#

package au::globals;

use strict;
use warnings;
use version;

use Exporter;
use YAML::Tiny;
use File::Basename;
use Log::Message::Simple qw[msg error debug carp croak cluck confess];
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %updates);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(%updates updateFile wd human cVer header pr carp croak);

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
    if( not defined $file )
    {
      delete $updates{$upkey};
      next;
    }
    $updates{$upkey}{'file'} = $file;
    
    basename($file) =~ /$update{'regex'}/;
    my $version = $1;
    if( not defined $version )
    {
      carp "Please update regex for ".$update{'name'}." or switch its version type to 0\n";
    }
    $updates{$upkey}{'version'} = $1;
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
    $file =~ /[A-Z]\:[\w_\s\-\\]*\\([\w_\-\s\.]+.\w+)/i;
    my $fname = $1;
    
    if( $fname =~ m/$update{'regex'}/i )
    {
      return $file;
    }
  }
  
  $update{'name'} =~ s/\$\s[A-Za-z]//g;
  
  carp( "Update not found: ".$update{'name'}."\n" );
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
# cVer
#   Compares two versions. Essentially drops periods and u to make a large number then compares.
#   If left side > right, returns true, otherwise false.
# Returns: 1 or 0
##########
sub cVer
{
  my $lver = $_[0];
  my $rver = $_[1];
  
  #JRE catches
  # The DisplayVersion tends to have an extra zero padded on
  if( $lver =~ m/[0-9]u[0-9]{1,2}/i )
  {
    $lver =~ s/u/\.0\./g;
    $lver .= 0;
  }

  if( $rver =~ m/[0-9]u[0-9]{1,2}/i )
  {
    $rver =~ s/u/\.0\./g;
    $rver .= 0;
  }
  
  return( version->parse($lver) > version->parse($rver) );
}

##########
# cInfo( )
#   Prints out information about this computer.
# Returns: Nothing
##########
sub cInfo
{
  
  
}

##########
# header( $text )
#   Prints out a nice header
# Returns: Nothing
##########
sub header
{
  pr("#"x79);
  pr("\n");
  foreach my $text (@_)
  {
    print " "x((79-length($text))/2);
    pr("$text\n");
  }
  pr("#"x79);
  pr("\n");
}

sub pr
{
  my $verb = $_[1];
  
  if( not defined $verb )
  {
    $verb = 1;
  }
  
  if( $verb <= 1 )
  {
    print $_[0];
  }
  
  open( my $fh, ">>", wd()."\\log.txt" );
  
  print $fh $_[0];
  
  close $fh;
}

return 1;
