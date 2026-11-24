# frozen_string_literal: true

require 'hugging_face_cache'
require 'microphone'
require 'whisper'

# Silero VAD over everything heard so far: where does the first sentence start and end?
class SentenceDetector
  MODEL_REPO = 'ggml-org/whisper-vad'
  MODEL_FILE = 'ggml-silero-v6.2.0.bin'
  SILENCE_MS = 250 # this much silence ends a sentence
  MAX_SPEECH_S = 8.0 # one subtitle line holds about this much speech
  SAMPLES_PER_CENTISECOND = Microphone::RATE / 100 # VAD reports time in hundredths of a second

  attr_reader :from, :to

  def initialize
    @vad = Whisper.vad_load(HuggingFaceCache.path_of(MODEL_REPO, MODEL_FILE))
    @from = 0
    @to = 0
    @count = 0
  end

  def detect(mic)
    Whisper.whisper_vad_detect_speech(@vad, mic.samples, mic.heard)
    segments = Whisper.vad_segments(@vad, SILENCE_MS, MAX_SPEECH_S)
    @count = Whisper.whisper_vad_segments_n_segments(segments)
    if speech?
      @from = (Whisper.whisper_vad_segments_get_segment_t0(segments, 0) * SAMPLES_PER_CENTISECOND).to_i
      to = Whisper.whisper_vad_segments_get_segment_t1(segments, 0) * SAMPLES_PER_CENTISECOND
      @to = [to.to_i, mic.heard].min
    end
    Whisper.whisper_vad_free_segments(segments)
  end

  def speech? = @count.positive?

  # A sentence is over once it ended at least SILENCE_MS ago.
  def sentence_over?(mic) = speech? && mic.heard - @to >= Microphone::RATE * SILENCE_MS / 1000
end
