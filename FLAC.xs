#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <FLAC/stream_decoder.h>
#include <math.h>

#define PCM_MAX_VALUE 32767

typedef FLAC__StreamDecoder decoder_t;

struct nickaudioflac {
    decoder_t *decoder;
    SV *scalar_out;
    FLAC__uint64 total_samples;
    FLAC__uint64 read_samples;
    unsigned int sample_rate;
    unsigned char channels;
    float gain;
    unsigned int buffer_samples;
    void *pcm_out;
};

typedef struct nickaudioflac NICKAUDIOFLAC;

void meta_callback(
    const decoder_t *decoder,
    const FLAC__StreamMetadata *metadata,
    void *client_data
) {
    NICKAUDIOFLAC *THIS = (NICKAUDIOFLAC *)client_data;
    if (
        metadata -> type == FLAC__METADATA_TYPE_STREAMINFO
    ) {
        unsigned bps = metadata -> data.stream_info.bits_per_sample;
        if ( bps != 16 ) {
            croak( "Only 16 bits per sample supported (not %d).", bps );
        }
        THIS -> total_samples = metadata -> data.stream_info.total_samples;
        THIS -> sample_rate = metadata -> data.stream_info.sample_rate;
        if ( THIS -> channels == 0 ) {
            THIS -> channels = metadata -> data.stream_info.channels;
        }
    }
}

