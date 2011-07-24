# encoding: UTF-8
module Bagit
  class FileList
    def initialize(source_dir, exclude_pattern = nil)
      @source_dir = source_dir
      @exclude_pattern = exclude_pattern
    end
  
    def files
      unless @list
        calculate_list
      end
      @files
    end
  
    def directories
      unless @list
        calculate_list
      end
      @directories
    end
  
    def list
      @list ||= calculate_list
    end
  
    private
  
    def calculate_list
      @files = []
      @directories = []
      @list = []
      FileUtils.chdir(@source_dir) do
        Dir.glob("**/**") do |file|
          unless  @exclude_pattern && file.match(/#{@exclude_pattern}/)
            File.directory?(file) ? @directories << file : @files << file
            @list << file
          end
        end
      end
      @list
    end
  end
end
