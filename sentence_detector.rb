# frozen_string_literal: true

require 'microphone'

# Silero VAD over everything heard so far: where does the first sentence start and end?
class SentenceDetector
  # whisper.cpp voice activity detection.
  module Vad
    extend FFI::Library

    attach_function :load_model,    :vad_load, [:str], :ptr
    attach_function :detect,        :whisper_vad_detect_speech, %i[ptr ptr int], :bool
    attach_function :segments,      :vad_segments, %i[ptr int double], :ptr
    attach_function :segment_count, :whisper_vad_segments_n_segments,     [:ptr], :int
    attach_function :start_at,      :whisper_vad_segments_get_segment_t0, %i[ptr int], :float
    attach_function :end_at,        :whisper_vad_segments_get_segment_t1, %i[ptr int], :float
    attach_function :free,          :whisper_vad_free_segments, [:ptr], :void
  end

  MODEL = 'vendor/models/ggml-silero-v6.2.0.bin'
  SILENCE_MS = 250 # this much silence ends a sentence
  MAX_SPEECH_S = 8.0 # one subtitle line holds about this much speech
  SAMPLES_PER_CENTISECOND = Microphone::RATE / 100 # VAD reports time in hundredths of a second

  attr_reader :from, :to

  def initialize
    @vad = Vad.load_model(MODEL)
    @from = 0
    @to = 0
    @count = 0
  end

  def detect(mic)
    Vad.detect(@vad, mic.samples, mic.heard)
    segments = Vad.segments(@vad, SILENCE_MS, MAX_SPEECH_S)
    @count = Vad.segment_count(segments)
    if speech?
      @from = (Vad.start_at(segments, 0) * SAMPLES_PER_CENTISECOND).to_i
      @to = [(Vad.end_at(segments, 0) * SAMPLES_PER_CENTISECOND).to_i, mic.heard].min
    end
    Vad.free(segments)
  end

  def speech? = @count.positive?

  # A sentence is over once it ended at least SILENCE_MS ago.
  def sentence_over?(mic) = speech? && mic.heard - @to >= Microphone::RATE * SILENCE_MS / 1000
end
