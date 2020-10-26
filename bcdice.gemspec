require_relative "lib/bcdice/version"

Gem::Specification.new do |spec|
  spec.name        = "bcdice"
  spec.version     = BCDice::VERSION
  spec.authors     = ["SAKATA Sinji"]
  spec.email       = ["ysakasin@gmail.com"]

  spec.summary     = "BCDice is a rolling dice engine for TRPG"
  spec.description = "BCDice is a rolling dice engine for TRPG"
  spec.homepage    = "https://bcdice.org"
  spec.license     = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bcdice/BCDice"
  spec.metadata["changelog_uri"] = "https://github.com/bcdice/BCDice/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "i18n", "~> 1.8.5"
end
