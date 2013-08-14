#Uninstall module
#

package au::globals;

use strict;
use warnings;
use version;

use Exporter;
use YAML::Tiny;
use Win32::IPConfig;
use Win32::DriveInfo;
use Win32::SystemInfo;
use File::Basename;
use Log::Message::Simple qw[msg error debug carp croak cluck confess];
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %updates);

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(updateFile wd human cVer header pr cInfo carp croak cnf readUpdates);

##########
# wd( void )
# Returns: Wraps cwd and returns a Windows-friendly path to the current directory
#   the script is in. 
##########
sub wd
{
  $0 =~ /([\w\\\:\-\.\$]+\\)[\w\.\-]+\.[\w]+/;

  return $1;
}

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
    next if( not defined $file );
    
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
    $file =~ /([\w\\\:\-\.\$]+\\)([\w\.\-]+\.[\w]+)$/;
    my $fname = $2;
    
    if( $fname =~ m/$update{'regex'}/i )
    {
      return $file;
    }
  }
  
  $update{'name'} =~ s/\$\s[A-Za-z]//g;
  
  #carp( "Update not found: ".$update{'name'}."\n" );
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
#   Partially from: http://perlgems.blogspot.com/2012/06/retrieve-windows-system-information.html
# Returns: Nothing
##########
sub cInfo
{
  header( "Computer Information" );
  
  pr( "Name: ".Win32::NodeName()."\n" );
  pr( "Domain: ".Win32::DomainName()."\n" );
  pr( "OS: ".Win32::GetOSDisplayName()."\n" );
  pr( "FS: ".Win32::FsType()."\n" );

  my %processor;
  Win32::SystemInfo::ProcessorInfo(%processor);

  pr( $processor{"Processor0"}{ProcessorName}."\n" );
  pr( "  Family: " . $processor{"Processor0"}{Identifier}."\n" );

  for( my $i=0; $i<$processor{NumProcessors}; $i++)
  {
    pr( "  Core$i: " . $processor{"Processor$i"}{MHZ} . "MHz\n" );
  }

  my %memory;
  Win32::SystemInfo::MemoryStatus(%memory, 'GB');
  pr( "RAM: ".sprintf( "%.2f", $memory{TotalPhys})." GB\n" );

  my %dtypes=(0 => "Undertmined",
  1 => "Does Not Exist",
  2 => "Removable",
  3 => "Hardrive",
  4 => "Network",
  5 => "CDROM",
  6 => "RAM Disk");

  my @drives = Win32::DriveInfo::DrivesInUse();
  pr( "Drives: \n" );
  foreach my $drive (@drives)
  {
    my $type = Win32::DriveInfo::DriveType($drive);
    if( $type > 1 && $type < 5 )
    {
      my @ds = Win32::DriveInfo::DriveSpace($drive);
      next unless defined $ds[5] && defined $ds[6];
      my $space = $ds[5];
      my $free = $ds[6];
      my $used = $space-$free;
      my $usedp = sprintf( "%.2f", ( $used/$space * 100) );
      my $extra = "\n";
      
      $free = sprintf( "%.2f", $free );
      $used = sprintf( "%.2f", $used/(1024**3) );
      $space = sprintf( "%.2f", $space/(1024**3) );
      
      if( $type == 4 )
      {
        $extra = `net use $drive:`;
        $extra =~ /(\\\\[\w\.\\]+\s)/;
        $extra = "\n    ".$1;
      }
      
      pr( "  $drive: $dtypes{$type}, $used/$space GiB ($usedp\%)$extra" );
      
    }
    else
    {
      pr( "  $drive: $dtypes{$type}\n" );
    }
  }

  header( "Network Information" );
  my $host = shift || "";
  if(my $ipconfig = Win32::IPConfig->new($host))
  {
    pr( "Hostname: ".$ipconfig->get_hostname."\n" );
    pr( "Domain: ".$ipconfig->get_domain."\n" );

    my @searchlist = $ipconfig->get_searchlist;
    pr( "Search List: @searchlist (".(scalar @searchlist).")\n" );
    pr( "Node Type: ".($ipconfig->get_nodetype)."\n" );

    pr( "IP Routing: ".($ipconfig->is_router() ? "Yes" : "No")."\n" );
    pr( "WINS proxy enabled: ".
        ($ipconfig->is_wins_proxy() ? "Yes" : "No")."\n" );
    pr( "LMHOSTS enabled: ".
        ($ipconfig->is_lmhosts_enabled() ? "Yes" : "No")."\n" );
    pr( "DNS enabled for NetBT: ".
        ($ipconfig->is_dns_enabled_for_netbt() ? "Yes" : "No")."\n" );

    foreach my $adapter ($ipconfig->get_adapters())
    {
      pr( "\nAdapter '".$adapter->get_name()."':\n" );
      pr( "Description: ".$adapter->get_description()."\n" );
      pr( "DHCP enabled: ".
          ($adapter->is_dhcp_enabled() ? "Yes" : "No")."\n" );

      my @ipaddresses = $adapter->get_ipaddresses();
      pr( "IP address(es): @ipaddresses (".(scalar @ipaddresses).")\n" );

      my @subnet_masks = $adapter->get_subnet_masks();
      pr( "Subnet Mask(s): @subnet_masks (".(scalar @subnet_masks).")\n" );

      my @gateways = $adapter->get_gateways();
      pr( "Gateway(s): @gateways (".(scalar @gateways).")\n" );

      pr( "Domain: ".$adapter->get_domain()."\n" );

      my @dns = $adapter->get_dns();
      pr( "DNS Server(s): @dns (".(scalar @dns).")\n" );

      my @wins = $adapter->get_wins();
      pr( "WIN(s): @wins (".(scalar @wins).")\n" );
    }
  }
  
  pr( "\n" );
}

##########
# cnf( $fork )
#   Copies n' Forks--- copies the program and files off the thumb drive and forks
#     to a new process. If this is a fork then we just go with what we have
#     as a safeguard.
# Returns: 1 if in C (to continue the script) 0 if on the thumb drive (dies)
##########
sub cnf
{
  my $fork = $_[0];
  my $wd = wd( );
  my $ndir = $ENV{'TEMP'}."\\au";
  
  return 1 if( $wd =~ m/C\:/i || $fork );
 
  pr( "Copying and forking: \n" );
    
  system("XCOPY /s /y /i \"$wd*\" \"$ndir\"");
  $0 =~ /[\:\$\w\s\-\\\/]*\\([\w_\-\s\.]+\.\w+)$/;
  exec("\"$ndir\\$1\" -fork");
}

##########
# header( $text )
#   Prints out a nice header
# Returns: Nothing
##########
sub header
{
  pr("#"x80);
  
  foreach my $text (@_)
  {
    print " "x((80-length($text))/2);
    pr("$text\n");
  }
  
  pr("#"x80);
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
