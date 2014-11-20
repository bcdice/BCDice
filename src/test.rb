#--*-coding:utf-8-*--

# ダイスボットのテストを起動するプログラム
# Ruby 1.9 以降に対応

rootDir = File.expand_path(File.dirname(__FILE__))
libPaths = [
  "#{rootDir}/test",
  rootDir,
  "#{rootDir}/irc"
]
libPaths.reverse.each do |libPath|
  $LOAD_PATH.unshift(libPath)
end

require 'DiceBotTest'

# テストを行うゲームシステム
gameType = nil
# テストデータ番号
dataIndex = nil

HELP_MESSAGE = "Usage: #{File.basename($0)} [GAME_TYPE] [DATA_INDEX]"

if ARGV.include?('-h') || ARGV.include?('--help')
  $stdout.puts(HELP_MESSAGE)
  exit
end

case ARGV.length
when 0
when 1
  # ゲームシステムを指定する
  gameType = ARGV[0]
when 2
  # ゲームシステムおよびテストデータ番号を指定する
  gameType = ARGV[0]
  dataIndex = ARGV[1].to_i
else
  $stderr.puts(HELP_MESSAGE)
  abort
end

success = DiceBotTest.new(gameType, dataIndex).execute
abort unless success
