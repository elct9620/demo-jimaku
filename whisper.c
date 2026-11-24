/* whisper.cpp takes these parameter structs by value, which FFI cannot pass. */
#include "vendor/whisper/include/whisper.h"

void *vad_load(const char *path) {
  return whisper_vad_init_from_file_with_params(path, whisper_vad_default_context_params());
}

void *vad_segments(void *vad, int silence_ms, double max_speech_s) {
  struct whisper_vad_params p = whisper_vad_default_params();
  p.min_silence_duration_ms = silence_ms;
  p.max_speech_duration_s = max_speech_s;
  return whisper_vad_segments_from_probs(vad, p);
}

void transcribe(void *whisper, void *samples, int n) {
  struct whisper_full_params p = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  p.language = "zh";
  p.print_progress = false;
  p.single_segment = true;
  whisper_full(whisper, p, samples, n);
}
