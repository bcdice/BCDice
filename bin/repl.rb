# frozen_string_literal: true

if ARGV.find_index { |s| s[0] == "-" }
  puts <<~HELP
    repl.rb [GAME_SYSTEM] [OPTIONS]

    Options:
      --help, -h  # Show this message
  HELP

  exit
end

$:.unshift(File.join(__dir__, "../lib"))
require "bcdice/repl"

repl = BCDice::REPL.new()
repl.history_file = File.join(__dir__, "repl_history")
repl.game_system = ARGV[0] if ARGV[0]

repl.run()
