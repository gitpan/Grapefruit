#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Grapefruit;
use YAML;
use Data::Dumper;

local $YAML::UseCode = 1;

for (qw(Solve Equals Add Power SuchThat Sub ContainsExpression)) {
  declare $_;
}

print "Defining rules\n";
# ignore the black magic involving $hold. This reduces debugging output and
# makes it (and me) work
{
  local $hold = 1;

  if (1) {

# prototype rules for addition
  rule 30, pattern( Add( _0, _1(\&is_num) ) ),
    sub { Add( $_[1], $_[0] ) };
  rule 20, pattern( Add( _0(\&is_num), _1(\&is_num) ) ),
    sub { $_[0] + $_[1] };
  rule 10, pattern( Add( _0(\&is_num), Add( _1(\&is_num), _2 ) ) ),
    sub { Add( $_[0] + $_[1], $_[2] ) };

  } else {

  # precedence 0 has builtins like adding two numbers
  rule 0, pattern( Add( _0(\&is_num), _1(\&is_num) ) ),
    sub { $_[0] + $_[1] };

  ## rules for Solve & SuchThat & ContainsExpression
  rule 100, pattern( Solve( Equals( _0, _1 ), _2 ) ),
    sub { SuchThat(Sub($_[0], $_[1]), 0, $_[2]) };

  

  # this could be at any precendence level since no other rule matches a
  # two arg SuchThat
  rule 10, pattern( SuchThat( _0, _1 ) ),
    sub { SuchThat( $_[0], 0, $_[1] ) };

  }
}

print "Solving a problem\n";

my $x = unknown;
my $y = unknown;

print Dump my $ans = Solve(Equals(3, Add(3, Add(Power($x, 2), 5))), $x);

print stringify($ans), "\n";

__END__

=head1 NAME

grapefruit.pl - A simple demonstration (and test) of Grapefruit

=head1 SYNOPSIS

  ./grapefruit.pl

=head1 AUTHOR

Benjamin Smith <bsmith@cpan.org>, usually available as integral on the
freenode irc network

=cut
