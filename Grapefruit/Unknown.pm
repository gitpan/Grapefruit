package Grapefruit::Unknown;

use 5.006;
use strict;
use warnings;

# import any needed constants from Grapefruit
use Grapefruit;

# Preamble

# we might need a version here
our $VERSION = '0.00105';

use Carp;

use base qw(Grapefruit::Atom);

# Code below

my $unique;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $num = ++$unique;
  return bless \$num, $class;
}

sub stringify {
  my $self = shift;
  "{$$self}";
}

sub equiv {
  my ($self, $right) = @_;
  if (UNIVERSAL::isa($right, 'Grapefruit::Unknown')) {
    return $$self == $$right; # do the ids match?
  } else {
    return 0;
  }
}

1;
