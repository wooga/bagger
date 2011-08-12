# CHANGELOG

## v 0.0.2

* Make file and cache manifest path configurable
* Validate that the source directory actually exists

## v 0.0.1

* Combines javascript
* Minfies javascript with [UglifyJS](https://github.com/mishoo/UglifyJS)
* Combines stylesheets
* Rewrites urls in stylesheets
* Minfies stylesheets with [rainpress](https://rubygems.org/gems/rainpress)
* Generates versioned file names e.g /images/logo.19db9a16e2b73017c575570de577d103.png
* Generates a manifest file in JSON
* Generates an HTML 5 cache manifest

### Known issues

* Paths for manifest and html 5 cache manifest are hardcoded to TARGET_DIR/manifest.json and TARGET_DIR/cache.manifest
