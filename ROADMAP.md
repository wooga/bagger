# ROADMAP

## v 0.0.1

* Combines javascript
* Minfies javascript with [UglifyJS](https://github.com/mishoo/UglifyJS)
* Combines stylesheets
* Rewrites urls in stylesheets
* Minfies stylesheets with [rainpress](https://rubygems.org/gems/rainpress)
* Generates versioned file names e.g /images/logo.19db9a16e2b73017c575570de577d103.png
* Generates a manifest file in JSON
* Generates an HTML 5 cache manifest

## v 0.1.0

* allow to specify the the paths for cache.manifest and manifest.json
* better validation

## v 0.2.0 

* generate custom manifest files e.g with support for file size

    {
		'/myfile.txt' => {
							:path => '/myfile.19db9a16e2b73017c575570de577d103.txt'
							:size => '391'
						 }
	}