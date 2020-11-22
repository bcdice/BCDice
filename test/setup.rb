require "simplecov"

if ENV["CI"] == "true" && ENV["CHECK_COVERAGE"] == "true"
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

SimpleCov.at_exit do
  SimpleCov.command_name "fork-#{$$}"
  SimpleCov.result.format!
end

SimpleCov.start do
  add_filter "/test/"
end
