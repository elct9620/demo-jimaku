# frozen_string_literal: true

# Installs what the demo links and loads; `spin run` does the rest.
WHISPER_VERSION = 'v1.9.4' # the version the Breeze model was converted with
WHISPER_SRC = 'vendor/whisper.cpp'
WHISPER_DIR = File.expand_path('vendor/whisper')
MINIAUDIO_VERSION = '0.11.26'
MINIAUDIO_HEADER = 'vendor/miniaudio/miniaudio.h'

MODELS = {
  'tsuzuri-app/Breeze-ASR-25-ggml' => 'ggml-breeze-asr-25-q5_0.bin',
  'ggml-org/whisper-vad' => 'ggml-silero-v6.2.0.bin'
}.freeze

desc 'Install whisper.cpp and miniaudio into vendor/, and fetch the models'
task default: ["#{WHISPER_DIR}/lib/libwhisper.a", MINIAUDIO_HEADER, :models]

file MINIAUDIO_HEADER do
  mkdir_p File.dirname(MINIAUDIO_HEADER)
  sh "curl -fsSL -o #{MINIAUDIO_HEADER} https://raw.githubusercontent.com/mackron/miniaudio/#{MINIAUDIO_VERSION}/miniaudio.h"
end

file WHISPER_SRC do
  sh "git clone --depth 1 --branch #{WHISPER_VERSION} https://github.com/ggml-org/whisper.cpp.git #{WHISPER_SRC}"
end

file "#{WHISPER_DIR}/lib/libwhisper.a" => WHISPER_SRC do
  sh "cmake -S #{WHISPER_SRC} -B #{WHISPER_SRC}/build -DCMAKE_BUILD_TYPE=Release " \
     "-DCMAKE_INSTALL_PREFIX=#{WHISPER_DIR} -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF " \
     '-DWHISPER_BUILD_EXAMPLES=OFF -DWHISPER_BUILD_TESTS=OFF -DGGML_METAL_EMBED_LIBRARY=ON'
  sh "cmake --build #{WHISPER_SRC}/build -j"
  sh "cmake --install #{WHISPER_SRC}/build"
end

desc 'Fetch the models into the Hugging Face cache'
task :models do
  MODELS.each { |repo, file| sh "hf download #{repo} #{file}" }
end
