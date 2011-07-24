# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bagit/version"

Gem::Specification.new do |s|
  s.name        = "bagit"
  s.version     = Bagit::VERSION
  s.authors     = ["Patrick Huesler"]
  s.email       = ["patrick.huesler@gmail.com"]
  s.homepage    = ""
  s.summary     = "Asset packaging for the rest of us"
  s.description = "A framework agnostic packaging solution for your assets: version files, combine them, minify them and create a manifest"

  s.rubyforge_project = "bagit"

  s.add_dependency "json"

  s.add_development_dependency "rake"
  s.add_development_dependency "shoulda-context"
  s.add_development_dependency "mocha"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
