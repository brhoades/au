#log module
#

package au::log;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use feature 'state';
 
#our @log;
state @log;

$VERSION     = 0.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(printl);
@EXPORT_OK   = qw(printl);
%EXPORT_TAGS = ( DEFAULT => \@EXPORT );


##########
# printl
# IN: qr/regex/ to search for
##########
sub printl
{
  my ($text, $print, $verb, $lb) = @_;
  my $message = "";
  
  if( not defined $verb )
  {
    $verb = 0;
  }
  if( not defined $lb )
  {
    $lb = 1;
  }
  
  for( my $i=0; $i<$verb; $i++ )
  {
    $message .= "  ";
  }
  
  my $message = $text.($lb ? "\n" : "");
  
  push @log, $message;
  print $message;
}

return 1;