require "rubygems"
require 'json'
require "bagger/packager"

module Bagger
  def self.bagit!(options)
    Bagger::Packager.new(options).run
  end
end
