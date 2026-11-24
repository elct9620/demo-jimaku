# frozen_string_literal: true

require 'hugging_face_cache'
require 'microphone'
require 'whisper'

# Replaces whisper.cpp's logging so the terminal shows only captions.
def silent_log(_level, _text, _data); end

# Breeze ASR through whisper.cpp: audio in, one line of text out.
class Transcriber
  MODEL_REPO = 'tsuzuri-app/Breeze-ASR-25-ggml'
  MODEL_FILE = 'ggml-breeze-asr-25-q5_0.bin'

  def initialize
    Whisper.whisper_log_set(method(:silent_log), nil)
    @whisper = Whisper.whisper_init_from_file(HuggingFaceCache.path_of(MODEL_REPO, MODEL_FILE))
  end

  def text_of(audio)
    Whisper.transcribe(@whisper, audio, audio.size / Microphone::SAMPLE_BYTES)
    return '' if Whisper.whisper_full_n_segments(@whisper).zero?

    Whisper.whisper_full_get_segment_text(@whisper, 0).strip
  end
end
