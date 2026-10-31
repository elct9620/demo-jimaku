# frozen_string_literal: true

# Offline live captions: microphone -> Silero VAD -> Breeze ASR -> a subtitle bar.
require 'microphone'
require 'sentence_detector'
require 'subtitle_bar'
require 'transcriber'

TAIL = Microphone::RATE / 2 # kept during silence, so the next word keeps its onset

transcriber = Transcriber.new
detector = SentenceDetector.new
bar = SubtitleBar.new
mic = Microphone.new

mic.listen do
  next if mic.heard < TAIL

  detector.detect(mic)
  if detector.sentence_over?(mic)
    text = transcriber.text_of(mic.between(detector.from, detector.to))
    bar.show(text)
    puts text
    mic.forget(detector.to)
  elsif !detector.speech?
    mic.forget(mic.heard - TAIL)
  end
end
