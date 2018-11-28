#!perl
package Test::OnlySome::RerunFailed;
use 5.012;
use strict;
use warnings;

use Carp qw(croak);
use Import::Into;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];

#use Data::Dumper;

use constant FILENAME => '.onlysome.yml';   # TODO make this a parameter

sub import {
    my ($target, $filename) = caller;
    #print STDERR "Called from $filename\n";
    # TODO read the YAML file
    my $fn = _localpath(1, FILENAME, 1);
    #print STDERR "Reading YAML from $fn\n";
    my $hrCfg = LoadFile($fn);
    #print STDERR Dumper($hrCfg);

    # TODO pick the numbers to skip
    my @skips;
    @skips = @{ $hrCfg->{$filename}->{passed} } if $hrCfg->{$filename}->{passed};
    #print STDERR "Skipping ", join(", ", @skips), "\n";
    # Load Test::OnlySome with the appropriate skips
    'Test::OnlySome'->import::into($target, @skips ? 'skip' : (), @skips);
}

sub _localpath { # Return the path to a file in the same directory as the caller {{{2
    my $calleridx = shift or croak 'Need a caller index';
    my $newfn = shift or croak 'Need a filename';
    my $moveup = shift;

    my ($package, $filename) = caller($calleridx);

    $filename = 'dummy' unless $filename && $filename ne '-e';
        # Dummy filename assumed to be in cwd, if we're running from -e
        # or are otherwise without a caller.

    $filename = File::Spec->rel2abs($filename);
        # Assume the code up to this point hasn't changed cwd

    #print STDERR "abs: $filename\n";
    my ($vol, $dir, $file) = File::Spec->splitpath($filename);
    $dir = File::Spec->catdir($dir);
        # Trim trailing slash , if any

    if($moveup) {
        my @dirs = File::Spec->splitdir($dir);
        #print STDERR "Dirs before: ", join "\n", @dirs, "\n";
        pop @dirs while $moveup--;
        #print STDERR "Dirs after ", join "\n", @dirs, "\n";
        $dir = File::Spec->catdir(@dirs);
    }

    return File::Spec->catpath($vol, $dir, $newfn)
} #}}}2

1;

# vi: set fdm=marker fdl=1:
