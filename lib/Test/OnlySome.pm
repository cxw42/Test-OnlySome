package Test::OnlySome;
use 5.012;
use strict;
use warnings;
use Keyword::Declare;
use Data::Dumper;   # DEBUG
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

use vars;
use Import::Into;

use constant { true => !!1, false => !!0 };

use parent 'Exporter';
our @EXPORT = qw( skip_these skip_next );

# TODO move $TEST_NUMBER_OS into the options structure.

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

You can pick which tests to skip using implicit or explicit configuration.
Explicit configuration uses a hashref:

    my $opts = { skip => { 2=>true } };

    os $opts ok(1, 'This will run');    # Single statement OK

    os $opts {                          # Block also OK
        ok(0, 'This will be skipped');  # Skipped since it's test 2
    };

Implicit configuration uses a hashref in the package variable C<$TEST_ONLYSOME>,
which Test::OnlySome creates in your package when you C<use> it:

    $TEST_ONLYSOME->{skip} = { 2=>true };
    os ok(1, 'Test 1');                     # This one runs
    os ok(0, 'Test 2 - should be skipped'); # Skipped since it's test 2

=cut

# }}}3

# Caller-facing routines {{{1

=head1 EXPORTS

=head2 skip_these

A convenience function to fill in C<< $hashref_options->{skip} >>.

    skip_these $hashref_options, 1, 2;
        # Skip tests 1 and 2
    skip_these 1, 2;
        # If you are using implicit configuration

=cut

sub skip_these {
    my $hrOpts = _opts($_[0]);
    shift if $_[0] && $hrOpts == $_[0];
    croak 'Need an options hash reference' unless ref $hrOpts eq 'HASH';
    $hrOpts->{skip}->{$_} = true foreach(@_);
} #skip_these()

=head2 skip_next

Another convenience function: Mark the next test to be skipped.  Example:

    skip_next;
    os ok(0, 'This one will be skipped');

=cut

sub skip_next {
    my $hrOpts = _opts($_[0]);
    shift if $_[0] && $hrOpts == $_[0];
    croak 'Need an options hash reference' unless ref $hrOpts eq 'HASH';
    $hrOpts->{skip}->{_nexttestnum()} = true;
} #skip_next()

# }}}1
# Importer, and keyword definitions {{{1

=head2 import

The C<import> sub defines the keywords so that they will be exported (!).
This is per L<Keyword::Declare>.

=cut

sub import {
    my $self = shift;
    my $target = caller;
    my $level = 1;

    #print STDERR "$self import into $target\n";
    #_printtrace();

    # Special-case imports from Test::Kit, since Test::Kit doesn't know how
    # to copy the custom keyword from its fake package to the ultimate caller.
    if($target =~ m{^Test::Kit::Fake::(.*)::\Q$self\E$}) {
        ($target, $level) = _escapekit($1);
        #print STDERR "$self real target = $target at level $level\n";
        $self->import::into($target);   # Import into the real target
        return;     # *** EXIT POINT ***
    }

    # Sanity check - e.g., `perl -MTest::OnlySome -E `os ok(1);` will die
    # because skip() isn't defined.  However, we don't require Test::More
    # because there might be other packages that you are using that provide
    # skip().
    {
        no strict 'refs';
        croak "Test::OnlySome: skip() not defined - I can't function!  (Missing `use Test::More`?)"
            unless (defined &{ $target . '::skip'}); # || $INC{'Test/More.pm'};
    }

    # Copy symbols listed in @EXPORT first.  Ignore @_, which we are
    # going to use for our own purposes.
    $self->export_to_level($level);

    # Create the variables we need in the target package
    vars->import::into($target, qw($TEST_NUMBER_OS $TEST_ONLYSOME));

    # Initialize the variables unless they already have been
    my $hrTOS;
    {
        no strict 'refs';
        ${ $target . '::TEST_NUMBER_OS' } = 1       # tests start at 1, not 0
            unless ${ $target . '::TEST_NUMBER_OS' };
        ${ $target . '::TEST_ONLYSOME' } = {}
            unless 'HASH' eq ref ${ $target . '::TEST_ONLYSOME' };
        $hrTOS = ${ $target . '::TEST_ONLYSOME' };
    };

    # Check the arguments.  Numeric arguments are tests to skip.
    foreach(@_) {
        $hrTOS->{skip}->{$_} = true
            if(!ref && looks_like_number $_);
    }

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

        # At this point, caller() is in Keyword::Declare.
        #my $target = caller(2);     # Skip past Keyword::Declare's code.
        #                            # TODO make this more robust.

        if(defined $debug_var) {
            no strict 'refs';
            $debug_var =~ s/^['"]|['"]$//g;   # $debug_var comes with quotes
            ${$debug_var} = {opts_var_name => $opts_name, code => $controlled};
            #print STDERR "# Stashed $controlled into `$debug_var`\n";
            #print STDERR Carp::ret_backtrace(); #join "\n", caller(0);
        }

        # Get the options
        #my $hrOptsName = $opts_name || ('$' . $target . '::TEST_ONLYSOME');
        my $hrOptsName = $opts_name || '$TEST_ONLYSOME';

#        print STDERR "os: Options in $hrOptsName\n";
#        _printtrace();

        croak "Need options as a scalar variable - got $hrOptsName"
            unless defined $hrOptsName && substr($hrOptsName, 0, 1) eq '$';

        return _gen($hrOptsName, $controlled);
    } # os() }}}2

} # import()

