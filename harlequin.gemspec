# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "harlequin/version"

Gem::Specification.new do |s|
  s.name        = "harlequin"
  s.version     = Harlequin::VERSION
  s.authors     = ["Brian Stanwyck"]
  s.email       = ["brian@highgroove.com"]
  s.homepage    = ""
  s.summary     = %q{Wrapper for discriminant analysis methods in R}
  s.description = %q{harlequin is a Ruby wrapper for linear and quadratic discriminant analysis in R for statistical classification. Also allows means testing to determine significance of discriminant variables.}

  s.rubyforge_project = "harlequin"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here
  
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_dependency             "rinruby"
end
