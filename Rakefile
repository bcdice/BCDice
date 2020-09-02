require "rake/testtask"

task :default => :test

desc 'Clean coverage resuts'
task :clean_coverage do
  require 'simplecov'
  resultset_path = SimpleCov::ResultMerger.resultset_path
  FileUtils.rm resultset_path if File.exist? resultset_path
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
      'test/setup',
      'test/testDiceBots.rb',
    ]
    t.libs = [
      'test/',
      'lib/',
    ]
    t.ruby_opts = [
      '--enable-frozen-string-literal'
    ]
  end

  Rake::TestTask.new(:unit) do |t|
    t.description = 'ユニットテスト'
    t.test_files = [
      'test/setup',
      'test/test_dicebot_info_is_defined.rb',
      'test/testDiceBotPrefixesCompatibility.rb',
      'test/test_command_parser.rb',
      'test/test_d66_table.rb',
      'test/test_srs_help_messages.rb',
      'test/test_detailed_rand_results.rb',
      'test/range_table_test.rb',
      'test/add_dice_parser_test.rb',
      'test/test_data_encoding.rb'
    ].compact
  end
end

task :test => [
  :clean_coverage,
  'test:dicebots',
  'test:unit',
]

require 'rubocop/rake_task'
RuboCop::RakeTask.new
task :test => [:rubocop] if ENV['CI'] != 'true'

require 'yard'
require 'yard/rake/yardoc_task'

YARD::Rake::YardocTask.new do |t|
  t.files = [
    'src/**/*.rb'
  ]
  t.options = []
end
