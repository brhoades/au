#Update Everything
#

use strict;
use warnings;

use Data::Dumper;
use File::Basename;

BEGIN
{
  $0 =~ /([\w\\\:\-\.]+\\)[\w\.\-]+\.[\w]+/;
  
  push @INC, $1;
}
use au::globals;
use au::install;

sub main
{
  foreach my $upref (keys %updates)
  {
    my %up = %{$updates{$upref}};
    my @inst;
    
    #next unless checkSyntax( %up );
        
    if( !$up{'flags'} )
    {
      croak( "Need flags: ".human( $up{'name'} )."\n" );
      next;
    }
    next if( 'av' ~~ $up{'flags'} );
    
    print human( $up{'name'} ).":\n";

    my $en = 'en' ~~ $up{'flags'};
    
    #Update status
    print "  Status: ".( $en ? "enabled" : "disabled" )."\n";
    
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
    print "  Installed: ".( @inst > 0 ? "true" : "false" )."\n";
    
    if( @inst && @inst > 0 )
    {
      #Version list
      versionList( @inst );
      
      #Update available
      if( updateAvail( \@inst, \%up ) )
      {
        print "   Action: Updating\n";
      }
      elsif( $up{'flags'} ~~ 'req' )
      {
        print "   Action: Installing (required)\n";
      }
      else
      {
        print "  Action: None\n";
      }
    }
    
    print "\n";
  }
}

sub versionList
{
  my %vers;
  my @inst = @_;
  my $num = @inst;
  my $first = 1;
  print "   Version".($num == 1 ? "" : "s").": ";
  
  foreach my $keyr (@inst)
  {
    my %key = %$keyr;
    
    $key{'DisplayVersion'} =~ s/\.([0]+\.?)//; #Remove extraneous zeros
    
    $vers{$key{'DisplayVersion'}} = 1;
  }
   
  foreach my $version (keys %vers)
  {
    if( $first )
    {
      print $version;
    }
    else
    {
      print ", $version";
    }
  }
  
  print "\n";
}

sub updateAvail
{
  my @inst = @{$_[0]};
  my %up = %{$_[1]};
  my $ret = 0;
  my %vers;
  
  print "   Latest Available: ";
  my $tempup = $up{'version'};
  $tempup =~ s/\.([0]+\.?)//; #Remove extraneous zeros
  print $tempup."\n";

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

main();