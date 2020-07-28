# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/typed_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-typedstore'
  spec.version       = ActiveRecord::TypedStore::VERSION
  spec.authors       = ['Jean Boussier']
  spec.email         = ['jean.boussier@gmail.com']
  spec.description   = %q{ActiveRecord::Store but with type definition}
  spec.summary       = %q{Add type casting and full method attributes support to АctiveRecord store}
  spec.homepage      = 'https://github.com/byroot/activerecord-typedstore'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 5.2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'coveralls', '~> 0'
  spec.add_development_dependency 'sqlite3', '~> 1'
  spec.add_development_dependency 'pg', ENV.fetch('PG_VERSION', '~> 0.18')
  spec.add_development_dependency 'mysql2', '> 0.3'
  spec.add_development_dependency 'database_cleaner', '~> 1'
end
