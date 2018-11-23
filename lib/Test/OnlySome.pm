package Test::OnlySome;

use 5.012;
use strict;
use warnings;
use Keyword::Declare;
#use Data::Dumper;
use Carp qw(croak);

use parent 'Exporter';
our @EXPORT = qw( $TEST_NUMBER_OS );

# Docs {{{3
=head1 NAME

Test::OnlySome - Skip individual tests in a *.t file

=head1 SYNOPSIS

TODO

    use Test::OnlySome;

=head1 INTERNALS

=cut

# }}}3

# Implementation of keywords (macro) {{{1

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
# Importer, and keyword definitions {{{1

=head1 EXPORTS

=head2 import

The C<import> sub defines the keywords so that they will be exported.

=cut

sub import {
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    Test::OnlySome->export_to_level(1, @_);

    do {
        no strict 'refs';
        ${ "$target" . '::TEST_NUMBER_OS' } = 1;    # tests start at 1, not 0
    };

# `os` keyword - mark each test-calling statement this way {{{2

=head2 os

Keyword C<os> marks a statement that should be excuted B<o>nly B<o>ome of
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

    keyword os(String? $debug_var, Var $opts, Block|Statement $controlled) {
        if(defined $debug_var) {
            no strict 'refs';
            $debug_var =~ s/^['"]|['"]$//g;   # $debug_var comes with quotes
            ${$debug_var} = {opts_var_name => $opts, code => $controlled};
            #print STDERR "# Stashed $controlled into `$debug_var`\n";
            #print STDERR Carp::ret_backtrace(); #join "\n", caller(0);
        }

        croak "Need options as a scalar variable holding a hashref"
            unless defined $opts && substr($opts, 0, 1) eq '$';

        # print STDERR "Options in $opts\n";
        return _gen($opts, $controlled);
    } # os() }}}2

} # import()
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

our $VERSION = '0.000_001';

=head1 VERSION

Version 0.0.1

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
