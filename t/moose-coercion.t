=pod

=encoding utf-8

=head1 PURPOSE

Check coercions work with L<Moose>; both mutable and immutable classes.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moose 2.0000 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { Moose => 2.0000 };
use Test::Fatal;

my @warnings;

{
	package Local::Class;
	
	use Moose;
	use BiggerLib -all;
	
	::isa_ok(BigInteger, "Moose::Meta::TypeConstraint");
	
	has small  => (is => "rw", isa => SmallInteger, coerce => 1);
	has big    => (is => "rw", isa => BigInteger, coerce => 1);
	
	local $SIG{__WARN__} = sub { push @warnings, \@_ };
	has big_nc => (is => "rw", isa => BigInteger->no_coercions, coerce => 1);
}

like(
	$warnings[0][0],
	qr{^You cannot coerce an attribute .?big_nc.? unless its type .?\w+.? has a coercion},
	"no_coercions and friends available on Moose type constraint objects",
);

my ($e, $o);

my $suffix = "mutable class";
for (0..1)
{
	$e = exception {
		$o = "Local::Class"->new(
			small => 104,
			big   => 9,
		);
	};
	is($e, undef, "no exception on coercion in constructor - $suffix");
	is($o && $o->big, 19, "'big' attribute coerces in constructor - $suffix");
	is($o && $o->small, 4, "'small' attribute coerces in constructor - $suffix");

	$e = exception {
		$o = "Local::Class"->new(
			small => [],
			big   => {},
		);
	};
	like($e, qr{^Attribute \(big\)}, "'big' attribute throws when it cannot coerce in constructor - $suffix");

	$e = exception {
		$o = "Local::Class"->new(
			small => {},
			big   => [],
		);
	};
	like($e, qr{^Attribute \(small\)}, "'small' attribute throws when it cannot coerce in constructor - $suffix");
	
	$o = "Local::Class"->new;
	$e = exception {
		$o->big([]);
		$o->small([]);
	};
	is($o && $o->big, 100, "'big' attribute coerces in accessor - $suffix");
	is($o && $o->small, 1, "'small' attribute coerces in accessor - $suffix");
	
	$e = exception { $o->big({}) };
	like($e, qr{^Attribute \(big\)}, "'big' attribute throws when it cannot coerce in accessor - $suffix");

	$e = exception { $o->small({}) };
	like($e, qr{^Attribute \(small\)}, "'small' attribute throws when it cannot coerce in accessor - $suffix");
	
	"Local::Class"->meta->make_immutable;
	$suffix = "im$suffix";
}

done_testing;
