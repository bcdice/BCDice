# frozen_string_literal: true

require "simplecov"

if ENV["CI"] == "true" && ENV["ENABLE_COBERTURA"] == "true"
  require "simplecov-cobertura"
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.at_exit do
  SimpleCov.command_name "fork-#{$$}"
  SimpleCov.result.format!
end

SimpleCov.start do
  enable_coverage :branch
  add_filter "/test/"
end
