package Grapefruit::Rule;

use 5.006;
use strict;
use warnings;

# import any needed constants from Grapefruit
use Grapefruit;

# Preamble

# we might need a version here
our $VERSION = '0.00105';

use Carp;

# Code below

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = [@_];
  return bless $self, $class;
}

sub match {
  my $self = shift;
  return $self->[0]->(@_);
}

sub transform {
  my $self = shift;
  return $self->[1]->(@_);
}

1;
