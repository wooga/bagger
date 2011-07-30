require "rubygems"
require 'json'
require "digest/md5"
require "bagger/css_packager"
require "bagger/css_url_changer"
require "bagger/file_list"
require "bagger/svn_info"
require "bagger/ftp_sync"
require "bagger/packager"
require "bagger/version"

module Bagger
  def self.bagit!(options)
    Packager.new(options).package
  end
end
