# frozen_string_literal: true

require "test/unit"
require "bcdice"
require "bcdice/game_system"

class TestSortKey < Test::Unit::TestCase
  HIRAGANA_BASIC_CHARS = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"

  data do
    BCDice.all_game_systems.map { |s| [s::ID, s::SORT_KEY] }.to_h
  end
  def test_sort_key(sort_key)
    assert_match(
      /\A(?:[#{HIRAGANA_BASIC_CHARS}][\d.A-Za-z#{HIRAGANA_BASIC_CHARS}]*|国際化:[\w ]+:.+|\*たいすほつと)\z/,
      sort_key,
      "SORT_KEY \"#{sort_key}\" はSORT_KEYの規約に違反しています。規約は docs/dicebot_sort_key.md を参照してください"
    )
  end
end
