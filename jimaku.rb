# frozen_string_literal: true

# Offline live captions: microphone -> Silero VAD -> Breeze ASR -> a subtitle bar.
require_relative 'microphone'
require_relative 'sentence_detector'
require_relative 'subtitle_bar'
require_relative 'transcriber'

class Jimaku
  # The main thread's run loop does all the waiting: it delivers audio and redraws the window.
  module RunLoop
    extend FFI::Library

    ffi_cflags '-framework CoreFoundation'

    attach_function :run_in_mode, :CFRunLoopRunInMode, %i[ptr double long], :int
    attach_function :cfstring, :CFStringCreateWithCString, %i[ptr str uint32], :ptr
  end

  BREEZE = 'vendor/models/ggml-breeze-asr-25-q5_0.bin'
  SILERO = 'vendor/models/ggml-silero-v6.2.0.bin'
  UTF8 = 0x08000100

  RATE = 16_000
  TICK = 0.05 # seconds between checks
  TAIL = RATE / 2 # kept during silence, so the next word keeps its onset

  def initialize
    @transcriber = Transcriber.new(BREEZE)
    @detector = SentenceDetector.new(SILERO, RATE)
    @bar = SubtitleBar.new
    @mic = Microphone.new(RATE)
    @mode = RunLoop.cfstring(nil, 'kCFRunLoopDefaultMode', UTF8)
  end

  def run
    loop do
      RunLoop.run_in_mode(@mode, TICK, 0)
      tick if @mic.heard >= TAIL
    end
  end

  private

  def tick
    @detector.detect(@mic)
    if @detector.sentence_over?(@mic)
      caption
    elsif !@detector.speech?
      @mic.forget(@mic.heard - TAIL)
    end
  end

  def caption
    text = @transcriber.text_of(@mic.between(@detector.from, @detector.to))
    @bar.show(text)
    puts text
    @mic.forget(@detector.to)
  end
end
