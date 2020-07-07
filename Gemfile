source 'https://rubygems.org'

group :development, :test do
  if RUBY_VERSION < '1.9'
    gem 'rake', '~> 10.5'
    gem 'test-unit', '1.2.3'
  else
    gem 'codecov', :require => false
    gem 'rake'
    gem 'test-unit'
  end

  if '1.9' <= RUBY_VERSION && RUBY_VERSION < '2.0'
    gem 'json', '~> 2.2.0'
  end

  if RUBY_VERSION >= '2.3'
    gem 'rubocop', '~> 0.72.0', :require => false
    gem 'yard'
  end
end

if RUBY_VERSION > '1.8.x'
  gem 'simplecov', :require => false
end
