#!perl
# 43-plugin-output.t: Test the App::Prove plugin.
# Runs t/allkinds.test with prove -PTest::OnlySomeP.

package t43;

use rlib 'lib';
use DTest;
use App::Prove;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];

my $results_fn = localpath '43.out';
unlink $results_fn if -e $results_fn;

my $test_fn = localpath("allkinds.test");   # the test file to run

# Run prove().  TODO: Swallow stdout and stderr while this is running, so
# that the intentional failures in t/allkinds.test don't confuse the output.
my $app = App::Prove->new;
$app->process_args(
    qw(-Q --norc --state=all),   # Isolate us from the environment
    '-PTest::OnlySomeP=filename,' . $results_fn,
    $test_fn
);
$app->run;

ok(-e $results_fn, "Output file exists");

my $results = LoadFile $results_fn;

ok(ref $results eq 'HASH', "Result file is valid YAML");

ok($results->{$test_fn}, "Result file has an entry for $test_fn");

# TODO test the content of $results

done_testing();
