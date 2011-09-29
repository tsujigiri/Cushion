# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cushion/version"

Gem::Specification.new do |s|
  s.name        = "cushion"
  s.version     = Cushion::VERSION
  s.authors     = ["Helge Rausch"]
  s.email       = ["helge@rausch.io"]
  s.homepage    = "https://github.com/tsujigiri/cushion"
  s.summary     = %q{A Hash with CouchDB persistence}
  s.description = %q{A Hash with indifferent access and CouchDB persistence layer}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "test-unit"
  s.add_development_dependency "shoulda"
  s.add_runtime_dependency "active_support"
end
