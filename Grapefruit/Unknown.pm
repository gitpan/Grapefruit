package Grapefruit::Unknown;

use 5.006;
use strict;
use warnings;

# import any needed constants from Grapefruit
use Grapefruit;

# Preamble

# we might need a version here
our $VERSION = '0.00104';

use Carp;

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

1;
