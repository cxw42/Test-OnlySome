#!perl
use rlib 'lib';
use DTest;
use Test::OnlySome;

$TEST_ONLYSOME->{skip} = { 2=>true, 3=>true, 6=>true, 7=>true, 8=>true };

is($TEST_NUMBER_OS, 1, 'Tests start at 1');

os ok(1, 'Test 1');     # This one should run

is($TEST_NUMBER_OS, 2, '$TEST_NUMBER_OS increments to 2');

$TEST_ONLYSOME->{n} = 2;
os {
    ok(0, 'Test 2 - should be skipped');
    ok(0, 'Test 3 - should be skipped');
}

is($TEST_NUMBER_OS, 4, '$TEST_NUMBER_OS increments to 4');

os {
    ok(1, 'Test 4');
    ok(1, 'Test 5');
}

is($TEST_NUMBER_OS, 6, '$TEST_NUMBER_OS increments to 6');

$TEST_ONLYSOME->{n} = 3;
os {
    ok(0, 'Test 6 - should be skipped');
    ok(0, 'Test 7 - should be skipped');
    ok(0, 'Test 8 - should be skipped');
}

is($TEST_NUMBER_OS, 9, '$TEST_NUMBER_OS increments to 9');

$TEST_ONLYSOME->{n} = 1;
os ok(1, 'Test 9');     # This one should run

is($TEST_NUMBER_OS, 10, '$TEST_NUMBER_OS increments to 10');

done_testing();
