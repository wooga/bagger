$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), "..", "lib") )

require "rubygems"
require 'test/unit'
require 'mocha'
require 'shoulda-context'
require 'bagger'

TEST_TEMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', 'tmp'))

