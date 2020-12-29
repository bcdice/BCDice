require "rake/testtask"
require "bundler/gem_helper"

task default: :test

namespace "gem" do
  gem_helper = Bundler::GemHelper.new
  gem_pkg = "#{gem_helper.gemspec.name}-#{gem_helper.gemspec.version}.gem"

  desc "Build #{gem_pkg} into the pkg directory."
  task "build" do
    gem_helper.build_gem
  end

  desc "Push pkg/#{gem_pkg} to RubyGems.org."
  task "push" do
    sh "gem push pkg/#{gem_pkg} -V"
  end

  task build: "racc"
end

RACC_TARGETS = [
  "lib/bcdice/common_command/add_dice/parser.rb",
  "lib/bcdice/common_command/barabara_dice/parser.rb",
  "lib/bcdice/common_command/calc/parser.rb",
  "lib/bcdice/common_command/reroll_dice/parser.rb",
  "lib/bcdice/common_command/upper_dice/parser.rb",
].freeze

task racc: RACC_TARGETS

rule ".rb" => ".y" do |t|
  opts = [t.source,
          "-o", t.name,]
  opts << "--no-line-convert" unless ENV["RACC_DEBUG"]
  opts << "--debug" if ENV["RACC_DEBUG"]

  sh "racc", *opts
end

desc "Clean coverage resuts"
task :clean_coverage do
  require "simplecov"
  resultset_path = SimpleCov::ResultMerger.resultset_path
  FileUtils.rm resultset_path if File.exist? resultset_path
end

namespace :test do
  Rake::TestTask.new(:all) do |t|
    t.description = "全てのテストを実行する"

    t.test_files = [
      "test/setup.rb",
      "test/test_*.rb",
    ]
    t.libs = [
      "test/",
      "lib/",
    ]
    t.ruby_opts = [
      "--enable-frozen-string-literal"
    ]
  end

  Rake::TestTask.new(:dicebots) do |t|
    t.description = "ダイスボット"

    t.test_files = [
      "test/test_game_system_commands.rb",
    ]
    t.libs = [
      "test/",
      "lib/",
    ]
    t.ruby_opts = [
      "--enable-frozen-string-literal"
    ]
  end

  Rake::TestTask.new(:unit) do |t|
    t.description = "ユニットテスト"

    t.test_files = FileList[
      "test/test_*.rb",
    ].exclude("test/test_game_system_commands.rb")

    t.libs = [
      "test/",
      "lib/",
    ]
    t.ruby_opts = [
      "--enable-frozen-string-literal"
    ]
  end

  task all: "racc"
  task dicebots: "racc"
  task unit: "racc"
end

task test: [
  :clean_coverage,
  "test:all",
]

require "rubocop/rake_task"
RuboCop::RakeTask.new
task test: [:rubocop] if ENV["CI"] != "true"

require "yard"
require "yard/rake/yardoc_task"

YARD::Rake::YardocTask.new
