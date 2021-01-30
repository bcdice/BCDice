# frozen_string_literal: true

require "test/unit"
require "tomlrb"
require "json"
require "bcdice"
require "bcdice/game_system"

require_relative "randomizer_mock"

class TestGameSystemCommands < Test::Unit::TestCase
  class << self
    def target_files
      env_target = ENV["target"]
      unless env_target
        return Dir.glob("test/data/*.toml")
      end

      files = env_target.split(",").map do |target|
        target_with_extension = target.end_with?(".toml") ? target : "#{target}.toml"
        path = "test/data/#{target_with_extension}"

        unless File.exist?(path)
          warn("Unknown target: #{path}")
          next nil
        end

        path
      end

      return files.compact
    end
  end

  data do
    data_set = {}

    files = target_files()
    if files.empty?
      warn("No target found!")
      exit(1)
    end

    files.each do |filename|
      filename_base = File.basename(filename, ".toml")
      data = Tomlrb.load_file(filename, symbolize_keys: true)

      data[:test].each.with_index(1) do |test_case, index|
        test_case[:filename] = filename
        test_case[:output] = nil if test_case[:output].empty? # TOMLではnilを表現できないので空文字で代用
        test_case[:secret] ||= false
        test_case[:success] ||= false
        test_case[:failure] ||= false
        test_case[:critical] ||= false
        test_case[:fumble] ||= false

        key = [filename_base, index, test_case[:input]].join(":")

        data_set[key] = test_case
      end
    end

    data_set
  end
  def test_diceroll(data)
    klass = BCDice.game_system_class(data[:game_system])
    game_system = klass.new(data[:input])

    rands = data[:rands].map { |r| [r[:value], r[:sides]] }
    game_system.randomizer = RandomizerMock.new(rands)

    msg = JSON.pretty_generate(data)

    result = game_system.eval()

    if result.nil?
      assert_nil(data[:output])
      return
    end

    assert_equal(data[:output], result.text, msg)
    assert_equal(data[:secret], result.secret?, msg)
    assert_equal(data[:success], result.success?, msg)
    assert_equal(data[:failure], result.failure?, msg)
    assert_equal(data[:critical], result.critical?, msg)
    assert_equal(data[:fumble], result.fumble?, msg)
  end
end
