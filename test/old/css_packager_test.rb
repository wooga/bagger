# encoding: UTF-8
require 'test_helper'

class Bagger::CssPackagerTest < Test::Unit::TestCase
  
  TEST_DIR = File.join(TEST_TEMP_DIR, 'css_packager_test_source') unless defined?(TEST_DIR)
  TEST_TARGET_DIR = File.join(TEST_TEMP_DIR, 'css_packager_test_target') unless defined?(TEST_TARGET_DIR)
  TEST_FILE = File.join(TEST_DIR, "test_file.css") unless defined?(TEST_FILE)

  def write_file(content, file=TEST_FILE)
    File.open(file,"w+") do |f|
      f.write content
    end
  end

  def file_content(file=TEST_FILE)
    File.open(file){|f| f.read}
  end
  
  def setup
    FileUtils.mkdir_p(TEST_DIR)
    FileUtils.mkdir_p(TEST_TARGET_DIR)    
  end
  
  def teardown
      FileUtils.rm_rf(TEST_DIR)
      FileUtils.rm_rf(TEST_TARGET_DIR)
  end
  
  context 'combining css files' do
    setup do
      original_content = <<-EOF
      p {
        display: block;
      }
      EOF
      main_menu_css = <<-EOF
      body {
        position: absolute;
        overflow: auto;
        background-image-type: animation;
      }
      EOF
      write_file(original_content)
      write_file(main_menu_css, File.join(TEST_DIR, 'zones.css'))
    end
    
   should 'combine all css files of a directory to one' do
     combined_file = File.join(TEST_TARGET_DIR, 'combined.css')
     packager = Bagger::CssPackager.new(TEST_DIR, combined_file)
     packager.package
     combined_content = file_content(combined_file)
     assert combined_content.include?(file_content(File.join(TEST_DIR,'zones.css')))
     assert combined_content.include?(file_content(TEST_FILE))
   end
   
   should 'include all the files even if the target name collides with an existing file' do
     combined_file = File.join(TEST_TARGET_DIR, 'zones.css')
     packager = Bagger::CssPackager.new(TEST_DIR, combined_file)
     packager.package
     combined_content = file_content(combined_file)
     assert combined_content.include?(file_content(File.join(TEST_DIR,'zones.css')))
     assert combined_content.include?(file_content(TEST_FILE))
   end
   
   should 'allow files to be excluded' do
     write_file('p { color: black;}', File.join(TEST_DIR, 'exclude_me.css'))
     combined_file = File.join(TEST_TARGET_DIR, 'combined.css')
     packager = Bagger::CssPackager.new(TEST_DIR, combined_file, :exclude_files => "exclude_me.css")
     packager.package
     assert !file_content(combined_file).include?(file_content(File.join(TEST_DIR, 'exclude_me.css')))
   end
 end
  
  context 'stripping out @import url statements' do
    setup do
      content = <<-EOF
        @import url('zones.css')
        @import url('http://test.host/style/zones.css')
        @define defaultLayer #ffff;
      EOF
      write_file(content)
    end
    
    should 'strip out @import statements containing paths' do
      combined_file = File.join(TEST_TARGET_DIR, 'combined.css')
      packager = Bagger::CssPackager.new(TEST_DIR, combined_file)
      packager.package
      combined_content = file_content(combined_file)
      assert !combined_content.include?("@import url('zones.css')")
    end
    
    should 'not strip out @import statements containing URLs' do
      combined_file = File.join(TEST_TARGET_DIR, 'combined.css')
      packager = Bagger::CssPackager.new(TEST_DIR, combined_file)
      packager.package
      combined_content = file_content(combined_file)
      assert combined_content.include?("@import url('http://test.host/style/zones.css')")      
    end
    
    should 'not strip out @define directives' do
      combined_file = File.join(TEST_TARGET_DIR, 'combined.css')
      packager = Bagger::CssPackager.new(TEST_DIR, combined_file)
      packager.package
      combined_content = file_content(combined_file)
      assert combined_content.include?("@define defaultLayer #ffff;")
    end
  end
end
