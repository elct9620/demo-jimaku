# frozen_string_literal: true

# A C callback can only call a top-level method.
def on_audio(buffer) = Microphone.current.receive(buffer)

# AudioQueue records into buffers it hands back on a run loop; audio_toolbox.c fills in its structs
# and returns each buffer to the queue once Ruby has read it.
module AudioToolbox
  ffi_cflags '-framework AudioToolbox'

  ffi_callback :on_audio, %i[ptr], :void
  ffi_func :audio_queue_open, %i[on_audio double], :ptr
  ffi_func :audio_queue_add_buffer, %i[ptr uint32], :void
  ffi_func :audio_queue_buffer_copy, %i[ptr ptr], :uint32
  ffi_func :AudioQueueStart, %i[ptr ptr], :int
end

module CoreFoundation
  ffi_cflags '-framework CoreFoundation'

  ffi_func :run_until_interrupted, [], :void
end

# What the microphone has heard so far, as contiguous 32-bit floats whisper can read.
class Microphone
  RATE = 16_000
  SAMPLE_BYTES = 4
  KEPT_SECONDS = 60
  QUEUED_BUFFERS = 40 # together they hold 2 seconds, longer than a transcription blocks the run loop
  BUFFER_BYTES = RATE / 20 * SAMPLE_BYTES # 50 milliseconds of audio

  class << self
    attr_accessor :current
  end

  attr_reader :heard, :samples

  def initialize
    @samples = IO::Buffer.new(RATE * KEPT_SECONDS * SAMPLE_BYTES)
    @heard = 0
  end

  def listen(&on_heard)
    Microphone.current = self
    @on_heard = on_heard
    start_queue
    CoreFoundation.run_until_interrupted
  end

  def between(from, to) = @samples.slice(from * SAMPLE_BYTES, (to - from) * SAMPLE_BYTES)

  def forget(count)
    @samples.copy(@samples, 0, (@heard - count) * SAMPLE_BYTES, count * SAMPLE_BYTES)
    @heard -= count
  end

  def receive(buffer)
    room = between(@heard, @heard + (BUFFER_BYTES / SAMPLE_BYTES))
    @heard += AudioToolbox.audio_queue_buffer_copy(buffer, room) / SAMPLE_BYTES
    @on_heard.call
  end

  private

  def start_queue
    queue = AudioToolbox.audio_queue_open(method(:on_audio), RATE.to_f)
    QUEUED_BUFFERS.times { AudioToolbox.audio_queue_add_buffer(queue, BUFFER_BYTES) }
    AudioToolbox.AudioQueueStart(queue, nil)
  end
end
