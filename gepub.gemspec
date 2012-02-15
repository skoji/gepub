# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gepub/version"

Gem::Specification.new do |s|
  s.name        = "gepub"
  s.version     = GEPUB::VERSION
  s.authors     = ["KOJIMA Satoshi"]
  s.email       = ["skoji@mac.com"]
  s.homepage    = %q{http://github.com/skoji/gepub}
  s.summary     = %q{a generic EPUB parser/generator.}
  s.description = %q{gepub is a EPUB parser/generator. Generates EPUB2 opf. will support EPUB3 parse/generation}

  s.rubyforge_project = "gepub"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">= 2"
  s.add_development_dependency "epubcheck", ">= 0.1.0"
  s.add_runtime_dependency "nokogiri", ">= 1.5.0"
  s.add_runtime_dependency "rubyzip", ">= 0.9.6"
  s.add_runtime_dependency "activesupport"
end
