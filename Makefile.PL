use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nick::Audio::FLAC',
    VERSION_FROM        => 'lib/Nick/Audio/FLAC.pm',
    AUTHOR              => 'Nick Peskett',
    LIBS                => [ '-lFLAC' ],
    TEST_REQUIRES       => {
        'Test::More' => 0,
        'Digest::MD5' => 0
    }
);
