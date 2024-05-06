require_relative "lib/bcdice/version"

Gem::Specification.new do |spec|
  spec.name        = "bcdice"
  spec.version     = BCDice::VERSION
  spec.authors     = ["SAKATA Sinji"]
  spec.email       = ["ysakasin@gmail.com"]

  spec.summary     = "BCDice is a rolling dice engine for TRPG"
  spec.description = "BCDice is a rolling dice engine for TRPG"
  spec.homepage    = "https://bcdice.org"
  spec.license     = "BSD-3-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bcdice/BCDice"
  spec.metadata["changelog_uri"] = "https://github.com/bcdice/BCDice/blob/master/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "i18n/**/*", "CHANGELOG.md", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "i18n", "~> 1.8.5"
  spec.add_runtime_dependency "racc", "~> 1.7.3"
end
