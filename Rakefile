# -*- coding: utf-8 -*-

require "rake/testtask"

task :default => :test

desc 'Clean coverage resuts'
task :clean_coverage do
  if RUBY_VERSION > '1.8.x'
    require 'simplecov'
    resultset_path = SimpleCov::ResultMerger.resultset_path
    FileUtils.rm resultset_path if File.exist? resultset_path
  end
end

namespace :test do
  Rake::TestTask.new(:dicebots) do |t|
    t.description = 'ダイスボット'

    t.test_files = [
      'src/test/setup',
      'src/test/testDiceBots.rb',
    ]
    t.libs = [
      'src/test',
      'src/',
      'src/irc'
    ]

    unless RUBY_VERSION < '1.9'
      t.ruby_opts = [
        '--enable-frozen-string-literal'
      ]
    end
  end

  Rake::TestTask.new(:unit) do |t|
    t.description = 'ユニットテスト'
    t.test_files = [
      'src/test/setup',
      'src/test/test_dicebot_info_is_defined.rb',
      'src/test/testDiceBotLoaders.rb',
      'src/test/testDiceBotPrefixesCompatibility.rb',
      'src/test/test_d66_table.rb',
      'src/test/test_srs_help_messages.rb',
      'src/test/test_detailed_rand_results.rb',
      'src/test/range_table_test.rb',
    ]
  end
end

task :test => [
  :clean_coverage,
  'test:dicebots',
  'test:unit',
]

if RUBY_VERSION >= '2.3'
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  task :test => [:rubocop]

  require 'yard'
  require 'yard/rake/yardoc_task'

  YARD::Rake::YardocTask.new do |t|
    t.files = [
      'src/**/*.rb'
    ]
    t.options = []
  end
end
