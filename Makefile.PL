use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    return $secure_perl_path;
} # get_perl_filename() }}}1

my $secure_perl_path = get_perl_filename();

# Set up Makefile to generate README.md {{{1
{   package MY;

    # dist_core: make `dist` a :: target rather than a : target.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\s*:[^:]/dist:: /m;
        return $text;
    } # MY::dist_core

    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)
        return <<EOT;
authortest:
\tRELEASE_TESTING=1 prove -l xt

testhere:   # Run the tests from lib rather than blib
\tprove -lv

README.md: lib/Test/OnlySome.pm
\tpod2markdown \$< > \$@

all :: README.md
dist :: README.md

EOT

    } #postamble()
} #package MY }}}1

WriteMakefile(
    NAME             => 'Test::OnlySome',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION_FROM     => 'lib/Test/OnlySome.pm',
    ABSTRACT_FROM    => 'lib/Test/OnlySome.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.012',    # required by Keyword::Declare
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Carp' => '0',
        'Exporter' => '0',
        'Import::Into' => '0',
        'parent' => '0',
        'Pod::Markdown' => '0',
        'rlib' => '0',
        'Test::More' => '0',
    },
    TEST_REQUIRES => {
        'Test::Kit' => '0',
    },
    PREREQ_PM => {
        'Data::Dumper' => '0',
        'Keyword::Declare'  => '0.001006',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-OnlySome-*' },
);

# vi: set fdm=marker fdl=0: #
