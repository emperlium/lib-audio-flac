# lib-audio-flac

Interface to the libflac (Free Lossless Audio Codec decoding) library.

## Dependencies

You'll need the [libflac library](https://xiph.org/flac/).

On Ubuntu distributions;

    sudo apt install libflac-dev

## Installation

    perl Makefile.PL
    make test
    sudo make install

## Example

    use Nick::Audio::FLAC;

    my $buff_out;
    my $flac = Nick::Audio::FLAC -> new(
        'test.flac',
        'gain' => -3,
        'buffer_out' => \$buff_out
    );

    use FileHandle;
    my $sox = FileHandle -> new( sprintf
            '| sox -q -t raw -b 16 -e s -r %d -c %d - -t pulseaudio',
            $flac -> get_sample_rate(),
            $flac -> get_channels()
    ) or die $!;
    binmode $sox;

    while (
        $flac -> read()
    ) {
        $sox -> print( $buff_out );
    }
