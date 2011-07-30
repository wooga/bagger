# encoding: UTF-8
require 'yaml'
module Bagger
  class SVNInfo
    @@silence_warnings = false
    class << self
      attr_accessor :silence_warnings
    end
  
    def self.revision_for_file(file)
      get_revision_for_file(file)
    end
    
    def self.revision
      get_revision_for_file(nil)
    end

    def self.branch
      yaml = subversion_info_command(nil)
      yaml ? yaml['URL'].to_s.split('/').last(2).join('/') : nil
    end
  
    private
        
    def self.get_revision_for_file(file)
      yaml = subversion_info_command(file)
      yaml ? yaml['Last Changed Rev'].to_s : nil      
    end
  
    def self.subversion_info_command(file)
      YAML.load(run_command("svn info #{file}"))
    end

    def self.run_command(command)
      if silence_warnings
        `#{command} 2>/dev/null`.chomp
      else
        `#{command}`.chomp
      end
    end
  end
end
