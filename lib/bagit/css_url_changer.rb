# encoding: UTF-8
module Bagit
  class CssUrlChanger
    def self.process_file_with_map(file, map = {})
      base_dir = File.dirname(file)
      File.open(file, 'r+') do |f|
        lines = process_lines_with_map(f.readlines,base_dir,map)
        f.pos = 0
        f.print lines.join
        f.truncate(f.pos)
      end
    end

    def self.process_directory_with_map(directory, map = {})
      Dir.glob("#{directory}/**/**.css").each do |css_file|
        process_file_with_map(css_file, map)
      end
    end

    private

    def self.process_lines_with_map(lines,base_dir,map)
      lines.each do |line|
        match = line.match(/url\(['"]([^:]+)['"]\)/)
        if match
          file_info = map[File.expand_path(match[1],base_dir)]
          line.sub!(match[1],file_info[:url]) if file_info && file_info[:url]
        end
      end
      lines
    end
  end
end
