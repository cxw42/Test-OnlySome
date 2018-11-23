package Test::OnlySome;

use 5.012;
use strict;
use warnings;
use Keyword::Declare;
#use Carp;

# Docs {{{1
=head1 NAME

Test::OnlySome - Skip individual tests in a *.t file

=head1 SYNOPSIS

TODO

    use Test::OnlySome;

=head1 EXPORT

=cut

# }}}1

# Importer, and keyword definitions {{{1

=head2 import

The C<import> sub defines the keywords so that they will be exported.

=cut

sub import {

# `os` keyword - mark each test-calling statement this way {{{2

=head2 os

Keyword C<os> marks a statement that should be excuted C<O>nly C<S>ome of
the time.

=cut

    # TODO
    # - Permit lexical state
    # - Permit skipping more than one test in $controlled

    keyword os(String? $debug_var, Block|Statement $controlled) {
        if(defined $debug_var) {
            no strict 'refs';
            $debug_var =~ s/^['"]|['"]$//g;   # $debug_var comes with quotes
            ${$debug_var} = $controlled;
            #print STDERR "# Stashed $controlled into `$debug_var`\n";
            #print STDERR Carp::ret_backtrace(); #join "\n", caller(0);
        }
        return $controlled;     # for now, no changes
    } # os() }}}2

} # import()
# }}}1

# More docs {{{1
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

# }}}1

our $VERSION = '0.000_001';

=head1 VERSION

Version 0.0.1

# License {{{1

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

# }}}1
1;

# vi: set fdm=marker: #
