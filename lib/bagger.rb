require "rubygems"
require 'json'
require "bagger/packager"

module Bagger
  class ValidationError < RuntimeError ; end

  def self.bagit!(options)
    Bagger::Packager.new(options).run
  end
end
