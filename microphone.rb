# frozen_string_literal: true

# What the microphone has heard so far, as contiguous 32-bit floats whisper can read.
class Microphone
  # miniaudio's ring buffer, filled by the audio thread in mic.c.
  module MiniAudio
    extend FFI::Library

    attach_function :mic_start,      %i[int int], :ptr
    attach_function :available,      :ma_pcm_rb_available_read, [:ptr], :uint32
    attach_function :acquire,        :ma_pcm_rb_acquire_read,   %i[ptr ptr ptr], :int
    attach_function :commit,         :ma_pcm_rb_commit_read,    %i[ptr uint32], :int
    attach_function :memcpy,         %i[ptr ptr size_t], :ptr

    ffi_buffer    :frames_out, 4
    ffi_buffer    :region_out, 8
    ffi_write_u32 :set_frames, 0
    ffi_read_u32  :get_frames, 0
    ffi_read_ptr  :get_region, 0
  end

  SAMPLE_BYTES = 4
  KEPT_SECONDS = 60
  RING_SECONDS = 10

  attr_reader :heard, :samples

  def initialize(rate)
    @capacity = rate * KEPT_SECONDS
    @samples = IO::Buffer.new(@capacity * SAMPLE_BYTES)
    @heard = 0
    @ring = MiniAudio.mic_start(rate, rate * RING_SECONDS)
  end

  # Moves what the audio thread captured since the last call into our buffer.
  def listen
    while (waiting = [MiniAudio.available(@ring), @capacity - @heard].min).positive?
      MiniAudio.set_frames(MiniAudio.frames_out, waiting)
      MiniAudio.acquire(@ring, MiniAudio.frames_out, MiniAudio.region_out)
      frames = MiniAudio.get_frames(MiniAudio.frames_out)
      region = MiniAudio.get_region(MiniAudio.region_out)
      MiniAudio.memcpy(between(@heard, @heard + frames), region, frames * SAMPLE_BYTES)
      MiniAudio.commit(@ring, frames)
      @heard += frames
    end
  end

  def between(from, to) = @samples.slice(from * SAMPLE_BYTES, (to - from) * SAMPLE_BYTES)

  def forget(count)
    @samples.copy(@samples, 0, (@heard - count) * SAMPLE_BYTES, count * SAMPLE_BYTES)
    @heard -= count
  end
end
