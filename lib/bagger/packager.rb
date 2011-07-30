# encoding: UTF-8
module Bagger
  class Packager
    def initialize(options = {:exclude_pattern => nil, :css_packager_options => {}})
      @source_dir = options[:source_dir]
      @target_dir = options[:target_dir]
      @asset_base_url = options[:target_host]
      @exclude_pattern = options[:exclude_pattern]
      @assets = Bagger::FileList.new(@source_dir, @exclude_pattern)
      @css_packager_options = options[:css_packager_options]
      @revision_suffix = options[:revision_suffix] || ''
      FileUtils.mkdir_p(@target_dir)
    end
  
    def package
      copy_directories_to_target(@assets.directories)
      @file_info = {}
      @assets.files.each do |file|
        target_file = file_with_revision(file)
        copy_file_to_target(file,target_file)
        @file_info[file] = file_info_hash(target_file, File.join(@target_dir, target_file))
      end
      combine_css
      write_file_info_file(@file_info, @source_dir)
    end
    
    def combine_css
      return unless process_css?
      package_css
      process_combined_css
      new_file = append_digest_to_combined_css_file_name
      update_file_info_for_combined_css(File.basename(new_file), new_file)
    end
      
    def generate_file_list
      file_info = {}
      @assets.files.each do |file|
        file_info[file] = file_info_hash(file, File.join(@source_dir,file))
      end
      write_file_info_file(file_info, @target_dir)
    end
  
    private
    
    def process_css?
      @css_packager_options && @css_packager_options[:combined_css_file_path]
    end
    
    def combined_css_file_path
      @css_packager_options[:combined_css_file_path] || ''
    end
  
    def file_info_hash(path, file)
      {
        :url => path,
        :size_in_bytes => File.size(file)
      }
    end
  
    def copy_directories_to_target(directories)
      FileUtils.mkdir_p directories.map{|d| File.join(@target_dir, d)}
    end
  
    def write_file_info_file(file_info, target_dir)
      File.open(File.join(target_dir, "file_info.json"), "w") do |f|
        f.write JSON.pretty_generate(file_info)
      end
    end
    
    def file_with_revision(file)
      extension = File.extname(file)
      if !extension.empty?
        file.sub(extension,versioned_extension_for_file(file))
      else
        file + versioned_extension_for_file(file)
      end
    end
  
    def versioned_extension_for_file(file)
      revision = SVNInfo.revision_for_file(File.join(@source_dir,file))
      extension = File.extname(file)
      if revision
        [".#{revision}",@revision_suffix,extension].join
      else
        [@revision_suffix,extension].join
      end
    end
  
    def copy_file_to_target(source,target)
      FileUtils.cp(File.join(@source_dir,source),File.join(@target_dir,target))
    end
    
    def package_css
      Bagger::CssPackager.new(@target_dir, 
                                    File.join(@target_dir,combined_css_file_path),
                                    @css_packager_options
                                   ).package   
    end
    
    def process_combined_css
      file_info_with_absolute_paths = {}
      @file_info.each do |path, info|
        file_info_with_absolute_paths[File.join(@target_dir,path)] = {:url => info[:url]}
      end
      CssUrlChanger.process_file_with_map(File.join(@target_dir,combined_css_file_path), file_info_with_absolute_paths)
    end
    
    def append_digest_to_combined_css_file_name
      digest = Digest::MD5.hexdigest(File.open(File.join(@target_dir,combined_css_file_path)) { |f| f.read})[0,8]
      basename = File.basename(combined_css_file_path, '.css')
      new_file_path = File.join(File.dirname(File.join(@target_dir,combined_css_file_path)),"#{basename}.#{digest}.css")
      File.rename(File.join(@target_dir,combined_css_file_path), new_file_path)
      new_file_path
    end
    
    def update_file_info_for_combined_css(file_name, new_file_path)
      relative_path =  File.dirname(File.expand_path(combined_css_file_path,"/"))[1..-1]
      @file_info[combined_css_file_path] = file_info_hash(File.join(relative_path,file_name),new_file_path)
    end
  end
end