static FLAC__StreamDecoderWriteStatus write_callback(
    const decoder_t *decoder,
    const FLAC__Frame *frame,
    const FLAC__int32 * const buffer[],
    void *client_data
) {
    NICKAUDIOFLAC *THIS = ( NICKAUDIOFLAC * )client_data;
    unsigned int i;
    const unsigned samples = frame -> header.blocksize;
    unsigned char *u_pcm = THIS -> pcm_out;
    signed char *s_pcm = THIS -> pcm_out + 1;
    FLAC__int32 sample;
    if ( THIS -> gain != 1 ) {
        int c;
        FLAC__int32 *s_ptr;
        for ( c = 0; c < frame -> header.channels; c ++ ) {
            s_ptr = ( FLAC__int32* )buffer[c];
            for ( i = 0; i < samples; i ++ ) {
                sample = *s_ptr * THIS -> gain;
                if (
                    sample > PCM_MAX_VALUE
                ) {
                    sample = PCM_MAX_VALUE;
                } else if (
                    sample < -PCM_MAX_VALUE
                ) {
                    sample = -PCM_MAX_VALUE;
                }
                s_ptr[0] = sample;
                s_ptr ++;
            }
        }
    }
    if ( frame -> header.channels == 1 ) {
        const FLAC__int32 *s_ptr;
        s_ptr = buffer[0];
        if ( THIS -> channels == 2 ) {
            for ( i = 0; i < samples; i ++ ) {
                sample = *s_ptr ++;
                u_pcm[0] = sample & 0xff;
                s_pcm[0] = ( sample >> 8 ) & 0xff;
                u_pcm += 2;
                s_pcm += 2;
                u_pcm[0] = sample & 0xff;
                s_pcm[0] = ( sample >> 8 ) & 0xff;
                u_pcm += 2;
                s_pcm += 2;
            }
        } else {
            for ( i = 0; i < samples; i ++ ) {
                sample = *s_ptr ++;
                u_pcm[0] = sample & 0xff;
                s_pcm[0] = ( sample >> 8 ) & 0xff;
                u_pcm += 2;
                s_pcm += 2;
            }
        }
    } else {
        const FLAC__int32 *l_ptr, *r_ptr;
        l_ptr = buffer[0];
        r_ptr = buffer[1];
        for ( i = 0; i < samples; i ++ ) {
            sample = *l_ptr ++;
            u_pcm[0] = sample & 0xff;
            s_pcm[0] = ( sample >> 8 ) & 0xff;
            u_pcm += 2;
            s_pcm += 2;
            sample = *r_ptr ++;
            u_pcm[0] = sample & 0xff;
            s_pcm[0] = ( sample >> 8 ) & 0xff;
            u_pcm += 2;
            s_pcm += 2;
        }
    }
    THIS -> buffer_samples = samples;
    return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

static void error_callback(
    const decoder_t *decoder,
    FLAC__StreamDecoderErrorStatus status,
    void *client_data
) {
    warn( "FLAC decoder error_callback: %d\n", status );
}

MODULE = Nick::Audio::FLAC  PACKAGE = Nick::Audio::FLAC

PROTOTYPES: DISABLE

static NICKAUDIOFLAC *
NICKAUDIOFLAC::new_xs( filename, scalar_out, channels, gain )
        const char *filename;
        SV *scalar_out;
        unsigned char channels;
        float gain;
    CODE:
        Newxz( RETVAL, 1, NICKAUDIOFLAC );
        RETVAL -> decoder = FLAC__stream_decoder_new();
        if ( RETVAL -> decoder == NULL ) {
            croak( "Problem allocating FLAC decoder." );
        }
        FLAC__stream_decoder_set_md5_checking(
            RETVAL -> decoder, false
        );
        if (
            FLAC__stream_decoder_init_file(
                RETVAL -> decoder,
                filename,
                write_callback,
                meta_callback,
                error_callback,
                RETVAL
            ) != FLAC__STREAM_DECODER_INIT_STATUS_OK
        ) {
            croak( "Problem allocating FLAC decoder." );
        }
        RETVAL -> channels = channels;
        FLAC__stream_decoder_process_until_end_of_metadata(
            RETVAL -> decoder
        );
        Newx(
            RETVAL -> pcm_out,
            FLAC__MAX_BLOCK_SIZE * 2 * RETVAL -> channels,
            void
        );
        RETVAL -> scalar_out = SvREFCNT_inc(
            SvROK( scalar_out )
            ? SvRV( scalar_out )
            : scalar_out
        );
        RETVAL -> read_samples = 0;
        RETVAL -> gain = pow( 10, gain / 20 );
    OUTPUT:
        RETVAL

void
NICKAUDIOFLAC::DESTROY()
    CODE:
        FLAC__stream_decoder_finish( THIS -> decoder );
        FLAC__stream_decoder_delete( THIS -> decoder );
        SvREFCNT_dec( THIS -> scalar_out );
        Safefree( THIS -> pcm_out );
        Safefree( THIS );

HV *
NICKAUDIOFLAC::details()
    CODE:
        RETVAL = newHV();
        sv_2mortal( (SV*)RETVAL );
        hv_store(
            RETVAL, "sample_rate", 11,
            newSViv( THIS -> sample_rate ),
            0
        );
        hv_store(
            RETVAL, "channels", 8,
            newSViv( THIS -> channels ),
            0
        );
        hv_store(
            RETVAL, "bits_sample", 11,
            newSViv( 16 ),
            0
        );
    OUTPUT:
        RETVAL

unsigned int
NICKAUDIOFLAC::get_sample_rate()
    CODE:
        RETVAL = THIS -> sample_rate;
    OUTPUT:
        RETVAL

unsigned char
NICKAUDIOFLAC::get_channels()
    CODE:
        RETVAL = THIS -> channels;
    OUTPUT:
        RETVAL

FLAC__uint64
NICKAUDIOFLAC::get_total_samples()
    CODE:
        RETVAL = THIS -> total_samples;
    OUTPUT:
        RETVAL

float
NICKAUDIOFLAC::get_total_secs()
    CODE:
        RETVAL = THIS -> total_samples / ( float )THIS -> sample_rate;
    OUTPUT:
        RETVAL

bool
NICKAUDIOFLAC::set_position_to_sample( sample )
        FLAC__uint64 sample;
    CODE:
        RETVAL = (bool)FLAC__stream_decoder_seek_absolute(
            THIS -> decoder, sample
        );
        if ( RETVAL ) {
            THIS -> read_samples = sample;
        }
    OUTPUT:
        RETVAL

FLAC__uint64
NICKAUDIOFLAC::get_position_as_sample()
    CODE:
        RETVAL = THIS -> read_samples;
    OUTPUT:
        RETVAL

bool
NICKAUDIOFLAC::set_position_to_secs( secs )
        float secs;
    CODE:
        FLAC__uint64 sample = secs * THIS -> sample_rate;
        RETVAL = (bool)FLAC__stream_decoder_seek_absolute(
            THIS -> decoder, sample
        );
        if ( RETVAL ) {
            THIS -> read_samples = sample;
        }
    OUTPUT:
        RETVAL

float
NICKAUDIOFLAC::get_position_in_secs()
    CODE:
        RETVAL = THIS -> read_samples / ( float )THIS -> sample_rate;
    OUTPUT:
        RETVAL

U32
NICKAUDIOFLAC::read()
    INIT:
        if (
            FLAC__stream_decoder_get_state( THIS -> decoder )
            == FLAC__STREAM_DECODER_END_OF_STREAM
        ) {
            XSRETURN_UNDEF;
        }
        THIS -> buffer_samples = 0;
    CODE:
        if (
            ! FLAC__stream_decoder_process_single( THIS -> decoder )
        ) {
            croak( "FLAC read error while processing frame." );
        }
        THIS -> read_samples += THIS -> buffer_samples;
        RETVAL = THIS -> buffer_samples * THIS -> channels * 2;
        sv_setpvn( THIS -> scalar_out, THIS -> pcm_out, RETVAL );
    OUTPUT:
        RETVAL
