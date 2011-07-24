# bagger

A framework agnostic packaging solution to speed up client side
rendering by using the following techniques:

* Generating versioned assets to maximize cache efficienzy
* Combine, minify and lint javascript and css files to reduce bandwidth
* Zip assets to further reduce bandwitdth consumption
* Generating a file manifest to lookup an assets location
* Rewrite urls in css files with the versioned file name
* Bundle up the assets as a zip file

## Similar projects

* [jammit](https://github.com/documentcloud/jammit)
* [Rails 3 asset pipeline](http://blog.nodeta.com/2011/06/14/rails-3-1-asset-pipeline-in-the-real-world/)
* [assets.io](http://www.assets.io/)

## Roadmap

### Version 0.0.1 (Minimal Viable Product)

* Versioned assets
* Manifest files
* Combine javascript
* Combine css
* Rewrite css urls
* CLI binary
* Solid test suite
* Support for the following Ruby versions (MRI 1.8.7, 1.9.2, REE 1.8.7)
* Pass all tests on travisci.org
* Examples on how to integrate it into the development workflow using
  tools like watch or supervisor
