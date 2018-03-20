use strict;
use warnings;

use Test::More tests => 13;

use Digest::MD5 'md5_base64';

BEGIN {
    use_ok( 'Nick::Audio::FLAC' );
};

my @want_md5 = qw(
    m9zcmzluATsRziGlyWQgMg
    TxxfJFtW/7T1b4cU5eyL7g
    RaggHIQ4zsACGwAsh2f0RA
    YxH900FSDl0ePG7KIUrVnw
    hgHZctjwpEKV9PZZx8nKRg
    E+3Wj6Q9KqRqKKugxwMFzw
);

my( $buff_out );
my $flac = Nick::Audio::FLAC -> new(
    'test.flac',
    'buffer_out'    => \$buff_out,
    'gain'          => -3
);

ok( defined( $flac ), 'new()' );

is_deeply(
    $flac -> details(), {qw(
        sample_rate 44100
        bits_sample 16
        channels    1
    )}, 'details'
);

is(
    $flac -> get_sample_rate(),
    44100,
    'get_sample_rate()'
);

is(
    $flac -> get_channels(),
    1,
    'get_channels()'
);

is(
    $flac -> get_total_samples(),
    22050,
    'get_total_samples()'
);

is(
    $flac -> get_total_secs(),
    .5,
    'get_total_secs()'
);

my @got_md5;
while (
    $flac -> read()
) {
    push @got_md5 => md5_base64( $buff_out );
}
is_deeply( \@got_md5, \@want_md5, 'read()' );

ok(
    $flac -> set_position_to_sample( 11025 ),
    'set_position_to_sample()'
);

is(
    $flac -> get_position_as_sample(),
    11025,
    'get_position_as_sample()'
);

is(
    $flac -> get_position_in_secs(),
    .25,
    'get_total_secs()'
);

ok(
    $flac -> set_position_to_secs( .1 ),
    'set_position_to_secs()'
);

is(
    $flac -> get_position_as_sample(),
    4410,
    'get_position_as_sample()'
);

