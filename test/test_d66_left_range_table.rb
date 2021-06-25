# frozen_string_literal: true

require "test/unit"
require "bcdice"
require "bcdice/dice_table/d66_left_range_table"

require_relative "randomizer_mock"

class TestD66LeftRangeTable < Test::Unit::TestCase
  # 左桁ダイスは範囲指定で見て、右桁ダイスは数値で見る
  def test_range_and_number
    table = BCDice::DiceTable::D66LeftRangeTable.new(
      "テスト",
      BCDice::D66SortType::NO_SORT,
      [
        [
          1..4,
          [
            "A1",
            "A2",
            "A3",
            "A4",
            "A5",
            "A6",
          ],
        ],
        [
          5..6,
          [
            "B1",
            "B2",
            "B3",
            "B4",
            "B5",
            "B6",
          ],
        ],
      ]
    )

    randomizer = RandomizerMock.new([[1, 6], [5, 6]])
    assert_equal("テスト(15) ＞ A5", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[4, 6], [5, 6]])
    assert_equal("テスト(45) ＞ A5", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[3, 6], [1, 6]])
    assert_equal("テスト(31) ＞ A1", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[5, 6], [1, 6]])
    assert_equal("テスト(51) ＞ B1", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[6, 6], [1, 6]])
    assert_equal("テスト(61) ＞ B1", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[6, 6], [3, 6]])
    assert_equal("テスト(63) ＞ B3", table.roll(randomizer).to_s)
  end
end
