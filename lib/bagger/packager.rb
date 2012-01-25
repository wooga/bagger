# encoding: UTF-8
require 'json'
require 'digest/md5'
require 'addressable/uri'
require 'uglifier'
require 'rainpress'
require 'zlib'

module Bagger
  class Packager

    def initialize(options)
      @options = options
      @source_dir = @options[:source_dir]
      @target_dir = @options[:target_dir]
      @manifest_path = @options[:manifest_path] || File.join(@source_dir, 'manifest.json')
      @cache_manifest_path = @options[:cache_manifest_path] || 'cache.manifest'
      @path_prefix = @options[:path_prefix] || ''
      @css_path_prefix = @options[:css_path_prefix] || ''
      @exclude_files = Array(@options[:exclude_files])
      @exclude_pattern = @options[:exclude_pattern]
      @manifest = {}
    end

    def add_to_manifest(key, path)
      if @options[:extended_manifest]
        @manifest[key] = {
          :path => File.expand_path(@path_prefix + "/" + path),
          :size => File.size(File.join(@target_dir, path))
        }
      else
        @manifest[key] = File.expand_path(@path_prefix + "/" + path)
      end
    end

    def to_manifest(path, keep_original = true)
      debug "adding: #{path}"
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
      add_to_manifest(manifest_key_path, File.join(dirname, new_file_name))
   end

    def stylesheets
      @stylesheets ||= calculate_stylesheets
    end

    def javascripts
      @javascripts ||= calculate_javascripts
    end

   def run
      debug "reading files from #{@source_dir}"
      validate
      version_files
      combine_css
      combine_js
      generate_cache_manifests
      write_manifest
      debug "files written to #{@target_dir}"
    end

    def write_manifest
      File.open(@manifest_path, 'w') do |f|
        f.write JSON.pretty_generate(@manifest)
      end
    end

    def version_files
      FileUtils.cd(@source_dir) do
        Dir["**/*"].reject{ |f| exclude_file?(f) }.each do |path|
          if File.directory? path
            FileUtils.mkdir_p(File.join(@target_dir, path))
            next
          end

          FileUtils.cp(path, File.join(@target_dir, path))
          to_manifest(path, false)
        end
      end
    end

    def combine_css
      stylesheets.each do |config|
        combine_files(config[:files], config[:target_path])
        rewrite_urls_in_css(config[:target_path])
        compress_css(config[:target_path])
        to_manifest(config[:target_path], false)
        gzip_target(config[:target_path]) if @options[:gzip]
      end
    end

    def rewrite_urls_in_css(stylesheet_path)
      url_regex = /(^|[{;,])(.*?url\(\s*['"]?)(.*?)(['"]?\s*\).*?)([,;}]|$)/ui
      behavior_regex = /behavior:\s*url/ui
      data_regex = /^\s*data:/ui
      input = File.open(File.join(@target_dir, stylesheet_path)){|f| f.read}
      output = input.gsub(url_regex) do |full_match|
        pre, url_match, post = ($1 + $2), $3, ($4 + $5)
        if behavior_regex.match(pre) || data_regex.match(url_match)
          full_match
        else
          path = Addressable::URI.parse("/") + url_match
          target_url = @manifest[path.to_s]
          if target_url
            pre + @css_path_prefix + target_url + post
          else
            full_match
          end
        end
      end
      File.open(File.join(@target_dir, stylesheet_path), 'w') do |f|
        f.write output
      end
    end

    def compress_css(stylesheet_path)
      css = File.open(File.join(@target_dir, stylesheet_path)){|f| f.read}
      compressed = Rainpress.compress(css)
      File.open(File.join(@target_dir, stylesheet_path), 'w') do |f|
        f.write compressed
      end
    end

    def combine_js
      javascripts.each do |config|
        combine_files(config[:files], config[:target_path])
        compress_js(config[:target_path])
        to_manifest(config[:target_path], false)
        gzip_target(config[:target_path]) if @options[:gzip]
      end
    end

    def compress_js(javascript_path)
      javascript = File.open(File.join(@target_dir, javascript_path)){|f| f.read}
      compressed = Uglifier.compile(javascript)
      File.open(File.join(@target_dir, javascript_path), 'w'){|f| f.write compressed}
    end

    def generate_cache_manifests
      cache_manifests = @options[:cache_manifests] || []
      if @cache_manifest_path
        cache_manifests << { 
          :target_path => @cache_manifest_path,
          :files => @manifest.keys
        }
      end
      cache_manifests.each do |cache_manifest|
        generate_cache_manifest(cache_manifest)
      end
    end

    # IMPORTANT:html 5 cache manifest should not be cached
    # because that would treat it as a new manifest with
    # new resources discarding the ones already downloaded
    # http://diveintohtml5.org/offline.html
    def generate_cache_manifest(cache_manifest)
      path = File.join(@target_dir, cache_manifest[:target_path])
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        f.puts 'CACHE MANIFEST'
        f.puts ''
        f.puts '# Explicitely cached entries'
        cache_manifest[:files].each do |relative_path|
          f.puts @manifest[File.join('/', relative_path)]
        end
        f.puts ''
        f.puts 'NETWORK:'
        f.puts '*'
      end
      add_to_manifest(File.join("/", cache_manifest[:target_path]), cache_manifest[:target_path])
    end

    protected

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

    def gzip_target(target_path)
      versioned_path = @manifest[File.join('/', target_path)]
      versioned_path.sub!(@path_prefix, '')
      gz_path = File.join(@target_dir, "#{versioned_path}.gz")
      Zlib::GzipWriter.open(gz_path) do |gz|
        gz << File.open(File.join(@target_dir, versioned_path)) { |f| f.read }
      end
    end

    def calculate_stylesheets
      if @options[:combine] && @options[:combine][:stylesheets]
        @options[:combine][:stylesheets]
      else
        []
      end
    end

    def calculate_javascripts
      if @options[:combine] && @options[:combine][:javascripts]
        @options[:combine][:javascripts]
      else
        []
      end
    end

    def validate
      raise_error "Source directory does not exist: #{@source_dir}" unless File.exists?(@source_dir)
    end

    def raise_error(message)
      raise ValidationError.new(message)
    end

    def exclude_file?(path)
      path =~ /\.(css|js)$/ || @exclude_files.include?(path) || (@exclude_pattern && path =~ @exclude_pattern)
    end

    def debug(message)
      STDOUT.puts message if @options[:verbose]
    end
  end
end
