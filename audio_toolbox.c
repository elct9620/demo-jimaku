/* AudioQueue speaks in structs, out-parameters and a six-argument callback; these hand Ruby a queue and each
   filled buffer, and put the buffer back once Ruby has read it. */
#include <AudioToolbox/AudioToolbox.h>
#include <string.h>

static void (*on_buffer)(AudioQueueBufferRef);

static void on_input(void *user, AudioQueueRef queue, AudioQueueBufferRef buffer, const AudioTimeStamp *time,
                     UInt32 packets, const AudioStreamPacketDescription *descriptions) {
  on_buffer(buffer);
  AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
}

/* Mono 32-bit float, delivered on the current run loop so the callback can be plain Ruby. */
void *audio_queue_open(void (*on_audio)(AudioQueueBufferRef), double rate) {
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
  on_buffer = on_audio;
  AudioQueueNewInput(&format, on_input, NULL, CFRunLoopGetCurrent(), NULL, 0, &queue);
  return queue;
}

void audio_queue_add_buffer(void *queue, uint32_t bytes) {
  AudioQueueBufferRef buffer = NULL;
  AudioQueueAllocateBuffer(queue, bytes, &buffer);
  AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
}

uint32_t audio_queue_buffer_copy(AudioQueueBufferRef buffer, void *dest) {
  memcpy(dest, buffer->mAudioData, buffer->mAudioDataByteSize);
  return buffer->mAudioDataByteSize;
}
