use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nick::Audio::FLAC',
    VERSION_FROM        => 'lib/Nick/Audio/FLAC.pm',
    AUTHOR              => 'Nick Peskett',
    LIBS                => [ '-lFLAC' ]
);
