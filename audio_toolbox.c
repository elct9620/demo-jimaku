/* AudioQueue speaks in structs and out-parameters; these hand Ruby a queue, a buffer and a byte count. */
#include <AudioToolbox/AudioToolbox.h>
#include <string.h>

/* Mono 32-bit float, delivered on the current run loop so the callback can be plain Ruby. */
void *audio_queue_open(AudioQueueInputCallback on_audio, double rate) {
  AudioStreamBasicDescription format = {
    .mSampleRate = rate,
    .mFormatID = kAudioFormatLinearPCM,
    .mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
    .mBytesPerPacket = sizeof(float),
    .mFramesPerPacket = 1,
    .mBytesPerFrame = sizeof(float),
    .mChannelsPerFrame = 1,
    .mBitsPerChannel = sizeof(float) * 8,
  };
  AudioQueueRef queue = NULL;
  AudioQueueNewInput(&format, on_audio, NULL, CFRunLoopGetCurrent(), NULL, 0, &queue);
  return queue;
}

void *audio_queue_new_buffer(void *queue, uint32_t bytes) {
  AudioQueueBufferRef buffer = NULL;
  AudioQueueAllocateBuffer(queue, bytes, &buffer);
  return buffer;
}

uint32_t audio_queue_buffer_copy(AudioQueueBufferRef buffer, void *dest) {
  memcpy(dest, buffer->mAudioData, buffer->mAudioDataByteSize);
  return buffer->mAudioDataByteSize;
}
