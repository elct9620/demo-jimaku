# frozen_string_literal: true

# AudioQueue can only call a top-level method.
def on_audio(_user, queue, buffer, _time, _packets, _descriptions) # rubocop:disable Metrics/ParameterLists
  Microphone.current.receive(queue, buffer)
end

# What the microphone has heard so far, as contiguous 32-bit floats whisper can read.
class Microphone
  # macOS calls back on the run loop we name, so the audio callback can be plain Ruby.
  module AudioQueue
    extend FFI::Library

    ffi_cflags '-framework AudioToolbox -framework CoreFoundation'

    ffi_callback :on_audio, %i[ptr ptr ptr ptr uint32 ptr], :void
    ffi_func :AudioQueueNewInput, %i[ptr on_audio ptr ptr ptr uint32 ptr], :int
    attach_function :allocate, :AudioQueueAllocateBuffer, %i[ptr uint32 ptr], :int
    attach_function :enqueue,  :AudioQueueEnqueueBuffer,  %i[ptr ptr uint32 ptr], :int
    attach_function :start,    :AudioQueueStart,          %i[ptr ptr], :int
    attach_function :current_run_loop, :CFRunLoopGetCurrent, [], :ptr
    attach_function :memcpy, %i[ptr ptr size_t], :ptr

    ffi_buffer   :out, 8
    ffi_read_ptr :out_pointer, 0
    ffi_read_ptr :audio_data, 8
    ffi_read_u32 :audio_size, 16
  end

  SAMPLE_BYTES = 4
  KEPT_SECONDS = 60
  QUEUED_BUFFERS = 40 # together they hold 2 seconds, longer than a transcription blocks the run loop
  BUFFER_SECONDS = 0.05
  LINEAR_PCM = 0x6C70636D
  PACKED_FLOAT = 9

  class << self
    attr_accessor :current
  end

  attr_reader :heard, :samples

  def initialize(rate)
    Microphone.current = self
    @samples = IO::Buffer.new(rate * KEPT_SECONDS * SAMPLE_BYTES)
    @heard = 0
    start_queue(rate)
  end

  def between(from, to) = @samples.slice(from * SAMPLE_BYTES, (to - from) * SAMPLE_BYTES)

  def forget(count)
    @samples.copy(@samples, 0, (@heard - count) * SAMPLE_BYTES, count * SAMPLE_BYTES)
    @heard -= count
  end

  def receive(queue, buffer)
    frames = AudioQueue.audio_size(buffer) / SAMPLE_BYTES
    AudioQueue.memcpy(between(@heard, @heard + frames), AudioQueue.audio_data(buffer), frames * SAMPLE_BYTES)
    @heard += frames
    AudioQueue.enqueue(queue, buffer, 0, nil)
  end

  private

  def start_queue(rate) # rubocop:disable Metrics/AbcSize
    run_loop = AudioQueue.current_run_loop
    AudioQueue.AudioQueueNewInput(format(rate), method(:on_audio), nil, run_loop, nil, 0, AudioQueue.out)
    queue = AudioQueue.out_pointer(AudioQueue.out)
    QUEUED_BUFFERS.times do
      AudioQueue.allocate(queue, (rate * BUFFER_SECONDS).to_i * SAMPLE_BYTES, AudioQueue.out)
      AudioQueue.enqueue(queue, AudioQueue.out_pointer(AudioQueue.out), 0, nil)
    end
    AudioQueue.start(queue, nil)
  end

  # AudioStreamBasicDescription: mono 32-bit float at the given rate.
  def format(rate)
    description = IO::Buffer.new(40)
    description.set_value(:f64, 0, rate.to_f)
    [LINEAR_PCM, PACKED_FLOAT, SAMPLE_BYTES, 1, SAMPLE_BYTES, 1, SAMPLE_BYTES * 8, 0].each_with_index do |field, i|
      description.set_value(:u32, 8 + (i * SAMPLE_BYTES), field)
    end
    description
  end
end
