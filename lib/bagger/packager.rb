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
      @manifest = {}
    end

    def to_manifest(path, keep_original = true)
      content = File.open(File.join(@target_dir, path)) { |f| f.read }
      extension = File.extname(path)
      basename = File.basename(path, extension)
      dirname = File.dirname(path)
      FileUtils.mkdir_p(File.join(@target_dir, dirname))
      md5 = Digest::MD5.hexdigest(content)
      new_file_name = "#{basename}.#{md5}#{extension}"
      new_file_path = File.join(@target_dir, dirname, new_file_name)
      File.open(new_file_path, 'w') { |f| f.write content }
      FileUtils.rm(File.join(@target_dir, path)) unless keep_original
      manifest_key_path = File.expand_path("/#{dirname}/#{basename}#{extension}")
      effective_path = File.expand_path("/" + File.join(dirname, new_file_name))
      @manifest[manifest_key_path] = effective_path
    end

    def manifest_path
      File.join(@options[:source_dir], @manifest_name)
    end

    def run
      combine_css
      combine_js
      version_files
      to_manifest(@stylesheet_path, false)
      to_manifest(@javascript_path, false)
      write_manifest
    end

    def write_manifest
      File.open(manifest_path, 'w') do |f|
        f.write JSON.pretty_generate(@manifest)
      end
    end

    def version_files
      FileUtils.cd(@source_dir) do
        Dir["**/*"].reject{ |f| f =~ /\.(css|js)$/ }.each do |path|
          next if File.directory? path
          FileUtils.cp(path, File.join(@target_dir, path))
          to_manifest(path, false)
        end
      end
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
