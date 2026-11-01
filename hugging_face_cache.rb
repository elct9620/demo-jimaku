# frozen_string_literal: true

# Finds the models that `rake models` downloaded with `hf`.
module HuggingFaceCache
  HUB = "#{Dir.home}/.cache/huggingface/hub".freeze

  def self.path_of(repo, file)
    path = Dir.glob("#{HUB}/models--#{repo.sub('/', '--')}/snapshots/*/#{file}").first
    abort "Cannot find #{file} in the Hugging Face cache. Run `rake models` first." unless path
    path
  end
end
