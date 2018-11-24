#!perl
use rlib 'lib';
use DTest;
use Test::OnlySome;

my $hrOpts = {};

is($TEST_NUMBER_OS, 1, 'Tests start at 1');

os $hrOpts ok(1, 'Test 1');     # This one should run

is($TEST_NUMBER_OS, 2, '$TEST_NUMBER_OS increments to 2');

skip_next $hrOpts;
os $hrOpts ok(0, 'Test 2 - should be skipped');

is($TEST_NUMBER_OS, 3, '$TEST_NUMBER_OS increments to 3');

os $hrOpts ok(1, 'Test 3');     # This one should run

is($TEST_NUMBER_OS, 4, '$TEST_NUMBER_OS increments to 4');

skip_next $hrOpts;
os $hrOpts ok(0, 'Test 4 - should be skipped');

is($TEST_NUMBER_OS, 5, '$TEST_NUMBER_OS increments to 5');

os $hrOpts ok(1, 'Test 5');     # This one should run

is($TEST_NUMBER_OS, 6, '$TEST_NUMBER_OS increments to 6');

$hrOpts->{n} = 2;
skip_next $hrOpts;
os $hrOpts {
    ok(0, 'Test 6');
    ok(0, 'Test 7');
};

is($TEST_NUMBER_OS, 8, '$TEST_NUMBER_OS increments to 8');

ok(1, 'Test 9');

is_deeply($hrOpts, {skip => {2=>true, 4=>true, 6=>true}, n=>2},
    'Options structure is what we set');
is_deeply($TEST_ONLYSOME, {}, '$TEST_ONLYSOME is empty');

done_testing();
