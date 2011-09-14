# bagger

A framework agnostic packaging solution to speed up loading times 
on the client side by using the following techniques:

* Generate versioned assets to maximize cache efficiency
* Combine and minify javascript and css files to reduce bandwidth
* Generate a file manifest to lookup an asset's location
* Generate an HTML 5 cache manifest
* Rewrite urls in css files with the versioned file name

## Features already implemented in version 0.0.1

* Combines javascript
* Minfies javascript with [UglifyJS](https://github.com/mishoo/UglifyJS)
* Combines stylesheets
* Rewrites urls in stylesheets
* Minfies stylesheets with [rainpress](https://rubygems.org/gems/rainpress)
* Generates versioned file names e.g /images/logo.19db9a16e2b73017c575570de577d103.png
* Generates a manifest file in JSON
* Generates an HTML 5 cache manifest

## Installation

    gem install bagger

## Usage
	require 'bagger'
	require 'fileutils'
	
	# define source and target directories
	target_dir = "/tmp/bundled_assets"
	source_dir = "/applications/my_app/public"
  
	# customize paths for file and cache manifest
	manifest_path = File.join(target_dir, 'file_manifest.json') #defaults
	to manifest.json

	cache_manifest_path = 'cache/cache.manifest' # defaults to cache.manifest
	
	# list the stylesheets and javascripts to be combined
	# and minified. The order is important, because otherwhise
	# the behavior of the stylesheets and javascripts might change
	stylesheets = ["css/style.css", "css/reset.css"]
	javascripts = ["js/app.js", "js/utils.js"]

	# define cache manifest bundles for directorfferent devices
	# for convencien, the manfiest defined with `cache_manifest_path`
	# will always contain all resources
	ipad_resources = ["images/troll-big.png"]
	iphone_retina_resources = ["images/troll-retina.png"]
	desktop_browser_resources = ["images/troll.png"]
	
	# make sure the target directory exists
	FileUtils.mkdir_p target_dir
	
	# define the options hash
	options = {
	  :source_dir => target_dir,
	  :target_dir => source_dir,
    :manifest_path => manifest_path,
    :cache_manifest_path => cache_manifest_path,
	  :combine => {
	    :stylesheets => [
        {
          :target_path => 'css/all.css',
          :files => stylesheets
        }
      ],
	    :javascripts => [
        {
          :target_path => 'js/combined.js',
          :files => javascripts
        }
      ]
	  },
    :cache_manifests => [
      {
        :target_path => 'cache/ipad-cache.manifest',
        :files => ipad_resources
      },
      {
        :target_path => 'cache/retina-cache.manifest',
        :files => iphone_retina_resources
      },
      {
        :target_path => 'cache/desktop.manifest',
        :files => desktop_browser_resources
      }
    ]
	}
	
	# run it
	Bagger::bagit!(options)
	
	# TODO: at this point, the paths for the manifest and html 5 cache manifest
	# are hardcoded.
	manifest_path = File.join(target_dir, 'manifest.json')
	cache_manifest_path = File.join(target_dir, 'cache.json')
	
## Manifest layout

    {
	  "/css/all.css" : "/css/all.19db9a16e2b73017c575570de577d103.css",
	  "/js/combined.js" : "/js/combined.19db9a16e2b73017c575570de577d103.js",
	  "/images/logo.png" : "/images/logo.19db9a16e2b73017c575570de577d103.png" 
	}
	
## HTML 5 cache manifest

	CACHE MANIFEST

	# Explicitely cached entries
	/css/all.19db9a16e2b73017c575570de577d103.css
	/js/combined.19db9a16e2b73017c575570de577d103.js
	/images/logo.19db9a16e2b73017c575570de577d103.png

	NETWORK:
	*

## Tests

check the build status on [travis.ci](http://travis-ci.org/wooga/bagger)

## Similar projects

* [jammit](https://github.com/documentcloud/jammit)
* [Rails 3 asset pipeline](http://blog.nodeta.com/2011/06/14/rails-3-1-asset-pipeline-in-the-real-world/)
* [assets.io](http://www.assets.io/)
