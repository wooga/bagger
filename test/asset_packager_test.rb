# encoding: UTF-8
require 'test_helper'

class PackagerTest < Test::Unit::TestCase
  SOURCE_DIR = File.join(::TEST_TEMP_DIR, "packaging_fixtures") unless defined?(SOURCE_DIR)
  TARGET_DIR = File.join(::TEST_TEMP_DIR, "tmp", "packaging") unless defined?(TARGET_DIR)
  
  Bagit::SVNInfo.silence_warnings = true
  
  def setup
    FileUtils.mkdir_p(SOURCE_DIR)
  end
  
  def teardown
    FileUtils.rm_rf(SOURCE_DIR)
    FileUtils.rm_rf(TARGET_DIR)
  end
  
  context 'generate_file_list' do
    should 'generate a json file' do
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.generate_file_list
      assert File.exists?(File.join(TARGET_DIR,"file_info.json")), "file could not be found"
    end
    
    should 'generate valid json hash' do
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["bar.png", "foo.png"])
      end      
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.generate_file_list
      json = JSON.parse(File.open(File.join(TARGET_DIR, 'file_info.json')).readlines.join)
      assert_equal Hash, json.class
    end
    
    should 'add the url' do
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["bar.png"])
      end      
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.generate_file_list
      list = JSON.parse(File.open(File.join(TARGET_DIR, 'file_info.json')).readlines.join)
      assert_equal "bar.png", list["bar.png"]["url"]
    end
    
    should 'add the relative path as key' do
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.mkdir_p("testdir1/subtestdir2")
        FileUtils.touch(["testdir1/subtestdir2/foo.png"])
      end      
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.generate_file_list
      list = JSON.parse(File.open(File.join(TARGET_DIR, 'file_info.json')).readlines.join)
      assert_equal "testdir1/subtestdir2/foo.png", list["testdir1/subtestdir2/foo.png"]["url"]
    end
    
    should 'add the file size in bytes' do
      FileUtils.chdir(SOURCE_DIR) do
        File.open("bar.txt", "w") do |f|
          f.puts "some content"
        end
      end      
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.generate_file_list
      list = JSON.parse(File.open(File.join(TARGET_DIR, 'file_info.json')).readlines.join)
      assert_equal 13, list["bar.txt"]["size_in_bytes"]
    end
  end
  
  context "package" do
    should "create the target directory if it does NOT exist" do
      inexistent_target_dir = File.join(TEST_TEMP_DIR, "inexistent_target_dir")
      FileUtils.rm_rf(inexistent_target_dir)
      Bagit::Packager.new(SOURCE_DIR, inexistent_target_dir, 'http://test.host/').package
      assert File.exists?(inexistent_target_dir), 'target directory should be created'
    end
    
    should "copy over the files" do
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["bar.png", "foo.png"])
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.package
      assert File.exists?(File.join(TARGET_DIR, "bar.png")), "File does not exist"
      assert File.exists?(File.join(TARGET_DIR, "foo.png")), "File does not exist"
    end
    
    should "respect the sources directory's folder structure" do
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.mkdir_p("testdir1/subtestdir2")
        FileUtils.touch(["testdir1/subtestdir2/bar.png"])
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.package      
      assert File.exists?(File.join(TARGET_DIR, "testdir1/subtestdir2/bar.png")), "File does not exist"
    end
    
    should "insert the scm revision right before the file extension" do
      Bagit::SVNInfo.stubs(:revision_for_file).returns("1956")
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["bar.png", "foo.png"])
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.package      
      assert File.exists?(File.join(TARGET_DIR, "bar.1956.png")), "File does not exist"
    end
    
    should "insert a minor revision marker if present" do
      Bagit::SVNInfo.stubs(:revision_for_file).returns("1956")
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["bar.png", "foo.png"])
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/', :revision_suffix => 'A')
      packager.package
      assert File.exists?(File.join(TARGET_DIR, "bar.1956A.png")), "File does not exist"      
    end
    
    should "handle files without an extension" do
      Bagit::SVNInfo.stubs(:revision_for_file).returns("1956")
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["some_file_without_extension"])
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.package
      assert File.exists?(File.join(TARGET_DIR, "some_file_without_extension.1956")), "File does not exist"
    end
    
    should "allow a filter" do
      FileUtils.chdir(SOURCE_DIR) do
        FileUtils.touch(["bar.png", "bar.txt"])
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/', :exclude_pattern => "\.txt")
      packager.package
      assert !File.exists?(File.join(TARGET_DIR, "bar.txt"))
    end
    
    should 'generate a json file in the source (public) dir because this file should not be cached by the cdn' do
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.package
      assert File.exists?(File.join(SOURCE_DIR,"file_info.json")), "file could not be found"
    end
    
    should 'have the right file size for files' do
      FileUtils.chdir(SOURCE_DIR) do
        File.open("bar.txt", "w") do |f|
          f.puts "some content"
        end
      end
      packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/')
      packager.package
      file_info = JSON.parse(File.read(File.join(SOURCE_DIR,"file_info.json")))
      assert_equal 13, file_info["bar.txt"]["size_in_bytes"]
    end
    
    context 'packing up css files' do
      setup do
        Digest::MD5.stubs(:hexdigest).returns('ff4c8ff084f80283faef')
        FileUtils.chdir(SOURCE_DIR) do
          FileUtils.mkdir_p('images')
          FileUtils.touch(["one.css", "two.css", "images/test.png"])
        end
        @combined_css_file = 'style/combined.css'
        @hashed_css_file = File.join(TARGET_DIR, 'style/combined.ff4c8ff0.css')
        @packager = Bagit::Packager.new(SOURCE_DIR, TARGET_DIR, 'http://test.host/',
                                  :css_packager_options => {
                                   :combined_css_file_path => @combined_css_file
                                  })
      end
            
      should 'add the first 8 md5 digits to the combined css file name after packaging' do
        Digest::MD5.expects(:hexdigest).returns('ff4c8ff084f80283faef')
        @packager.package
        assert File.exists?(@hashed_css_file)
      end
      
      should 'update all the urls inside that the combined file' do
        file_info = {
                File.join(TARGET_DIR,'two.css') => {
                  :url => 'two.css',
                },
                File.join(TARGET_DIR,'images/test.png') => {
                  :url => 'images/test.png',
                },
                File.join(TARGET_DIR,'one.css') => {
                  :url => 'one.css',
                }
              }
        Bagit::CssUrlChanger.expects(:process_file_with_map).with(File.join(TARGET_DIR,@combined_css_file), file_info)
        @packager.package
      end
      
      should 'should add the combined css file to the file_info' do
        @packager.package
        file_info = JSON.parse(File.read(File.join(SOURCE_DIR,"file_info.json")))
        assert_equal "style/combined.ff4c8ff0.css",file_info['style/combined.css']['url']
      end
    end
  end
end
