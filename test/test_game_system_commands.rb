# frozen_string_literal: true

require "test/unit"
require "tomlrb"
require "json"
require "bcdice"
require "bcdice/game_system"

class TestGameSystemCommands < Test::Unit::TestCase
  data do
    data_set = {}
    files = Dir.glob("test/data/*.toml")

    files.each do |filename|
      filename_base = File.basename(filename, ".toml")
      data = Tomlrb.load_file(filename, symbolize_keys: true)

      data[:test].each.with_index(1) do |test_case, index|
        test_case[:filename] = filename
        key = [filename_base, index, test_case[:input]].join(":")

        data_set[key] = test_case
      end
    end

    data_set
  end
  def test_diceroll(data)
    klass = BCDice.game_system_class(data[:game_system])
    game_system = klass.new

    rands = data[:rands].map { |r| [r[:value], r[:sides]] }
    game_system.randomizer.setRandomValues(rands)

    msg = JSON.pretty_generate(data)

    assert_equal(data[:output], game_system.eval(data[:input]), msg)
    assert_equal(data[:secret] || false, game_system.secret?, msg)
  end
end
