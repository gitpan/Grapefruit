package Grapefruit::Pattern;

use 5.006;
use strict;
use warnings;

# import any needed constants from Grapefruit
use Grapefruit;
BEGIN { *D_PATTERN = *Grapefruit::D_PATTERN };
package Grapefruit;
our @captures;
package Grapefruit::Pattern;

# Preamble

# we might need a version here
our $VERSION = '0.00105';

use Carp;

# eek! note that the inherited constructed *isn't* called. ouch!
use base qw(Grapefruit::Atom);

use overload
  '&{}' => "operator_coderef";

# Code below

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my ($patterntree, $predicate) = @_;

  my $self = { patterntree => $patterntree,
               predicate => $predicate,
	     };

  return bless $self, $class;
}

sub stringify {
  my $self = shift;
  "pattern( " . Grapefruit::stringify($self->{patterntree}) . ", " .
    Grapefruit::stringify($self->{predicate}) . " )";
}

sub operator_coderef {
  my $self = shift;
  my ($patterntree, $predicate) = @$self{qw(patterntree predicate)};
  return sub {
    my ($parsetree) = @_;
    local @captures = ();
    D_PATTERN and print "* Patterntree: $patterntree\n";
    D_PATTERN and print "* Parsetree: $parsetree\n";

    # recursivly process the two trees in parallel
    my $success = Grapefruit::_do_match($patterntree, $parsetree);

    # check the predicate
    if (defined $predicate) {
      $success &&= $predicate->(@captures);
    }
    
    D_PATTERN and print "* Captures: @captures\n";
    D_PATTERN and print "* Success: $success\n";
    
    if ($success) {
      return wantarray ? @captures : 1;
    } else {
      return wantarray ? () : 0;
    }
  };
}

1;
