use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Exegete',
    AUTHOR              => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM        => 'lib/Exegete.pm',
    ABSTRACT_FROM       => 'lib/Exegete.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES           => [ qw(script/exeg) ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Term::Shell' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Exegete-*' },
);
