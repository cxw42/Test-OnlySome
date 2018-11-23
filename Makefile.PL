use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;

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
        'rlib' => '0',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Data::Dumper' => '0',
        'Keyword::Declare'  => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-OnlySome-*' },
);
