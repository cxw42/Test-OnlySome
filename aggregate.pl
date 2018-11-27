#!perl
# Modified from https://github.com/Perl-Toolchain-Gang/Test-Harness/blob/b3f5f0d73efa5114537fbd489843d2e674457fb4/examples/silent-harness.pl
#
# Run some tests and get back a data structure describing them.

use strict;
use warnings;
use TAP::Harness;
use Data::Dumper;

my @tests = glob 't/*.t';

my $harness = TAP::Harness->new( { verbosity => -9, lib => ['lib'] } );

# $aggregate is a TAP::Parser::Aggregator
my $aggregate = $harness->runtests(@tests);
print Dumper($aggregate);
