#!perl
package t01;

use rlib 'lib';
use DTest;
use Test::OnlySome;

plan tests => 2;

# Vars to hold the debug output from os(), since os() processing happens
# at compile time, and the stack trace doesn't point us here.
our ($t1, $t2);

os 't01::t1' my $x;
is($t01::t1, 'my $x;', 'os() grabs a statement');

os 't01::t2' {my $x; my $y;};
is($t01::t2, '{my $x; my $y;}', 'os() grabs a block');

