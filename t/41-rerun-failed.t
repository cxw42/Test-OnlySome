#!perl
# 41-rerun-failed.t: Test::OnlySome::RerunFailed
package t41;

use rlib 'lib';
use DTest;
use Nested::DImportInto;

use Test::OnlySome::RerunFailed;

os ok(0,'Test 1');
os ok(0,'Test 2');
os ok(0,'Test 3');
os ok(0,'Test 4');

done_testing();
