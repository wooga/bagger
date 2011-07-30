require 'test_helper'
require 'tmpdir'

class BaggerTest < Test::Unit::TestCase

  def setup
    @source_dir = Dir.mktmpdir
    @target_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry_secure @source_dir
    FileUtils.remove_entry_secure @target_dir
  end

  def write_file(path, content)
    File.open(path, 'w') do |f|
      f.write content
    end
  end

  context 'manifest' do
    should 'generate one' do
      Bagger.bagit!(:source_dir => @source_dir)
      assert File.exists?(File.join(@source_dir, 'manifest.json')), 'manifest was not created'
    end
  end

  context 'combine css files' do
    setup do
      @config = { :stylesheets => [] }
      @css_dir = File.join(@source_dir, 'css')
      FileUtils.mkdir_p(@css_dir)
      %w(one two).each do |file|
        write_file(
                    File.join(@css_dir, "#{file}.css"),
                    ".#{file}{}"
                  )
        @config[:stylesheets] << "css/#{file}.css"
      end
    end

    should 'combine it' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, 'css', 'combined.css')
 
      assert File.exists?(expected_file_path), 'combined css not found'
    end

    should 'only copy over the generate file' do

    end
end

  context 'combine javascript' do

  end

  context 'minify javascript' do

  end

  context 'minify css' do

  end

  context 'rewrite css urls' do

  end

  context 'version files' do

  end
end
