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
end

RACC_TARGETS = [
  "lib/bcdice/common_command/add_dice/parser.rb",
  "lib/bcdice/common_command/barabara_dice/parser.rb",
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

desc "Release BCDice"
task :release, ["version"] do |_, args|
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
  replace("CHANGELOG.md", "### Unreleased", md_header)
  replace("src/bcdiceCore.rb", /VERSION = ".+"/, "VERSION = \"#{version}\"")
  replace("src/configBcDice.rb", /\$bcDiceVersion = ".+"/, "$bcDiceVersion = \"#{version}\"")
  sh "git --no-pager diff"

  # Test and lint
  Rake::Task[:test].invoke

  # Commit release
  sh "git commit -a -v -e --message='Release #{version_with_prefix}'"

  # Create tag
  sections = File.read("CHANGELOG.md").split(/\n{2,}/)
  section = sections.find { |s| s.start_with?(md_header) }
  section_body = section.sub(md_header, "").strip
  sh "git tag -a -e #{version_tag} -m '#{header}' -m '#{section_body}'"

  puts "Do followings:"
  puts "  $ git checkout release; git merge master"
  puts "  $ git push origin release"
  puts "  $ git push origin master"
  puts "  $ git push origin #{version_tag}"
end

namespace :test do
  Rake::TestTask.new(:all) do |t|
    t.description = "全てのテストを実行する"

    t.test_files = [
      "test/setup",
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
