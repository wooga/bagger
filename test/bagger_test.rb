# encoding: UTF-8
require 'test_helper'

class BaggerTest < Test::Unit::TestCase

  def setup
    @source_dir = Dir.mktmpdir
    @target_dir = Dir.mktmpdir
    Uglifier.stubs(:compile).returns('//minified js');
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

  context 'validations' do
    should 'verify the source directory exists' do
      assert_raise(Bagger::ValidationError) do
        Bagger.bagit!(default_options.merge(:source_dir => '/do/not/exist'))
      end
    end
  end

  context 'manifest' do
    should 'generate one' do
      Bagger.bagit!(default_options)
      assert File.exists?(File.join(@source_dir, 'manifest.json')), 'manifest was not created'
    end

    should 'not add the manifest itself to the manfiest' do
      Bagger.bagit!(default_options)
      assert !manifest['/manifest.json']
    end

    should 'version files with md5' do
      test_content = 'testcontent'
      write_file(File.join(@source_dir, 'test.txt'), test_content)
      Bagger.bagit!(default_options)
      md5 = Digest::MD5.hexdigest(test_content)
      assert_equal md5, manifest['/test.txt'].split('.')[1]
    end

    should 'copy over the versioned files' do
      test_content = 'testcontent'
      write_file(File.join(@source_dir, 'test.txt'), test_content)
      Bagger.bagit!(default_options)
      assert File.exists?(File.join(@target_dir, manifest['/test.txt']))
    end

    should 'support a path prefix' do
      test_content = 'testcontent'
      write_file(File.join(@source_dir, 'test.txt'), test_content)
      Bagger.bagit!(default_options.merge(:path_prefix => '/path_prefix'))
      assert_match /\/path_prefix\/test\..*\.txt/, manifest['/test.txt']
    end

    should 'allow to specify the path' do
      manifest_path = File.join(@target_dir, 'custom.manifest')
      Bagger.bagit!(default_options.merge(:manifest_path => manifest_path))
      assert File.exists?(manifest_path), 'custom manifest path not found'
    end

    should 'support an exclude file list' do
      write_file(File.join(@source_dir, 'test.txt'), 'foo')
      Bagger.bagit!(default_options.merge(:exclude_files => 'test.txt'))
      assert_nil manifest['/test.txt']
    end

    should 'support an exclude file pattern' do
      write_file(File.join(@source_dir, 'test.txt'), 'foo')
      Bagger.bagit!(default_options.merge(:exclude_pattern => /.*\.txt/))
      assert_nil manifest['/test.txt']
    end
  end

  context 'html 5 cache manifest' do
    should 'generate one' do
      Bagger.bagit!(default_options)
      expected_path = File.join(@target_dir, 'cache.manifest')
      assert File.exists?(expected_path), 'cache manifest not found'
    end

    should 'add the cache manifest to the manifest' do
      Bagger.bagit!(default_options)
      assert_equal "/cache.manifest", manifest['/cache.manifest']
    end

    should 'not version the cache manifest (http://diveintohtml5.org/offline.html)' do
      Bagger.bagit!(default_options)
      expected_path = File.join(@target_dir, 'cache.manifest')
      assert File.exists?(expected_path), 'unversionened cache manifest not found'
    end

    should 'allow to specify the path' do
      manifest_path = 'cache/cache.manifest'
      Bagger.bagit!(default_options.merge(:cache_manifest_path => manifest_path))
      expected_path = File.join(@target_dir, manifest_path)
      assert File.exists?(expected_path), 'custom cache manifest path not found'
    end

    context 'packages' do
      setup do
        @images_dir = File.join(@source_dir, 'images')
        FileUtils.mkdir_p(@images_dir)
        FileUtils.touch(File.join(@images_dir, 'retina.png'))
        FileUtils.touch(File.join(@images_dir, 'ipad.png'))

        @manifest_options = {
          :cache_manifests => [
            {
              :target_path => 'cache/retina-cache.manifest',
              :files => ['images/retina.png']
            },
            {
              :target_path => 'cache/ipad-cache.manifest',
              :files => ['images/ipad.png']
            }
          ]
        }
      end

      should 'add the cache files' do
        Bagger.bagit!(default_options.merge(@manifest_options))
        assert File.exists?(File.join(@target_dir, 'cache/retina-cache.manifest'))
        assert File.exists?(File.join(@target_dir, 'cache/ipad-cache.manifest'))
      end

      should 'add the files listed to the respective manifest' do
        Bagger.bagit!(default_options.merge(@manifest_options))
        cache_file_content = File.open(File.join(@target_dir, 'cache/retina-cache.manifest')){|f| f.read}
        assert cache_file_content.include?(manifest['/images/retina.png'])
      end

      should 'only add the files listed' do
        Bagger.bagit!(default_options.merge(@manifest_options))
        cache_file_content = File.open(File.join(@target_dir, 'cache/retina-cache.manifest')){|f| f.read}
        assert !cache_file_content.include?(manifest['/images/ipad.png'])
      end
    end
  end

  context 'css files' do
    setup do
      @config = {
        :stylesheets => [{
          :target_path => 'css/combined.css',
          :files => []
        }]
      }
      @css_dir = File.join(@source_dir, 'css')
      FileUtils.mkdir_p(@css_dir)
      %w(one two).each do |file|
        write_file(
                    File.join(@css_dir, "#{file}.css"),
                    ".#{file}{}"
                  )
        @config[:stylesheets][0][:files] << "css/#{file}.css"
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

    should 'minify it' do
      Rainpress.stubs(:compress).returns('//super minified css');
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, manifest['/css/combined.css'])
      compressed_content = File.open(expected_file_path){|f| f.read}
      assert_equal '//super minified css', compressed_content , 'combined css not found'
    end

    context 'url rewriting' do
      setup do
        css = <<-EOF
        #documentRootBasedUrl {
            background: url("/images/root.png") top center;
        }
        #relativeUrl {
            background: url("../images/relative.png") top center;
        }

        #multipleUrls {
            background-image: url(../images/relative.png) no-repeat 0% 20%,
                              url(/images/multiple.png) no-repeat -20px 0;
        }

        #absoluteUrl {
            background: url('http://localhost/absolute.png') top center;
        }

        #webkitSpecials {
          -webkit-border-image: url("/images/dash.png") 8 0 8 0 repeat;
        }
        EOF
        write_file(File.join(@css_dir, "urled.css"), css)
        @config[:stylesheets][0][:files] << 'css/urled.css'
        FileUtils.mkdir_p(File.join(@source_dir, 'images'))
        %w(root relative multiple absolute dash).each do |type|
          FileUtils.touch(File.join(@source_dir, 'images', "#{type}.png"))
        end
      end

      should 'rewrite document root based urls' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :combine => @config
        )
        combined_css = File.open(File.join(@target_dir, manifest['/css/combined.css'])){|f| f.read}
        assert combined_css.include?(manifest['/images/root.png'])
      end

      should 'rewrite relative (anchored by the css file) urls to absolute paths' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :combine => @config
        )
        combined_css = File.open(File.join(@target_dir, manifest['/css/combined.css'])){|f| f.read}
        assert combined_css.include?(manifest['/images/relative.png'])
      end

      should 'rewrite multiple urls in one line' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :combine => @config
        )
        combined_css = File.open(File.join(@target_dir, manifest['/css/combined.css'])){|f| f.read}
        assert combined_css.include?(manifest['/images/relative.png'])
        assert combined_css.include?(manifest['/images/multiple.png'])
      end

      should 'rewrite directives that start with a -' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :combine => @config
        )
        combined_css = File.open(File.join(@target_dir, manifest['/css/combined.css'])){|f| f.read}
        assert combined_css.include?(manifest['/images/dash.png'])
      end

      should 'not rewrite absolute urls' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :combine => @config
        )
        combined_css = File.open(File.join(@target_dir, manifest['/css/combined.css'])){|f| f.read}
        assert combined_css.include?('http://localhost/absolute.png')
      end

      should 'support a path prefix' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :path_prefix => '/path_prefix',
          :combine => @config
        )
        combined_css_path = manifest['/css/combined.css'].gsub(/path_prefix/,'')
        combined_css = File.open(File.join(@target_dir, combined_css_path)){|f| f.read}
        assert_match /\/path_prefix\/images\/relative\..*\.png/, combined_css
      end

      # this is useful for pages being delivered outside a webserver
      # think phonegap
      should 'support a css specific path prefix for rewritten urls' do
        Bagger.bagit!(
          :source_dir => @source_dir,
          :target_dir => @target_dir,
          :css_path_prefix => '/css_path_prefix',
          :combine => @config
        )
        combined_css = File.open(File.join(@target_dir, manifest['/css/combined.css'])){|f| f.read}
        assert_match /css_path_prefix\/images\/relative\..*\.png/, combined_css
      end
    end
  end

  context 'combine javascript' do
    setup do
      @config = {
        :javascripts => [
          {
            :target_path => 'js/combined.js',
            :files => []
          }
        ]
      }
      @js_dir = File.join(@source_dir, 'js')
      FileUtils.mkdir_p(@js_dir)
      %w(one two).each do |file|
        write_file(
                    File.join(@js_dir, "#{file}.js"),
                    "var #{file} = 1;"
                  )
        @config[:javascripts][0][:files] << "js/#{file}.js"
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

    should 'minify the javascript' do
      expected_path = File.join(@target_dir, 'js', 'combined.js')
      Uglifier.expects(:compile).returns('//minified javascript')

      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, manifest['/js/combined.js'])
      assert_equal '//minified javascript', File.open(expected_file_path){|f| f.read}
    end
  end

  context 'packages' do

    setup do
      @config = {
        :javascripts => [
          {
            :target_path => 'js/common.js',
            :files => []
          },
          {
            :target_path => 'js/navigation.js',
            :files => []
          }
        ],
        :stylesheets => [
          {
            :target_path => 'css/common.css',
            :files => []
          },
          {
            :target_path => 'css/navigation.css',
            :files => []
          }
        ]
      }
      @js_dir = File.join(@source_dir, 'js')
      FileUtils.mkdir_p(@js_dir)
      @css_dir = File.join(@source_dir, 'css')
      FileUtils.mkdir_p(@css_dir)

      %w(one two).each do |file|
        write_file(
                    File.join(@js_dir, "#{file}.js"),
                    "var #{file} = 1;"
                  )
        write_file(
                    File.join(@css_dir, "#{file}.css"),
                    "##{file} { color : black }"
                  )
      end
      @config[:javascripts][0][:files] << 'js/one.js';
      @config[:javascripts][1][:files] << 'js/two.js';
      @config[:stylesheets][0][:files] << 'css/one.css';
      @config[:stylesheets][1][:files] << 'css/two.css';

      Rainpress.stubs(:compress).returns('//minified css');
    end


    should 'allow to bundle javascript into packages' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, manifest['/js/common.js'])
      assert_equal '//minified js', File.open(expected_file_path){|f| f.read}
      expected_file_path = File.join(@target_dir, manifest['/js/navigation.js'])
      assert_equal '//minified js', File.open(expected_file_path){|f| f.read}
    end

    should 'allow to bundle stylesheets into packages' do
      Bagger.bagit!(
        :source_dir => @source_dir,
        :target_dir => @target_dir,
        :combine => @config
      )
      expected_file_path = File.join(@target_dir, manifest['/css/common.css'])
      assert_equal '//minified css', File.open(expected_file_path){|f| f.read}
      expected_file_path = File.join(@target_dir, manifest['/css/navigation.css'])
      assert_equal '//minified css', File.open(expected_file_path){|f| f.read}
    end

  end
end
