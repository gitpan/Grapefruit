package Grapefruit;

use 5.006;
use strict;
use warnings;

# Constants

sub D_PATTERN () { 0 }
sub D_RULES () { 0 }
sub D_EQUIV () { 0 }
sub D_TRACE () { 0 }

# Preamble

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw( declare rule unknown stringify
                  capture is_num pattern equiv
		  is_atom
		);
for (0..9) { push @EXPORT, "_$_" } # all the shortened capture sequences

our $VERSION = '0.00103'; # increment _after_ each distribution

use Carp;
use YAML;
use Scalar::Util qw( blessed );

# Code below

our @captures;

{ # quick'n'dirty wrapper
  package Grapefruit::Rule;
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
}

{ # quick'n'dirty wrapper
  package Grapefruit::Compound;
  use Carp;
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
}

{ # quick'n'dirty wrapper
  package Grapefruit::Pattern;
  BEGIN { *D_PATTERN = *Grapefruit::D_PATTERN };
  sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my ($patterntree, $predicate) = @_;

    my $self = sub {
      my ($parsetree) = @_;
      local @captures = ();
      D_PATTERN and print "* Patterntree: $patterntree\n";
      D_PATTERN and print "* Parsetree: $parsetree\n";

      # recursivly process the two trees in parallel
      my $success = Grapefruit::_do_match($patterntree, $parsetree);

      # check the predicate
      if (defined $predicate) {
        $success &&= $predicate->(@captures);
      }
    
      D_PATTERN and print "* Captures: @captures\n";
      D_PATTERN and print "* Success: $success\n";
    
      if ($success) {
        return wantarray ? @captures : 1;
      } else {
        return wantarray ? () : 0;
      }
    };

    return bless $self, $class;
  }
}

sub capture ($;$) {
  my ($num, $matcher) = @_;
  my $closure;
  if ($matcher) {
    $closure = sub {
      my ($parsetree) = @_; # take the parsetree
      if ($matcher->($parsetree)) { # if it matches the pattern
	$captures[$num] = $parsetree; # save it
	return 1;
      } else {
	return 0;
      }
    };
  } else {
    $closure = sub {
      my ($parsetree) = @_; # take the parsetree
      $captures[$num] = $parsetree; # save it
      return 1; # we matched
    };
  }
  return bless $closure, 'pattern::capture';
}
sub _0 (;$) { &capture(0, @_) }
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
  } elsif (ref $patterntree eq "pattern::capture") {
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

  push @{$rules{$prec}}, Grapefruit::Rule->new($match, $func);
}

our $hold;
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

	D_TRACE and print ": ", stringify($expr), "\n";

	$expr = $rule->transform(@captures);

	D_TRACE and print "  --> ", stringify($expr), "\n";

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
      Grapefruit::run_rules(Grapefruit::Compound->new(q{$name}, \@_));
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
    } else {
      "'$_'"
    }
  } @_;
}

sub unknown () { bless [undef], 'symbolic::unknown' }

sub is_num ($) {
  return $_[0] =~ /^\d+$/; # only handles integers, see perlfaq for more REs
}

sub is_atom ($) {
  return 1 if UNIVERSAL::isa($_[0], 'symbolic::unknown');
  return ref $_[0] ? 0 : 1;
}

# bah! It'll work!
sub equiv {
  my ($left, $right) = @_;
  D_EQUIV and printf "equiv: [%s] [%s]\n", stringify($left), stringify($right);
  if (blessed $left and $left->can('equiv')) {
    return $left->equiv($right);
  } elsif (blessed $right and $right->can('equiv')) {
    return $right->equiv($left);
  } elsif (is_num $left and is_num $right) {
    return $left == $right;
  } else {
    return $left eq $right;
  }
}

1;
__END__

=head1 NAME

Grapefruit - Pattern matching and reduction engine for a perl CAS

=head1 SYNOPSIS

  use Grapefruit;
  print Solve( Equals( 5, Add( 3, x ) ) );

=head1 DESCRIPTION

Just read the source, the comments try to be amusing.

Blah blah blah.

=head1 AUTHOR

Benjamin Smith <bsmith@cpan.org>, usually available as integral on the
freenode irc network

=cut
