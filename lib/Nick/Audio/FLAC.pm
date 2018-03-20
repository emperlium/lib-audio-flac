package Nick::Audio::FLAC;
use strict;
use warnings;

use XSLoader;
use Carp;

# sudo apt install libflac-dev

our $VERSION;

BEGIN {
    $VERSION = '0.01';
    XSLoader::load 'Nick::Audio::FLAC' => $VERSION;
}

=pod

=head1 NAME

Nick::Audio::FLAC - Interface to the libflac library.

=head1 SYNOPSIS

Currently only supports 16 bits per sample files.

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

=head1 METHODS

=head2 new()

Instantiates a new Nick::Audio::FLAC object.

Takes a filename as the first argument, the following arguments as a hash.

All elements of the hash are optional;

=over 2

=item buffer_out

Scalar that'll be used to push decoded PCM to.

=item channels

How many audio channels should be in output (i.e. output mono file to 2 channels).

=item gain

Decibels of gain to apply to the decoded PCM.

=back

=head2 read()

Decodes the next chunk of audio and populates B<buffer_out>.

Returns number of bytes of audio in B<buffer_out>, or B<undef> if file has ended.

=head2 details()

Returns a hash with the keys B<sample_rate>, B<channels> and B<bits_sample>.

=head2 get_sample_rate()

Returns current sample rate.

=head2 get_channels()

Returns current number of channels being output.

=head2 get_total_samples()

Returns total number of samples (not inclusive of channels).

=head2 get_total_secs()

Returns length of file in seconds.

=head2 set_position_to_sample( sample )

Takes an integer as argument and moves read position to that sample offset.

Returns true if successful.

=head2 get_position_as_sample()

Returns current sample offset.

=head2 set_position_to_secs( secs )

Takes a float as argument and moves read position to that seconds offset.

Returns true if successful.

=head2 get_position_in_secs()

Returns current seconds offset.

=cut

sub new {
    my( $class, $file, %settings ) = @_;
    -f $file or croak(
        'Missing FLAC file: ' . $file
    );
    exists( $settings{'buffer_out'} )
        or $settings{'buffer_out'} = do{ my $x = '' };
    $settings{'channels'} ||= 0;
    $settings{'gain'} ||= 0;
    return Nick::Audio::FLAC -> new_xs(
        $file, @settings{ qw(
            buffer_out channels gain
        ) }
    );
}

1;
