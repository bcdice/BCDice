# ダイスボットのテストを起動するプログラム

$:.unshift(File.join(__dir__, "../lib"))
$:.unshift(File.join(__dir__, "../test"))

require "DiceBotTest"

HELP_MESSAGE = <<~HELP.freeze
  Usage: #{File.basename($0)} test_file [index]
    特定のゲームシステムのテストを実行する

    test_file  テストファイルのパス
    index      実行したいテストケースの番号
HELP

if ARGV.include?("-h") || ARGV.include?("--help") || ARGV.empty?
  puts HELP_MESSAGE
  exit
end

if ARGV.length > 2
  warn HELP_MESSAGE
  exit 1
end

test_data_path = ARGV[0].end_with?(".txt") ? ARGV[0] : File.join(__dir__, "../test/data/#{ARGV[0]}.txt")
data_index = ARGV[1]&.to_i

success = DiceBotTest.new(test_data_path, data_index).execute
unless success
  exit 1
end
