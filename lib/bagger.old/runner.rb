# encoding: UTF-8
module Bagger
  class Runner

    def initialize(options)
      @options = options
      @manifest_name = 'manifest.json'
      @css_source_files = @options[:stylesheets]
    end

    def manifest_path
      File.join(@options[:source_dir], @manifest_name)
    end

    def run
      target_path =
      File.open(manifest_path, 'w') do |f|
        f.puts 'jah a'
      end
    end
  end
end
