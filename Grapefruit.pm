package Grapefruit;

use 5.006;
use strict;
use warnings;

# Constants

sub D_PATTERN () { 0 }
sub D_RULES () { 0 }
sub D_EQUIV () { 0 }
sub D_OPERATOR () { 0 }
sub D_TRACE () { 0 }

# Preamble

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw( declare rule unknown stringify
                  capture is_num pattern equiv
		  is_atom
		);
for (0..9) { push @EXPORT, "_$_" } # all the shortened capture sequences

our $VERSION = '0.00105'; # increment _after_ each distribution

use Carp;
use YAML;
use Scalar::Util qw( blessed );

# Submodules
use Grapefruit::Atom;
use Grapefruit::Compound;
use Grapefruit::Rule;
use Grapefruit::Unknown;
use Grapefruit::Pattern;
use Grapefruit::Capture;

# Code below

our @captures;

sub capture ($;$) {
  my ($num, $matcher) = @_;
  return Grapefruit::Capture->new($num, $matcher);
}
sub _0 (;$) { &capture(0, @_) } # the & does magic, do not remove
sub _1 (;$) { &capture(1, @_) }
sub _2 (;$) { &capture(2, @_) }
sub _3 (;$) { &capture(3, @_) }
sub _4 (;$) { &capture(4, @_) }
sub _5 (;$) { &capture(5, @_) }
sub _6 (;$) { &capture(6, @_) }
sub _7 (;$) { &capture(7, @_) }
sub _8 (;$) { &capture(8, @_) }
sub _9 (;$) { &capture(9, @_) }

sub _do_match_apply {
  my ($patterntree, $parsetree) = @_;
  D_PATTERN and print "*** _do_match_apply [@$patterntree] [@$parsetree]\n";
  if ($patterntree->[0] eq $parsetree->[0] and
      @$patterntree == @$parsetree) {
    for (1..$#$patterntree) {
      _do_match($patterntree->[$_], $parsetree->[$_]) or
        return 0;
    }
    D_PATTERN and print "**** successful\n";
    return 1;
  } else {
    return 0;
  }
}

sub _do_match {
  my ($patterntree, $parsetree) = @_;
  D_PATTERN and print "** _do_match $patterntree $parsetree\n";
  if (blessed $patterntree and $patterntree->can('_do_match')) {
    $patterntree->_do_match($parsetree);
  } elsif (ref $patterntree eq "ARRAY" and
      ref $parsetree eq "ARRAY") {
    return _do_match_apply($patterntree, $parsetree);
  } elsif (ref $patterntree eq "Grapefruit::Capture") {
    # probably just handle all code refs like this
    D_PATTERN and print "*** calling the pattern::capture closure with $parsetree\n";
    return $patterntree->($parsetree);
  } elsif (not ref $patterntree or
           not ref $parsetree) {
    if (is_num($patterntree) and is_num($parsetree)) {
      return $patterntree == $parsetree;
    } else {
      return $patterntree eq $parsetree;
    }
  } else {
    D_PATTERN and print "*** not sure how to handle this\n";
    carp "Not sure how to handle this, sort it out yourself";
    return 0;
  }
}

# take a parsetree and generate a matcher
sub pattern ($;$) {
  my ($patterntree, $pred) = @_;

  return Grapefruit::Pattern->new($patterntree, $pred);
}

our %rules;
sub rule ($$$) {
  my ($prec, $match, $func) = @_;
  croak "precedence must be numeric" unless $prec =~ /^\d+$/;

  D_RULES and print "Creating rule at precedence $prec:\n";
  D_RULES and print stringify($match), " <= ", stringify($func), "\n";

  push @{$rules{$prec}}, Grapefruit::Rule->new($match, $func);
}

our $hold;
our $indent=-1; # magic which works!
sub run_rules ($;$) {
  my ($expr, $prec) = @_;

  return $expr if $hold;

  my @levels = sort keys %rules;
  @levels = grep { $_ <= $prec } @levels if defined $prec;
  D_RULES and print "levels: @levels (applying to $expr)\n";

  LEVEL: for my $level (@levels) {
    D_RULES and print "level: $level\n";
    RULE: for my $rule (@{$rules{$level}}) {
      D_RULES and print "  rule: $rule (applied to $expr)\n";
      if (my @captures = $rule->match($expr)) {
	#local $hold = 1; # disabled

	D_RULES and print "    match!\n";
	D_RULES and print "Pre-transform:\n", Dump($expr);
	D_RULES and print "Captures: @captures\n";

	local $indent = $indent + 1;
	D_TRACE and print '  'x$indent, ": ", stringify($expr), "\n";

	$expr = $rule->transform(@captures);

	D_TRACE and print '  'x$indent, "--> ", stringify($expr), "\n";

	D_RULES and print "Post-transform:\n", Dump($expr);

	# now what do we skip to the next precedence level or restart this one?
	# last LEVEL; # terminate early
	# next LEVEL; # skip to the next one
	# redo LEVEL; # redo the current one
	# next RULE; # just continue
	goto LEVEL; # start over
      }
    }
  }
  
  return $expr;
}

