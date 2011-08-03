# encoding: UTF-8
require 'json'
require 'digest/md5'

module Bagger
  class Packager

    def initialize(options)
      @options = options
      @manifest_name = 'manifest.json'
      @stylesheets = (@options[:combine] || {})[:stylesheets] || []
      @javascripts = (@options[:combine] || {})[:javascripts] || []
      @source_dir = @options[:source_dir]
      @target_dir = @options[:target_dir]
      @stylesheet_path = (@options[:combine] || {})[:stylesheet_path] || 'combined.css'
      @javascript_path = (@options[:combine] || {})[:javascript_path] || 'combined.js'
    end

    def manifest_path
      File.join(@options[:source_dir], @manifest_name)
    end

    def run
      target_path =
      File.open(manifest_path, 'w') do |f|
        f.puts 'jah a'
      end
      combine_css
      combine_js
    end

    def combine_css
      combine_files(@stylesheets, @stylesheet_path)
    end

    def combine_js
      combine_files(@javascripts, @javascript_path)
    end

    private

    def combine_files(files, path)
      output = ''
      FileUtils.mkdir_p(File.join(@target_dir, File.dirname(path)))
      target_path = File.join(@target_dir, path)
      files.each do |file|
        output << File.open(File.join(@source_dir, file)) { |f| f.read }
        output << "\n"
      end
      File.open(target_path, "w") { |f| f.write(output) }
    end
  end
end
