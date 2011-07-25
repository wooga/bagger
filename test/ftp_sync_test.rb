# encoding: UTF-8
require 'test_helper'

class FTPSyncTest < Test::Unit::TestCase

  FTP_SOURCE_DIR = File.join(TEST_TEMP_DIR, "ftp_sync_test")
  FTP_TARGET_DIR = "remote_assets"

  def ftp_string_for_filename(file_name)
    "-rw-r--r--    1 james     staff            6 Jan 07 03:54 #{file_name}"
  end

  def ftp_string_for_directory(directory_name)
    "drw-r--r--    1 james     staff            6 Jan 07 03:54 #{directory_name}"
  end

  Bagger::FTPSync.silence_log_messages = true

  context "one_way_sync_from_local_to_remote" do
    setup do
      FileUtils.mkdir_p(FTP_SOURCE_DIR)

      @ftp_client_test_double = stub_everything('fake_ftp_client')
      @ftp_fake_client_class = stub("FakeFTPClient", :new => @ftp_client_test_double)

      @ftp = Bagger::FTPSync.new("ftp.test.host", "ftpuser", "ftppassword")
      @ftp.ftp_client = @ftp_fake_client_class
    end

    teardown do
      FileUtils.rm_rf(FTP_SOURCE_DIR)
      FileUtils.rm_rf(FTP_TARGET_DIR)
    end

    should "open a connection to the host" do
      @ftp_fake_client_class.expects(:new).with('ftp.test.host').returns(@ftp_client_test_double)
      @ftp.one_way_sync_from_local_to_remote(FTP_SOURCE_DIR, FTP_TARGET_DIR)
    end

    should "login into the ftp server" do
      @ftp_client_test_double.expects(:login).with('ftpuser','ftppassword')
      @ftp.one_way_sync_from_local_to_remote(FTP_SOURCE_DIR, FTP_TARGET_DIR)
    end

    should 'copy new files to the remote host' do
      FileUtils.touch(File.join(FTP_SOURCE_DIR, 'test.txt'))
      @ftp_client_test_double.expects(:put).with("test.txt")
      @ftp.one_way_sync_from_local_to_remote(FTP_SOURCE_DIR, FTP_TARGET_DIR)
    end

    should 'copy new directories' do
      FileUtils.mkdir(File.join(FTP_SOURCE_DIR, 'testdirectory'))
      @ftp_client_test_double.expects(:mkdir).with('testdirectory')
      @ftp.one_way_sync_from_local_to_remote(FTP_SOURCE_DIR, FTP_TARGET_DIR)
    end

    should 'copy files of subdirectories' do
      FileUtils.mkdir(File.join(FTP_SOURCE_DIR, 'testdirectory'))
      FileUtils.touch File.join(FTP_SOURCE_DIR, 'testdirectory', 'subfile.txt')
      @ftp_client_test_double.expects(:put).with('subfile.txt')
      @ftp.one_way_sync_from_local_to_remote(FTP_SOURCE_DIR, FTP_TARGET_DIR)
    end

    should 'not copy a file to the remote host if it exists already' do
      FileUtils.touch(File.join(FTP_SOURCE_DIR, 'test.txt'))
      @ftp_client_test_double.stubs(:ls).yields(ftp_string_for_filename("test.txt"))
      @ftp_client_test_double.expects(:put).with('test.txt').times(0)
      @ftp.one_way_sync_from_local_to_remote(FTP_SOURCE_DIR, FTP_TARGET_DIR)
    end
  end
  
  context 'clean up resources with a manifest' do
    setup do
      @ftp_client_test_double = stub_everything('fake_ftp_client')
      @ftp_fake_client_class = stub("FakeFTPClient", :new => @ftp_client_test_double)

      @ftp = Bagger::FTPSync.new("ftp.test.host", "ftpuser", "ftppassword")
      @ftp.ftp_client = @ftp_fake_client_class

      @ftp_client_test_double.stubs(:ls).multiple_yields(
        ftp_string_for_filename("fake.3219C.txt"),
        ftp_string_for_filename("fake.3211C.txt"),
        ftp_string_for_directory("subdir1")
      ).then.multiple_yields(
        ftp_string_for_filename("fake.2223C.txt"),
        ftp_string_for_filename("fake.2222C.txt"),
        ftp_string_for_directory("subdir2")
      ).then.multiple_yields(
        ftp_string_for_filename("fake.3333C.txt"),
        ftp_string_for_filename("fake.3332C.txt")
      )
      @ftp_client_test_double.stubs(:pwd).returns('/published', '/published', '/published/subdir1', '/published/subdir1', '/published/subdir1/subdir2')
      @manifest = ["/published/fake.3219C.txt", "/published/subdir1/fake.2223C.txt", "/published/subdir1/subdir2/fake.3333C.txt"]
    end
    
    should 'delete versions not in the manifest' do
      @ftp_client_test_double.expects(:delete).with('fake.3211C.txt')
      @ftp.clean_up_with_manifest(FTP_TARGET_DIR, @manifest)
    end
    
    should 'keep files in the manifest' do
      @ftp_client_test_double.expects(:delete).with('fake.3219C.txt').never
      @ftp.clean_up_with_manifest(FTP_TARGET_DIR, @manifest)      
    end
    
    should 'keep files in subdirectories' do
      @ftp_client_test_double.expects(:delete).with('fake.3219C.txt').never
      @ftp_client_test_double.expects(:delete).with('fake.2223C.txt').never
      @ftp_client_test_double.expects(:delete).with('fake.3333C.txt').never
      @ftp.clean_up_with_manifest(FTP_TARGET_DIR, @manifest)
    end
    
    should 'descend into subdirectories and delete' do
      @ftp_client_test_double.expects(:delete).with('fake.2222C.txt')
      @ftp_client_test_double.expects(:delete).with('fake.3332C.txt')
      @ftp.clean_up_with_manifest(FTP_TARGET_DIR, @manifest)            
    end
    
    should 'have a dry run option' do
      @ftp_client_test_double.expects(:delete).never
      @ftp.clean_up_with_manifest(FTP_TARGET_DIR, @manifest, :dry_run => true)
    end
  end

  context 'clean up resources by index' do
    setup do
      @ftp_client_test_double = stub_everything('fake_ftp_client')
      @ftp_fake_client_class = stub("FakeFTPClient", :new => @ftp_client_test_double)

      @ftp = Bagger::FTPSync.new("ftp.test.host", "ftpuser", "ftppassword")
      @ftp.ftp_client = @ftp_fake_client_class

      @ftp_client_test_double.stubs(:ls).multiple_yields(
        ftp_string_for_filename("flash.14695871.css"),
        ftp_string_for_filename("512K"),
        ftp_string_for_filename("test.txt"),
        ftp_string_for_filename("test.1000.txt"),
        ftp_string_for_filename("test.1001A.txt"),
        ftp_string_for_filename("test.1002B.txt"),
        ftp_string_for_filename("test.1003C.txt"),
        ftp_string_for_filename("test.1004C.txt")
        )
    end

    should 'delete old versions' do
      @ftp_client_test_double.expects(:delete).with('test.1000.txt')
      @ftp_client_test_double.expects(:delete).with('test.1001A.txt')
      @ftp_client_test_double.expects(:delete).with('test.1002B.txt')
      @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'C')
    end

    should 'keep unrevisioned files' do
      @ftp_client_test_double.expects(:delete).with('test.txt').never
      @ftp_client_test_double.expects(:delete).with('512K').never
      @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'C')
    end

    should 'keep files with suffix C' do
      @ftp_client_test_double.expects(:delete).with('test.1004C.txt').never
      @ftp_client_test_double.expects(:delete).with('test.1003C.txt').never
      @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'C')
    end

    should 'keep files with a different versioning schema' do
      @ftp_client_test_double.expects(:delete).with('flash.14695871.css').never
      @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'C')
    end

    should 'make the suffix to keep configurable' do
      @ftp_client_test_double.expects(:delete).with('test.1001A.txt').never
      @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'A')
    end

    should 'raise an exception if suffix to keep is blank' do
      assert_raises(ArgumentError){ @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => nil) }
    end

    should 'raise an exception if suffix is not a single uppercase letter' do
      assert_raises(ArgumentError){ @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'foo') }
    end

    should 'not delete files when the dry run option is set' do
      @ftp_client_test_double.expects(:delete).never
      @ftp.clean_up(FTP_TARGET_DIR, :suffix_to_keep => 'C', :dry_run => true)
    end
  end
end
