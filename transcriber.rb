# frozen_string_literal: true

# Replaces whisper.cpp's logging so the terminal shows only captions.
def silent_log(_level, _text, _data); end

# Breeze ASR through whisper.cpp: audio in, one line of text out.
class Transcriber
  # whisper.cpp speech recognition. speech.c covers the calls that take a struct by value.
  module Whisper
    extend FFI::Library

    ffi_lib 'c++'
    ffi_lib 'objc'
    ffi_cflags '-Lvendor/whisper/lib -lwhisper -lggml -lggml-metal -lggml-blas -lggml-cpu -lggml-base'
    ffi_cflags '-framework Accelerate -framework Foundation -framework Metal -framework MetalKit'
    # Spin links against an older SDK than whisper.cpp was built with; ggml guards this class with @available.
    ffi_cflags "-Wl,-U,'_OBJC_CLASS_$_MTLResidencySetDescriptor'"

    ffi_callback :logger, %i[int ptr ptr], :void
    ffi_func :whisper_log_set, %i[logger ptr], :void
    attach_function :load_model, :whisper_init_from_file, [:str], :ptr
    attach_function :transcribe, %i[ptr ptr int], :void
    attach_function :count,      :whisper_full_n_segments,       [:ptr], :int
    attach_function :text_at,    :whisper_full_get_segment_text, %i[ptr int], :str
  end

  SAMPLE_BYTES = 4

  def initialize(model)
    Whisper.whisper_log_set(method(:silent_log), nil)
    @whisper = Whisper.load_model(model)
  end

  def text_of(audio)
    Whisper.transcribe(@whisper, audio, audio.size / SAMPLE_BYTES)
    Whisper.count(@whisper).zero? ? '' : Whisper.text_at(@whisper, 0).strip
  end
end
