# encoding: UTF-8
module Bagger
  class CssPackager
    def initialize(options)
      @source_dir = options[:base_dir]
      @target_file = options[:target_file]
      @exclude_files = options[:exclude_files] || nil
    end
    
    def package
      FileUtils.mkdir_p(File.dirname(@target_file))
      File.open(@target_file, "w+") { |cache| cache.write(join_asset_file_contents(paths)) }
    end
    
    private
    
    def paths
      Dir.glob("#{@source_dir}/**/**.css").sort
    end
    
    def join_asset_file_contents(paths)
      paths.collect do |path|
        process_file(path) unless @exclude_files && path.match(/#{@exclude_files}/)
      end.join("\n\n")
    end
    
    def process_file(file)
      File.open(file, 'r+'){|f| f.readlines}.reject do |line|
        line =~ (/@import\s+url\(.+\)/) && URI.extract(line).empty?
      end.join
    end
  end
end
