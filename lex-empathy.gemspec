# frozen_string_literal: true

require_relative 'lib/legion/extensions/empathy/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-empathy'
  spec.version       = Legion::Extensions::Empathy::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Empathy'
  spec.description   = 'Theory of mind engine — models other agents beliefs, emotions, intentions, and cooperation stance'
  spec.homepage      = 'https://github.com/LegionIO/lex-empathy'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-empathy'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-empathy'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-empathy'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-empathy/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-empathy.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
