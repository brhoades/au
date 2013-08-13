#Update Everything
#

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use Getopt::Long;

BEGIN
{
  $0 =~ /([\w\\\:\-\.\$]+\\)[\w\.\-]+\.[\w]+/;
  
  push @INC, $1;
}
use au::globals;
use au::install;

my ($dryrun, $fork);
GetOptions("dryrun" => \$dryrun,
           "fork" => \$fork);

sub main
{
  my (@update, @install);
  
  die unless cnf( $fork );
  
  foreach my $upref (keys %updates)
  {
    my %up = %{$updates{$upref}};
    my (@inst);
    
    #next unless checkSyntax( %up );

    if( !$up{'flags'} )
    {
      croak( "Need flags: ".human( $up{'name'} )."\n" );
      next;
    }
    next if( 'av' ~~ $up{'flags'} );
    
    pr(human( $up{'name'} ).": ");
    pr("\n", 2);

    my $en = 'en' ~~ $up{'flags'};
    
    #Update status
    pr("  Status: ".( $en ? "enabled" : "disabled" )."\n", 2);
    
    next unless $en;
    
    #Install list
    my $strname;
    if( not $up{'unregex'} )
    {
      $strname = $up{'name'};
      $strname =~ s/\$[A-Za-z]//g; #remove variable subs
      $strname =~ s/\ +$//; #trim whitespace
    }
    else
    {
      $strname = $up{'unregex'};
    }
    @inst = isInstalled( 'DisplayName' => $strname );
    pr("  Installed: ".( @inst > 0 ? "true" : "false" )."\n",2);
    
    if( @inst && @inst > 0 )
    {
      #Version list
      versionList( @inst );
    }
    
    #Update available
    if( updateAvail( \@inst, \%up ) )
    {
      pr("  Action: ",2 );
      pr("Updating");
      push @update, [$updates{$upref}, \@inst];
    }
    elsif( 'req' ~~ $up{'flags'} && @inst == 0 )
    {
      pr("  Action: ", 2);
      pr("Installing (required)");
      push @install, $updates{$upref};
    }
    elsif( @inst > 1 )
    {
      pr("  Action: ", 2);
      pr("Cleaning (multiple versions)");
      push @update, [$updates{$upref}, \@inst];
    }
    else
    {
      pr("  Action: None, ", 2);
      pr("Installed/up to date");
    }
  
    pr("\n");
  }

  pr("\n\n");
  processInstalls( @install );
  processUpdates( @update );
}

sub versionList
{
  my %vers;
  my @inst = @_;
  my $num = @inst;
  my $first = 1;
  pr("   Version".($num == 1 ? "" : "s").": ", 2);
  
  foreach my $keyr (@inst)
  {
    my %key = %$keyr;
    
    $key{'DisplayVersion'} =~ s/\.([0]+[\.]?)$//; #Remove extraneous zeros
    
    $vers{$key{'DisplayVersion'}} = 1;
  }
   
  foreach my $version (keys %vers)
  {
    if( $first )
    {
      pr($version, 2);
    }
    else
    {
      pr(", $version", 2);
    }
  }
  
  pr( "\n", 2 );
}

sub updateAvail
{
  my @inst = @{$_[0]};
  my %up = %{$_[1]};
  my $ret = 0;
  my %vers;
  
  pr("   Latest Available: ", 2);
  my $tempup = $up{'version'};
  $tempup =~ s/\.([0]+\.?)$//; #Remove extraneous zeros
  pr( $tempup."\n", 2);

  foreach my $keyr (@inst)
  {
    my %key = %$keyr;

    $vers{$key{'DisplayVersion'}} = 1;
  }
   
  foreach my $version (keys %vers)
  {
    $ret = 1 if( cVer( $up{'version'}, $version ) );
  }
  
  return $ret;
}

sub processUpdates
{
  header( "Processing Updates" );
  pr("\n");
  
  foreach my $packref (@_)
  {
    my @packed = @$packref;
    #unpack
    my %up = %{$packed[0]};
    my @inst = @{$packed[1]};
    
    foreach my $install (@inst)
    {
      next if $dryrun;
      unInstall( 'UpdateKey' => \%up,
                 'UninstallKey' => \%{$install} ); 
    }
    
    install( 'UpdateKey' => \%up );
  }
}

sub processInstalls
{
  header( "Processing Installs" );
  pr("\n");
  
  my @packed = @_;
  #unpack
  
  foreach my $upref (@packed)
  {
    my %up = %$upref;
    
    install( 'UpdateKey' => \%up );
  }
}

header( "Multiprogram Autoupdate", "by Billy Rhoades" );
pr("\n\n");
sleep(3);

main();