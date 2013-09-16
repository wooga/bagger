# CHANGELOG
# v 0.6.1

  * improve CSS URL rewriting
  * fix rewriting for certain multi-URL properties
  * correctly rewrite IE behavior URLs unless the reference objects or default behaviors

  All changes by Martin Rehfeld

# v 0.6.0
  * Add option to add the manifest itself to the manifest (Christian
    Lundgren)

# v 0.5.0
  
  * gzip support for stylesheets and javascripts (Christian Lundgren)
  * Extended manifest with info file size (Christian Lundgren)
  * verbose option

# v 0.4.0

  * Support for css_path_prefix allows rewritten urls in stylesheets to
    be prefixed with a different path

# v 0.3.1

 * Support for exclude_files and exclude_pattern. For times when you
   don't want certain files to be processed by bagger

## v 0.2.1

 * Updating this particular roadmap

## v 0.2.0

* Support for cache manifest bundles. Useful for different target
  devices

## v 0.1.2

* Hotfix for problems with multiple urls per background directive (Horia Dragomir)

## v 0.1.1

* Do not version cache manifest (http://diveintohtml5.org/offline.html)

## v 0.1.0

* Combine javascript and stylesheets into several packages
* Change of configuration API. The javascript and stylesheets are now
  defined as an array. See the updated README.md for an example

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
