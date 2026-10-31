# frozen_string_literal: true

# Offline live captions: microphone -> Silero VAD -> Breeze ASR -> a subtitle bar.
require 'microphone'
require 'sentence_detector'
require 'subtitle_bar'
require 'transcriber'

TAIL = Microphone::RATE / 2 # kept during silence, so the next word keeps its onset

TRANSCRIBER = Transcriber.new
DETECTOR = SentenceDetector.new
BAR = SubtitleBar.new
MIC = Microphone.new

# AudioQueue can only call a top-level method.
def on_audio(_user, queue, buffer, _time, _packets, _descriptions) # rubocop:disable Metrics/ParameterLists
  MIC.receive(queue, buffer)
  caption_finished_sentence if MIC.heard >= TAIL
end

def caption_finished_sentence
  DETECTOR.detect(MIC)
  if DETECTOR.sentence_over?(MIC)
    show_caption
  elsif !DETECTOR.speech?
    MIC.forget(MIC.heard - TAIL)
  end
end

def show_caption
  text = TRANSCRIBER.text_of(MIC.between(DETECTOR.from, DETECTOR.to))
  BAR.show(text)
  puts text
  MIC.forget(DETECTOR.to)
end

MIC.listen
