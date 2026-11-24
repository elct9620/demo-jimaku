# frozen_string_literal: true

# whisper.cpp, for both speech recognition and voice activity detection.
# whisper.c covers the calls that take a struct by value.
module Whisper
  ffi_lib 'c++'
  ffi_lib 'objc'
  ffi_cflags '-Lvendor/whisper/lib -lwhisper -lggml -lggml-metal -lggml-blas -lggml-cpu -lggml-base'
  ffi_cflags '-framework Accelerate -framework Foundation -framework Metal -framework MetalKit'
  # Spin links against an older SDK than whisper.cpp was built with; ggml guards this class with @available.
  ffi_cflags "-Wl,-U,'_OBJC_CLASS_$_MTLResidencySetDescriptor'"

  ffi_callback :logger, %i[int ptr ptr], :void
  ffi_func :whisper_log_set, %i[logger ptr], :void
  ffi_func :whisper_init_from_file, [:str], :ptr
  ffi_func :transcribe, %i[ptr ptr int], :void
  ffi_func :whisper_full_n_segments, [:ptr], :int
  ffi_func :whisper_full_get_segment_text, %i[ptr int], :str

  ffi_func :vad_load, [:str], :ptr
  ffi_func :whisper_vad_detect_speech, %i[ptr ptr int], :bool
  ffi_func :vad_segments, %i[ptr int double], :ptr
  ffi_func :whisper_vad_segments_n_segments, [:ptr], :int
  ffi_func :whisper_vad_segments_get_segment_t0, %i[ptr int], :float
  ffi_func :whisper_vad_segments_get_segment_t1, %i[ptr int], :float
  ffi_func :whisper_vad_free_segments, [:ptr], :void
end
