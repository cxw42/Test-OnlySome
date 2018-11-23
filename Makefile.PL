use 5.006;
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
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-OnlySome-*' },
);
