# encoding: UTF-8
require 'net/ftp'
module Bagger
  class FTPSync
    class << self
      attr_accessor :silence_log_messages
      silence_log_messages = false
    end

    attr_accessor :ftp_client

    def initialize(host, user, password)
      @host = host
      @user = user
      @password = password
      @ftp_client = Net::FTP
    end

    def ftp
      if @ftp.nil? || @ftp.closed?
        @ftp = ftp_client.send(:new, @host)
        @ftp.passive = true
      end
      @ftp
    end

    def one_way_sync_from_local_to_remote(local_dir, remote_dir)
      begin
        ftp.login(@user, @password)
        log "logged in, start syncing..."
        sync_folder(local_dir, remote_dir)
        log "sync finished"
        return true
      rescue Net::FTPPermError => e
        log "Failed: #{e.message}"
        return false
      end
    end

    def clean_up(target_dir, options)
      suffix_to_keep = options[:suffix_to_keep]
      dry_run = options[:dry_run]
      raise ArgumentError, 'please provide a suffix to keep' unless /[A-Z]/ =~ suffix_to_keep
      ftp.login(@user, @password)
      clean_up_folder(target_dir, suffix_to_keep, dry_run)
    end

    def clean_up_with_manifest(target_dir, manifest, options = {})
      ftp.login(@user, @password)
      dry_run = options[:dry_run]
      clean_up_folder_with_manifest(target_dir, manifest, dry_run)
    end

    private

    def clean_up_folder_with_manifest(target_dir, manifest, dry_run = false)
      ftp.chdir(target_dir)
      remote_dirs, remote_files = get_remote_dir_and_file_names
      remote_files.each do |file|
        full_path = File.join(ftp.pwd, file)
        if manifest.include?(full_path)
          log "[KEEP] file #{full_path}"
        else
          ftp.delete(file) unless dry_run
          log "[DELETE] file #{full_path}"
        end
      end
      remote_dirs.each do |dir|
        clean_up_folder_with_manifest(dir, manifest, dry_run)
      end
      ftp.chdir("..")
    end

    def clean_up_folder(target_dir, suffix_to_keep, dry_run = false)
      ftp.chdir(target_dir)
      remote_dirs, remote_files = get_remote_dir_and_file_names
      remote_files.each do |file|
        if file =~ /\.[0-9]{1,5}[^#{suffix_to_keep}]?\./
          log "deleting file #{target_dir}/#{file}"
          ftp.delete(file) unless dry_run
        end
      end
      remote_dirs.each do |dir|
        clean_up_folder(dir, suffix_to_keep, dry_run)
      end
      ftp.chdir("..")
    end

    def put_title(title)
      log "#{'-'*80}\n#{title}:\n\n"
    end

    def full_file_path(file)
      File.join(Dir.pwd, file)
    end

    def upload_file(file)
      put_title "upload file: #{full_file_path(file)}"
      ftp.put(file)
    end

    def upload_folder(dir)
      put_title "upload folder: #{full_file_path(dir)}"
      Dir.chdir dir
      ftp.mkdir dir
      ftp.chdir dir

      local_dirs, local_files = get_local_dir_and_file_names

      local_dirs.each do |subdir|
        upload_folder(subdir)
      end

      local_files.each do |file|
        upload_file(file)
      end

      Dir.chdir("..")
      ftp.chdir("..")
    end

    def sync_folder(local_dir, remote_dir)
      Dir.chdir local_dir
      ftp.chdir remote_dir

      put_title "process folder: #{Dir.pwd}"

      local_dirs, local_files = get_local_dir_and_file_names
      remote_dirs, remote_files = get_remote_dir_and_file_names

      new_dirs = local_dirs - remote_dirs
      new_files = local_files - remote_files
      existing_dirs = local_dirs - new_dirs
      existing_files = local_files - new_files

      new_files.each do |file|
        upload_file(file)
      end

      new_dirs.each do |dir|
        upload_folder(dir)
      end

      existing_dirs.each do |dir|
        sync_folder(dir, dir)
      end

      Dir.chdir("..")
      ftp.chdir("..")
    end

    def get_local_dir_and_file_names
      dirs = []
      files = []
      Dir.glob("*").each do |file|
        if File.file?(file)
          files << file
        else
          dirs << file
        end
      end
      return [dirs, files]
    end

    def get_remote_dir_and_file_names
      dirs = []
      files = []
      ftp.ls do |file|
        #-rw-r--r--    1 james     staff            6 Jan 07 03:54 hello.txt
        file_name = file.gsub(/\S+\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+/, '')
        case file[0, 1]
        when "-"
          files << file_name
        when "d"
          dirs << file_name
        end
      end
      return [dirs, files]
    end

    def log(message)
      puts message unless self.class.silence_log_messages
    end
  end
end
