# frozen_string_literal: true

# Offline live captions: microphone -> Silero VAD -> Breeze ASR -> a subtitle bar.
require_relative 'microphone'
require_relative 'sentence_detector'
require_relative 'subtitle_bar'
require_relative 'transcriber'

class Jimaku
  HF_HUB = "#{Dir.home}/.cache/huggingface/hub".freeze
  BREEZE = 'models--tsuzuri-app--Breeze-ASR-25-ggml/snapshots/d8ec322b4a34e92c380e4186d4e0f238eebe7ba7'
  SILERO = 'models--ggml-org--whisper-vad/snapshots/9ffd54a1e1ee413ddf265af9913beaf518d1639b'

  RATE = 16_000
  TICK = 0.2 # seconds between checks
  TAIL = RATE / 2 # kept during silence, so the next word keeps its onset

  def initialize
    @transcriber = Transcriber.new("#{HF_HUB}/#{BREEZE}/ggml-breeze-asr-25-q5_0.bin")
    @detector = SentenceDetector.new("#{HF_HUB}/#{SILERO}/ggml-silero-v6.2.0.bin", RATE)
    @bar = SubtitleBar.new
    @mic = Microphone.new(RATE)
  end

  def run
    loop do
      @bar.pump
      sleep TICK
      @mic.listen
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
