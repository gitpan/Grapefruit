#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Grapefruit;
use YAML;
use Data::Dumper;

local $YAML::UseCode = 1;

sub True () { return Grapefruit::Compound->new('True') }
sub False () { return Grapefruit::Compound->new('False') }

sub test {
  if (ref $_[0]) {
    if (equiv($_[0], True)) {
      return 1;
    } elsif (equiv($_[0], False)) {
      return 0;
    } else {
      return undef;
    }
  } else {
    return $_[0] ? 1 : 0;
  }
}

for (qw(Solve SuchThat ContainsExpression Ln)) {
  declare $_;
}

print "Defining rules\n";
# ignore the black magic involving $hold. This reduces debugging output and
# makes it (and me) work
{
  local $Grapefruit::hold = 1;

  ## rules for Solve & SuchThat & ContainsExpression
  rule 100, pattern( Solve( (_0() == _1()), _2 ) ),
    sub { SuchThat($_[0] - $_[1], 0, $_[2]) };

  # ContainsExpression(a, b) : is b contained within a?
  rule 10, pattern( ContainsExpression( _0, _1 ), sub { equiv($_[0], $_[1]) } ),
    sub { True };
  rule 15, pattern( ContainsExpression( _0(\&is_atom), _1 ) ),
    sub { False };
  rule 20, pattern( ContainsExpression( _0, _1 ) ),
    sub {
      my ($x, $y) = @_;
      die "Unexpected type of \$x: $x" unless UNIVERSAL::isa($x, 'Grapefruit::Compound');
      for (@$x[1..$#$x]) {
        return True if test( ContainsExpression( $_, $y ) );
      }
      return False;
    };

  # this could be at any precendence level since no other rule matches a
  # two arg SuchThat
  rule 10, pattern( SuchThat( _0, _1 ) ),
    sub { SuchThat( $_[0], 0, $_[1] ) };

  rule 10, pattern( SuchThat( _0, _1, _2 ), sub { equiv($_[0], $_[2]) } ),
    sub { $_[1] };

  rule 20, pattern( SuchThat( _0(\&is_atom), _1, _2 ) ),
    sub { $_[2] };

  rule 30, pattern( SuchThat( _0() + _1(), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], $_[2] - $_[1], $_[3] ) };
  rule 30, pattern( SuchThat( _1() + _0(), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], $_[2] - $_[1], $_[3] ) };

  rule 30, pattern( SuchThat( _0() - _1(), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], $_[2] + $_[1], $_[3] ) };
  rule 30, pattern( SuchThat( _1() - _0(), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], $_[1] - $_[2], $_[3] ) };

  rule 30, pattern( SuchThat( _0() ** _1(), _2, _3),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], $_[2] ** ( 1 / $_[1] ), $_[3] ) };
  rule 30, pattern( SuchThat( _0() ** _1(), _2, _3),
                    sub { test( ContainsExpression( $_[1], $_[3] ) ) } ),
    sub { SuchThat( $_[1], Ln($_[2]) / Ln($_[0]), $_[3] ) };
  
}

print "Solving a problem\n";

my $x = unknown;
my $y = unknown;

sub f {
#  Solve(3 == (3 + ($x**2 + 5)), $x);
  Solve(3 == (3 + ($x**2 - 5)), $x);
}

#my $ans = Solve(3 == (3 + ($x**2 + 5)), $x);
my $ans = f();
#print Dump $ans;
print "\n";

{
  local $Grapefruit::hold = 1;
#  print "> ", stringify(Solve(3 == (3 + ($x**2 + 5)), $x)), "\n\n";
  print "> ", stringify( f() ), "\n\n";
#  print "> ", stringify(Solve(3, $x)), "\n\n";
#  print "> ", stringify($x**2), "\n\n";
#  print "> ", stringify(2**$x), "\n\n";
#  print "> ", stringify($x**2 + 5), "\n\n";
#  print "> ", stringify(3 + ($x**2 + 5)), "\n\n";
#  print "> ", stringify(3 == (3 + ($x**2 + 5))), "\n\n"; # this blows up
#  print "> ", stringify((3 + ($x**2 + 5)) == 3), "\n\n"; # this blows up
}
print "< ", stringify($ans), "\n\n";

#print "< ", stringify( ContainsExpression( Add( 4, 5 ), Add( 4, 5 ) ) ), "\n\n";
#print "< ", stringify( ContainsExpression( $x, Add($x, $y) ) ), "\n\n";
#print "< ", stringify( ContainsExpression( Add( $x, Add( $y, 3 ) ),
#                                           Add( $y, 3 ) ) ), "\n\n";

#print "< ", stringify( SuchThat( $x, Add(4,5), $x ) ), "\n\n";
#print "< ", stringify( SuchThat( 3, Add(4,5), $x ) ), "\n\n";

__END__

=head1 NAME

grapefruit.pl - A simple demonstration (and test) of Grapefruit

=head1 SYNOPSIS

  ./grapefruit.pl

=head1 DESCRIPTION

This will eventually be a front-end interface to the case, but for the moment
see the pod for L<Grapefruit> for more information.

=head1 AUTHOR

Benjamin Smith <bsmith@cpan.org>, usually available as integral on the
freenode irc network

=cut
