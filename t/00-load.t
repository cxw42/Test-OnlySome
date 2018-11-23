#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::OnlySome' ) || print "Bail out!\n";
}

diag( "Testing Test::OnlySome $Test::OnlySome::VERSION, Perl $], $^X" );
