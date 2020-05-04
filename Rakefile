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

desc 'Release BCDice'
task :release, ['version'] do |_, args|
  version = args.version
  version_with_prefix = "Ver#{version}"
  version_tag = "v#{version}"
  date = Time.now.strftime("%Y/%m/%d")

  header = "#{version_with_prefix} #{date}"
  md_header = "### #{header}"

  def replace(file, src, dst)
    txt = File.read(file).sub(src, dst)
    File.write(file, txt)
  end

  # Replace versions
  replace('CHANGELOG.md', '### Unreleased', md_header)
  replace('src/bcdiceCore.rb', /VERSION = ".+"/, "VERSION = \"#{version}\"")
  replace('src/configBcDice.rb', /\$bcDiceVersion = ".+"/, "$bcDiceVersion = \"#{version}\"")
  sh "git --no-pager diff"

  # Test and lint
  Rake::Task[:test].invoke

  # Commit release
  sh "git commit -a -v -e --message='Release #{version_with_prefix}'"

  # Create tag
  sections = File.read('CHANGELOG.md').split(/\n{2,}/)
  section = sections.find { |s| s.start_with?(md_header) }
  section_body = section.sub(md_header, '').strip
  sh "git tag -a -e #{version_tag} -m '#{header}' -m '#{section_body}'"

  puts "Do followings:"
  puts "  $ git checkout release; git merge master"
  puts "  $ git push origin release"
  puts "  $ git push origin master"
  puts "  $ git push origin #{version_tag}"
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
      'src/test/add_dice_parser_test.rb',
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
