package Grapefruit::Atom;

use 5.006;
use strict;
use warnings;

# import any needed constants from Grapefruit
use Grapefruit;
BEGIN { *D_OPERATOR = *Grapefruit::D_OPERATOR };

# Preamble

# we might need a version here
our $VERSION = '0.00105';

use Carp;
use Scalar::Util qw(blessed);

use overload
  '==' => "operator_equals",
  'bool' => "operator_bool",
  '""' => "operator_str",
  '0+' => "operator_num",
  nomethod => "operator_wrap";

# code below

# this black magic appears to be needed (5.6.1)
sub operator_equals {
  shift->operator_wrap(@_, '==');
}

sub operator_str {
  D_OPERATOR and print "operator_str ", overload::StrVal($_[0]), "\n";
  return shift;
}

sub operator_num {
  D_OPERATOR and print "operator_num ", overload::StrVal($_[0]), "\n";
  return shift;
}

sub operator_bool {
  D_OPERATOR and print "operator_bool ", overload::StrVal($_[0]), "\n";
  return shift;
}

sub operator_wrap {
  my ($obj, $other, $inv, $meth) = @_;
  D_OPERATOR and printf "operator_wrap obj=%s other=%s inv=$inv meth=$meth\n",
#    (blessed($obj) and overload::Overloaded($obj) ? "?" : (defined $obj ? $obj : 'undef')),
#    (blessed($other) and overload::Overloaded($other) ? "?" : (defined $other ? $other : 'undef'));
    (defined $obj ? $obj : 'undef'),
    (defined $other ? $other : 'undef');
  ($obj, $other) = ($other, $obj) if $inv;
  my $rv = Grapefruit::run_rules(Grapefruit::Compound->new("operator::$meth", $obj, $other));
  D_OPERATOR and print "  ", Grapefruit::stringify($rv), "\n";
  return $rv;
}