=head2 unimport

Removes the L</os> keyword definition.

=cut

sub unimport {
    unkeyword os;
}

# }}}1
# Implementation of keywords (macro), and internal helpers {{{1

=head1 INTERNALS

=head2 _escapekit

Find the caller using a Test::Kit package that uses us, so we can import
the keyword the right place.

=cut

sub _escapekit {
# Find the real target package, in case we were called from Test::Kit
    my $kit = shift;
    #print STDERR "Invoked from Test::Kit module $kit\n";

    my $level;

    #       0         1          2      3            4
    my ($callpkg, $filename, $line, $subroutine, $hasargs,
    #    5          6          7            8       9         10
    $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);

    # Find the caller of $kit, and import directly there.
    for($level=0; 1; ++$level) {
        #       0         1          2      3            4
        ($callpkg, $filename, $line, $subroutine, $hasargs,
        #    5          6          7            8       9         10
        $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)
        = caller($level);
        last unless $callpkg;
        last if $callpkg eq $kit;
    } #for levels

    if($callpkg && ($callpkg eq $kit)) {
        ++$level;
        $callpkg = caller($level);
        return ($callpkg, $level) if $callpkg;
    }

    die "Could not find the module that invoked Test::Kit module $kit";
} #_escapekit()

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
        {
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

=head2 _opts

Returns the appropriate options hashref.  Call as C<_opts($_[0])>.

=cut

sub _opts {
    my $target = caller(1) or croak 'Could not find caller';
    my $arg = shift;

#    print STDERR "_opts: Options in ", (ref $arg eq 'HASH' ?
#        'provided hashref' : "\$${target}::TEST_ONLYSOME\n");
#    _printtrace();

    return $arg if ref $arg eq 'HASH';

    # Implicit config: find the caller's package and get $TEST_ONLYSOME
    return do { no strict 'refs'; ${ "$target" . '::TEST_ONLYSOME' } };

} #_opts()

=head2 _nexttestnum

Gets the caller's current C<$TEST_NUMBER_OS> value.

=cut

sub _nexttestnum {
    my $target = caller(1) or croak 'Could not find caller';
    return do { no strict 'refs'; ${ "$target" . '::TEST_NUMBER_OS' } };
} #_nexttestnum()

=head2 _printtrace

Print a full stack trace

=cut

sub _printtrace {
    # Print full stack trace
    my @callers;
    for(my $i=0; 1; ++$i) {
        ##       0         1          2      3            4
        #my ($package, $filename, $line, $subroutine, $hasargs,
        ##    5          6          7            8       9         10
        #$wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)
        #= caller($i);
        push @callers, [caller($i)];
        last unless $callers[-1]->[0];
    }
    print Dumper(\@callers), "\n";
}

# }}}1

# More docs, and $VERSION {{{3
=head1 VARIABLES

=head2 C<$TEST_NUMBER_OS>

Exported into the caller's package.  A sequential numbering of tests that
have been run under L</os>.

=head2 C<$TEST_ONLYSOME> (Options hashref)

Exported into the caller's package.  A hashref of options, of the same format
as an explicit-config hashref.  Keys are:

=over

=item * C<n>

The number of tests in each L</os> call.

=item * C<skip>

A hashref of tests to skip.  Test numbers are keys; any truthy
value will indicate that the L</os> call beginning with that test number
should be skipped.

=back

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

our $VERSION = '0.000_004';

=head1 VERSION

Version 0.0.4 (dev)

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
