# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bigint_pk/version"

Gem::Specification.new do |s|
  s.name        = "rails-bigint-pk"
  s.version     = BigintPk::VERSION
  s.authors     = ["David J. Hamilton"]
  s.email       = ["github@hjdivad.com"]
  s.homepage    = "https://github.com/caboteria/rails-bigint-pk"
  s.summary     = %q{Easily use 64-bit primary keys in rails}
  s.description = <<-DESC
                    Rails-bigint-pk modifies Rails so that it uses
                    64-bit primary and foreign keys.  It works with
                    MySQL and PostgreSQL and has versions for Rails
                    3 and 4.
                    DESC
  s.licenses    = ['MIT']

  s.rubyforge_project = "rails-bigint-pk"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activerecord", '>= 4.0'
  s.add_runtime_dependency "railties", '>= 4.0'

  s.add_development_dependency "rspec"
  s.add_development_dependency "travis-lint"
  s.add_development_dependency "rails"
  s.add_development_dependency "mysql2", '~> 0.3.10'
  s.add_development_dependency "mysql", '~> 2.8.1'
  s.add_development_dependency "pg", '~> 0.11'
  s.add_development_dependency "sqlite3", '~> 1.3.6'
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "guard-ctags-bundler"
  s.add_development_dependency "rb-fsevent"
end
