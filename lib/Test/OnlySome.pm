package Test::OnlySome;

use 5.012;
use strict;
use warnings;
use Keyword::Declare;
use Data::Dumper;
use Carp qw(croak);

use constant { true => !!1, false => !!0 };

use parent 'Exporter';
our @EXPORT = qw( $TEST_NUMBER_OS $TEST_ONLYSOME skip_these skip_next );

# Docs {{{3

=head1 NAME

Test::OnlySome - Skip individual tests in a *.t file

=head1 INSTALLATION

Easiest: install C<cpanminus> if you don't have it - see
L<https://metacpan.org/pod/App::cpanminus#INSTALLATION>.  Then run
C<cpanm Test::OnlySome>.

Manually: clone or untar into a working directory.  Then, in that directory,

    perl Makefile.PL
    make
    make test

... and if all the tests pass,

    make install

If some of the tests fail, please check the issues and file a new one if
no one else has reported the problem yet.

=head1 USAGE

    use Test::More;
    use Test::OnlySome;

    my $opts = { skip => { 2=>true } };

    os $opts ok(1, 'This will run');    # Single statement OK

    os $opts {                          # Block also OK
        ok(0, 'This will be skipped');  # Skipped since it's test 2
    };

=cut

# }}}3

# Caller-facing routines {{{1

=head1 EXPORTS

=head2 skip_these

A convenience function to fill in C<< $hashref_options->{skip} >>.

    skip_these $hashref_options, 1, 2;
        # Skip tests 1 and 2

=cut

sub skip_these {
    my $hrOpts = shift;
    croak 'Need an options hash reference' unless ref $hrOpts eq 'HASH';
    $hrOpts->{skip}->{$_} = true foreach(@_);
} #skip_these()

=head2 skip_next

Another convenience function: Mark the next test to be skipped.

=cut

sub skip_next {
    my $hrOpts = shift;
    croak 'Need an options hash reference' unless ref $hrOpts eq 'HASH';

    my $target = caller or croak("Couldn't find caller");

    my $next_test;
    {
        no strict 'refs';
        $next_test = ${ "${target}::TEST_NUMBER_OS" } or
            croak "Couldn't get \$TEST_NUMBER_OS from $target";
    };

    $hrOpts->{skip}->{$next_test} = true;
} #skip_next()

# }}}1
# Importer, and keyword definitions {{{1

=head2 import

The C<import> sub defines the keywords so that they will be exported (!).
This is per L<Keyword::Declare>.

=cut

sub import {
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    Test::OnlySome->export_to_level(1, @_);

    do {
        no strict 'refs';
        ${ "$target" . '::TEST_NUMBER_OS' } = 1;    # tests start at 1, not 0
        ${ "$target" . '::TEST_ONLYSOME' } = {};
    };

# `os` keyword - mark each test-calling statement this way {{{2

=head2 os

Keyword C<os> marks a statement that should be excuted B<o>nly B<s>ome of
the time.  Example:

    os 'main::debug' $hrOpts  ok 1,'Something';
        # Run "ok 1,'Something'" if hashref $hrOpts indicates.
        # Save debug information into $main::debug.

Syntax:

    os ['debug::variable::name'] $hashref_options <statement | block>

C<$debug::variable::name> will be assigned at compilation time.
C<$hashref_options> will be accessed at runtime.

CAUTION: The given statement or block will be run in its own lexical scope,
not in the caller's scope.

=cut

    keyword os(String? $debug_var, Var? $opts_name, Block|Statement $controlled) {
        my $target = caller(2);     # Skip past Keyword

#        # Print full stack trace
#        my @callers;
#        for(my $i=0; 1; ++$i) {
#            ##       0         1          2      3            4
#            #my ($package, $filename, $line, $subroutine, $hasargs,
#            ##    5          6          7            8       9         10
#            #$wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)
#            #= caller($i);
#            push @callers, [caller($i)];
#            last unless $callers[-1]->[0];
#        }
#        print Dumper(\@callers, "\n");

        if(defined $debug_var) {
            no strict 'refs';
            $debug_var =~ s/^['"]|['"]$//g;   # $debug_var comes with quotes
            ${$debug_var} = {opts_var_name => $opts_name, code => $controlled};
            #print STDERR "# Stashed $controlled into `$debug_var`\n";
            #print STDERR Carp::ret_backtrace(); #join "\n", caller(0);
        }

        # Get the options
        my $hrOptsName = $opts_name || ('$' . $target . '::TEST_ONLYSOME');

        croak "Need options as a scalar variable holding a hashref - got $hrOptsName"
            unless defined $hrOptsName && substr($hrOptsName, 0, 1) eq '$';

        # print STDERR "Options in $opts\n";
        return _gen($hrOptsName, $controlled);
    } # os() }}}2

} # import()
# }}}1
# Implementation of keywords (macro) {{{1

=head1 INTERNALS

=head2 _gen

This routine generates source code that, at runtime, will execute a given
only-some test.

=cut

sub _gen {
    my $optsVarName = shift or croak 'Need an options-var name';
    my $code = shift or croak 'Need code';

    # Syntactic parts, so I don't have to disambiguate interpolation in the
    # qq{} below from hash access in the generated code.  Instead of
    # $foo->{bar}, interpolations below use $foo$W$L bar $R.
    my $W = '->';
    my $L = '{';
    my $R = '}';

    my $replacement = qq{
        do {
            my \$ntests = $optsVarName$W$L n $R // 1;   # TODO move this to a separate parm of os()
            my \$first_test_num = \$TEST_NUMBER_OS;
            \$TEST_NUMBER_OS += \$ntests;
            SKIP: {
                # print STDERR " ==> Trying test \$first_test_num\\n"; # DEBUG
                skip 'Test::OnlySome: you asked me to skip these', \$ntests
                    if $optsVarName$W$L skip $R$W$L \$first_test_num $R;
                $code
            }
        };
    };

    #print STDERR "$replacement\n"; # DEBUG
    return $replacement;

} #_gen()

# }}}1

# More docs {{{3
=head1 VARIABLES

=head2 C<$TEST_NUMBER_OS>

Exported into the caller's package.  A sequential numbering of tests that
have been run under L</os>.

=head1 AUTHOR

Christopher White, C<< <cxwembedded at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests on GitHub, at
L<https://github.com/cxw42/Test-OnlySome/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::OnlySome

You can also look for information at:

=over 4

=item * The GitHub repository

L<https://github.com/cxw42/Test-OnlySome>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-OnlySome>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Test-OnlySome>

=item * Search CPAN

L<https://metacpan.org/release/Test-OnlySome>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-OnlySome>

=back

=cut

# }}}3

our $VERSION = '0.000_002';

=head1 VERSION

Version 0.0.2-dev

=cut

# License {{{3

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Christopher White.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# }}}3
1;

# vi: set fdm=marker fdl=2: #
