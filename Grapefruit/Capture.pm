package Grapefruit::Capture;

use 5.006;
use strict;
use warnings;

# import any needed constants from Grapefruit
use Grapefruit;
package Grapefruit;
our @captures;
package Grapefruit::Capture;

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
  my ($num, $matcher) = @_;

  my $self = { num => $num, 
               matcher => $matcher,
	     };

  return bless $self, $class;
}

sub stringify {
  my $self = shift;
  "capture( " . Grapefruit::stringify($self->{num}, $self->{matcher}) . " )";
}

sub operator_coderef {
  my $self = shift;
  my ($num, $matcher) = @$self{qw(num matcher)};
  if ($matcher) {
    return sub {
      my ($parsetree) = @_; # take the parsetree
      if ($matcher->($parsetree)) { # if it matches the pattern
	$captures[$num] = $parsetree; # save it
	return 1;
      } else {
	return 0;
      }
    };
  } else {
    return sub {
      my ($parsetree) = @_; # take the parsetree
      $captures[$num] = $parsetree; # save it
      return 1; # we matched
    };
  }
}

1;
