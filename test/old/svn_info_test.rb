# encoding: UTF-8
require 'test_helper'

class Bagger::SVNInfoTest < Test::Unit::TestCase
  FAKE_RESPONSE = <<-eos
  Path: Rakefile
  Name: Rakefile
  URL: https://wooga.svn.beanstalkapp.com/pets/trunk/server
  Repository Root: https://wooga.svn.beanstalkapp.com/pets
  Repository UUID: 7ed62783-5fa2-41fb-8d69-1c0cd56a9f5c
  Revision: 1956
  Node Kind: file
  Schedule: normal
  Last Changed Author: tim_lossen
  Last Changed Rev: 1342
  Last Changed Date: 2010-05-07 14:55:05 +0200 (Fr, 07 Mai 2010)
  Text Last Updated: 2010-06-04 13:44:26 +0200 (Fr, 04 Jun 2010)
  Checksum: a9e3cecdba63d63194917d6860059044
  eos

  context "revision_for_file" do
    should "return the revision info" do
      Bagger::SVNInfo.stubs(:run_command).returns(FAKE_RESPONSE)
      assert_equal "1342", Bagger::SVNInfo.revision_for_file(nil)
    end
  end

  context "branch" do
    should "return the last two folders" do
      Bagger::SVNInfo.stubs(:run_command).returns(FAKE_RESPONSE)
      assert_equal 'trunk/server', Bagger::SVNInfo.branch
    end
  end
end