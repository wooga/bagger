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

  def default_options
    {
      :source_dir => @source_dir,
      :target_dir => @target_dir,
    }
  end

  def manifest
    path = File.join(@source_dir, 'manifest.json')
    json = File.open(path){|f| f.read}
    JSON.parse(json) 
  end

  context 'manifest' do
    should 'generate one' do
      Bagger.bagit!(default_options)
      assert File.exists?(File.join(@source_dir, 'manifest.json')), 'manifest was not created'
    end
  end

  context 'combine css files' do
    setup do
      @config = { 
        :stylesheets => [],
        :stylesheet_path => 'css/combined.css'
      }
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

    should 'add it to the manifest' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )

      assert manifest['/css/combined.css']
    end

    should 'combine it' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, manifest['/css/combined.css'])
      assert File.exists?(expected_file_path), 'combined css not found'
    end

    should 'only copy over the generate files' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      assert !File.exists?(File.join(@target_dir, 'css', 'one.css'))
    end
end

  context 'combine javascript' do
    setup do
      @config = { 
        :javascripts => [],
        :javascript_path => 'js/combined.js'
      }
      @js_dir = File.join(@source_dir, 'js')
      FileUtils.mkdir_p(@js_dir)
      %w(one two).each do |file|
        write_file(
                    File.join(@js_dir, "#{file}.js"),
                    "var #{file} = 1;"
                  )
        @config[:javascripts] << "js/#{file}.js"
      end
    end

    should 'add it to the manifest' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      assert manifest['/js/combined.js']
    end

    should 'combine it' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, manifest['/js/combined.js'])
      assert File.exists?(expected_file_path), 'combined js not found'
    end

    should 'only copy over the generate files' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      assert !File.exists?(File.join(@target_dir, 'js', 'one.js'))
    end
  end
end
