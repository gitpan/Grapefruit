package Grapefruit::Compound;

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

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my ($func, @args) = @_;
  croak "Function name needs to be a simple scalar" if ref $func;
  my $self = [$func, @args];
  return bless $self, $class;
}

# this is a method, but it calls the multimethod...
sub stringify {
  my $self = shift;
  #print "$self->[0] ".join(" ", @$self[1..$#$self])."\n";
  "$self->[0]( ".join(", ", map Grapefruit::stringify($_), @$self[1..$#$self])." )";
}

sub _do_match {
  my ($self, $parsetree) = @_;
  if (UNIVERSAL::isa($parsetree, 'Grapefruit::Compound')) {
    return Grapefruit::_do_match_apply($self, $parsetree);
  } else {
    return 0;
  }
}

sub equiv {
  my ($self, $right) = @_;
  if (UNIVERSAL::isa($right, 'Grapefruit::Compound')) {
    return 0 unless $self->[0] eq $right->[0];
    return 0 unless @$self == @$right;
    for (1..$#$self) {
      return 0 unless Grapefruit::equiv($self->[$_], $right->[$_]);
    }
    return 1;
  } else {
    return 0;
  }
}

1;
