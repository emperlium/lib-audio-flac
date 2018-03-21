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

## Methods

### new()

Instantiates a new Nick::Audio::FLAC object.

Takes a filename as the first argument, the following arguments as a hash.

All elements of the hash are optional;

- buffer\_out

    Scalar that'll be used to push decoded PCM to.

- channels

    How many audio channels should be in output (i.e. output mono file to 2 channels).

- gain

    Decibels of gain to apply to the decoded PCM.

### read()

Decodes the next chunk of audio and populates **buffer\_out**.

Returns number of bytes of audio in **buffer\_out**, or **undef** if file has ended.

### details()

Returns a hash with the keys **sample\_rate**, **channels** and **bits\_sample**.

### get\_sample\_rate()

Returns current sample rate.

### get\_channels()

Returns current number of channels being output.

### get\_total\_samples()

Returns total number of samples (not inclusive of channels).

### get\_total\_secs()

Returns length of file in seconds.

### set\_position\_to\_sample( sample )

Takes an integer as argument and moves read position to that sample offset.

Returns true if successful.

### get\_position\_as\_sample()

Returns current sample offset.

### set\_position\_to\_secs( secs )

Takes a float as argument and moves read position to that seconds offset.

Returns true if successful.

### get\_position\_in\_secs()

Returns current seconds offset.