sub declare ($) {
  my ($name) = @_;
  no strict 'refs';
  my $pkg = caller;
  my $code = <<"END";
    package $pkg;
    sub $name {
      Grapefruit::run_rules(Grapefruit::Compound->new(q{${pkg}::$name}, \@_));
    }
END
  eval $code;
  croak "Error declaring subroutine: $@" if $@;
}

# this is a multimethod manually implemented
sub stringify {
  return join ", ", map {
    if (blessed $_ and $_->can('stringify')) {
      $_->stringify;
    } elsif (ref $_ eq "ARRAY") { # this is a function application atm
      "($$_[0] ".join(" ", map stringify($_), @$_[1..$#$_]).")";
    } elsif (not defined $_) {
      "undef"
    } else {
      "'$_'"
    }
  } @_;
}

sub unknown () { Grapefruit::Unknown->new }

sub is_num ($) {
  return $_[0] =~ /^\d+$/; # only handles integers, see perlfaq for more REs
}

sub is_atom ($) {
  return 1 if UNIVERSAL::isa($_[0], 'Grapefruit::Unknown');
  return ref $_[0] ? 0 : 1;
}

# bah! It'll work!
sub equiv {
  my ($left, $right) = @_;
  my $rv;
  D_EQUIV and printf "equiv: [%s] [%s]\n", stringify($left), stringify($right);
  if (blessed $left and $left->can('equiv')) {
    $rv = $left->equiv($right);
  } elsif (blessed $right and $right->can('equiv')) {
    $rv = $right->equiv($left);
  } elsif (blessed $left or blessed $right) {
    die "left or right is blessed but doesn't handle equiv ($left,$right)";
  # randomly works, this does!
  } elsif (is_num $left and is_num $right) {
    $rv = $left == $right;
  } else {
    $rv = $left eq $right;
  }
  D_EQUIV and print "    => rv = $rv\n";
  return $rv;
}

1;
__END__

=head1 NAME

Grapefruit - Pattern matching and reduction engine for a perl CAS

=head1 SYNOPSIS

  use Grapefruit;
  print Solve( Equals( 5, Add( 3, x ) ), x );

=head1 DESCRIPTION

Just read the source, the comments try to be amusing. The only existing example
code is in grapefruit.pl.

Grapefruit provides a pattern matching engine which will match against a
parsetree of an expression. The parsetree (and pattern) is generated by small
stub functions which create a Grapefruit::Compound object using their name and
their arguments. They then pass this into the rule based reduction engine. A
reduction engine, in contrast to a production engine where a set of rules are
given for producing all the valid theorems of a system (to mix terminologies
from parsing and Post's symbolic manipulation systems) , such as a Yacc or
Parse::RecDescent grammar, has a set of rules (sorted by precendence in this
implementation) each of which has a predicate, and a replacement parsetree.
When the predicate (being passed a parsetree as its argument) is true, the
parsetree is replaced by the one specified in the replacement. Portions of the
parsetree being matched against can be 'captured' as in normal regular
expressions, and can be substituted into the replacement tree. In Grapefruit,
since parsetrees are generated as the return values of functions, the
replacements are implemented as subroutine references which are called with the
captures are arguments.

The idea is that the core of Grapefruit, the reduction engine, will stay very
general and applicable to any application and that the ability to have
different sets of rules will be aided by having a Grapefruit::Ruleset object.
This means that since it's dependent on multimethods, namespace hell will
avoided by being able to say $ruleset->import, to import all the symbols from
your chosen ruleset or package (%pkg::RULES).

Another important part is the original aim of developing a computer algebra
system in perl (and using perl, note the difference). There's two goals here,
one is to create a cmdline application like yacas or maxima (and optionally a
gui via TeXmacs or similar), and the other is to enable algebra in a normal
perl program.

Here's some dream code from the distant future:

  use Grapefruit::Algebra; # basic algebra rules and operators
  use Grapefruit::Calculus::Differential; # the differential calculus, this is mainly here for fun
  use Grapefruit::Algorithm::NewtonRaphson; # this includes the above
  # they all export their rulesets by default; ie they have @ISA=qw(Grapefruit::Ruleset);

  sub f {
    my $x = shift;
    return 5*$x**5+4*$x**4+5; # any takers for solving this by hand?
  }

  print Newton(\&f, 4); # this differentiates it for us!

Ok that wasn't very enlightening code, and all those imports weren't needed but
it should serve as a goal to achieve.

=head1 BUGS

Now I'm using objects with overloaded operators I've got a nice problem with
complex numbers.  Because evaluation is no longer delayed we tend to end up
with 'NaN'.  I can't simply use Math::Complex because it doesn't play well with
Math::BigFloat which is a potential problem for this module.  I anticipate that
I'll solve this in one of three ways: write my own complex implementation
(which plays nicely with the whole system; turn all numbers into
Grapefruit::Atoms possibly using constant overloading; write some code which
detects which modules the user is using and adapt.  None of this seems much
fun.  The second idea currently sounds the most feasible.

=head1 AUTHOR

Benjamin Smith <bsmith@cpan.org>, usually available as integral on the
freenode irc network

=cut
