# encoding: UTF-8
require 'test_helper'

class BaggerTest < Test::Unit::TestCase
  context '#bagit!' do
    should 'run the asset packager' do
      options = {
                  :source_dir => 'fake/source/dir',
                  :target_dir => 'fake/test/dir'
                }
      packager_mock = mock()
      Bagger::Packager.expects(:new)
                      .with(options)
                      .returns(packager_mock)
      packager_mock.expects(:package)

      Bagger.bagit!(options)
    end
  end
end
