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

for (qw(Solve Equals Add Power SuchThat Sub ContainsExpression Div Mult Ln)) {
  declare $_;
}

print "Defining rules\n";
# ignore the black magic involving $hold. This reduces debugging output and
# makes it (and me) work
{
  local $Grapefruit::hold = 1;

  if (0) {

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

  rule 0, pattern( Sub( _0(\&is_num), _1(\&is_num) ) ),
    sub { $_[0] - $_[1] };

  ## rules for Solve & SuchThat & ContainsExpression
  rule 100, pattern( Solve( Equals( _0, _1 ), _2 ) ),
    sub { SuchThat(Sub($_[0], $_[1]), 0, $_[2]) };

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

  rule 30, pattern( SuchThat( Add(_0,_1), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], Sub( $_[2], $_[1] ), $_[3] ) };
  rule 30, pattern( SuchThat( Add(_1,_0), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], Sub( $_[2], $_[1] ), $_[3] ) };

  rule 30, pattern( SuchThat( Sub(_0,_1), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], Add( $_[2], $_[1] ), $_[3] ) };
  rule 30, pattern( SuchThat( Sub(_1,_0), _2, _3 ),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], Sub( $_[1], $_[2] ), $_[3] ) };

  rule 30, pattern( SuchThat( Power(_0,_1), _2, _3),
                    sub { test( ContainsExpression( $_[0], $_[3] ) ) } ),
    sub { SuchThat( $_[0], Power( $_[2], Div( 1, $_[1] ) ), $_[3] ) };
  rule 30, pattern( SuchThat( Power(_0,_1), _2, _3),
                    sub { test( ContainsExpression( $_[1], $_[3] ) ) } ),
    sub { SuchThat( $_[1], Div( Ln($_[2]), Ln($_[0]) ), $_[3] ) };
  
  }
}

print "Solving a problem\n";

my $x = unknown;
my $y = unknown;

my $ans = Solve(Equals(3, Add(3, Add(Power($x, 2), 5))), $x);
#print Dump $ans;

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

=head1 AUTHOR

Benjamin Smith <bsmith@cpan.org>, usually available as integral on the
freenode irc network

=cut
