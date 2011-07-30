# encoding: UTF-8
require 'test_helper'

class Bagger::CSSURLChanger < Test::Unit::TestCase
  TEST_DIR = ::TEST_TEMP_DIR
  TEST_FILE = File.join(TEST_DIR, "test_file.css") unless defined?(TEST_FILE)

  def write_file(content)
    File.open(TEST_FILE,"w+") do |f|
      f.write content
    end
  end

  def file_content
    File.open(TEST_FILE){|f| f.read}
  end

  context "process_file" do
    setup do
      @map = {
        File.join(TEST_DIR,'mainMenu.css') => {:url => "http://test.host/style/mainMenu.2340.css"},
        File.join(TEST_DIR,'image/tooltip.png') => {:url => "http://test.host/style/image/tooltip.2480.png"}
      }
      
      original_content = <<-EOF
      @import url('mainMenu.css');

      MetaMenu .downArrowButton
      {
        background:#fff0 url('attach://ButtonMoveDown') no-repeat 0px 50%;
      }

      #Tooltip {
        background: url('./image/tooltip.png');
      }

      body {
        position: absolute;
        overflow: auto;
        background-image-type: animation;
      }
      EOF
      write_file(original_content)
    end

    def teardown
      FileUtils.rm_f(TEST_FILE)
    end
    
    should 'replace the urls with the information in the map' do
      Bagger::CssUrlChanger.process_file_with_map(TEST_FILE, @map)
      assert file_content.include?("url('http://test.host/style/mainMenu.2340.css');"), "imported css files should include revision numbers"
      assert file_content.include?("url('http://test.host/style/image/tooltip.2480.png');"), "imported css files should include revision numbers"
    end

    should 'leave the file structure intact' do
      expected = <<-EOF
      body {
        position: absolute;
        overflow: auto;
        background-image-type: animation;
      }
      EOF
      Bagger::CssUrlChanger.process_file_with_map(TEST_FILE, @map)
      assert file_content.include?(expected), "css should remain untouched"
    end

    should 'leave attach:// directives untouched' do
      expected = <<-EOF
        background:#fff0 url('attach://ButtonMoveDown') no-repeat 0px 50%;
      EOF
      Bagger::CssUrlChanger.process_file_with_map(TEST_FILE, @map)
      assert file_content.include?(expected)
    end
  end

  context "process_directory" do
    setup do
      @basedir = File.join(TEST_DIR, "css_test_directory")
      FileUtils.mkdir_p(@basedir)
      FileUtils.chdir(@basedir) do
        FileUtils.mkdir_p(File.join(@basedir, "subdir1"))
        content = "@import url('mainMenu.css');"
        ["test1.css", "test2.css", 'subdir1/testsub1.css'].each do |file_name|
          `echo "#{content}" > #{file_name}`
        end
      end
      
      @map = {
        File.join(@basedir,'mainMenu.css') => {:url => "http://test.host/style/mainMenu.2340.css"},
        File.join(@basedir,'subdir1','mainMenu.css') => {:url => "http://test.host/style/basedir1/mainMenu.2340.css"}
      }
    end

    teardown do
      FileUtils.rm_rf(@basedir)
    end

    should 'process all css files in a given directory' do
      Bagger::CssUrlChanger.process_directory_with_map(@basedir, @map)
      assert_equal "@import url('http://test.host/style/mainMenu.2340.css');\n", File.open(File.join(@basedir,'test1.css')){|f| f.read}
      assert_equal "@import url('http://test.host/style/mainMenu.2340.css');\n", File.open(File.join(@basedir,'test2.css')){|f| f.read}
    end

    should "process the css files in subdirectories of a given directory" do
      Bagger::CssUrlChanger.process_directory_with_map(@basedir, @map)
      assert_equal "@import url('http://test.host/style/basedir1/mainMenu.2340.css');\n", File.open(File.join(@basedir,'subdir1','testsub1.css')){|f| f.read}
    end
  end
end
