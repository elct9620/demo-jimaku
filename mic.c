/* The audio thread cannot enter Ruby, and miniaudio's device config is returned by value. */
#define MINIAUDIO_IMPLEMENTATION
#include "vendor/miniaudio/miniaudio.h"

static ma_pcm_rb ring;
static ma_device device;

static void on_audio(ma_device *d, void *out, const void *in, ma_uint32 frames) {
  const float *from = in;
  while (frames > 0) {
    ma_uint32 n = frames;
    void *to;
    ma_pcm_rb_acquire_write(&ring, &n, &to);
    if (n == 0) return;
    memcpy(to, from, n * sizeof(float));
    ma_pcm_rb_commit_write(&ring, n);
    from += n;
    frames -= n;
  }
}

void *mic_start(int rate, int ring_frames) {
  ma_pcm_rb_init(ma_format_f32, 1, ring_frames, NULL, NULL, &ring);
  ma_device_config c = ma_device_config_init(ma_device_type_capture);
  c.capture.format = ma_format_f32;
  c.capture.channels = 1;
  c.sampleRate = rate;
  c.dataCallback = on_audio;
  ma_device_init(NULL, &c, &device);
  ma_device_start(&device);
  return &ring;
}
