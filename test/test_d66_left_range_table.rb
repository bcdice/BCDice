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

  def test_valid_conv_string_range_should_be_accepted
    assert_equal(
      Range.new(1, 3),
      BCDice::DiceTable::D66LeftRangeTable.conv_string_range("1..3")
    )
  end

  def test_invalid_conv_string_range_should_be_denied
    assert_raise(ArgumentError) do
      BCDice::DiceTable::D66LeftRangeTable.conv_string_range("1")
    end
    assert_raise(ArgumentError) do
      BCDice::DiceTable::D66LeftRangeTable.conv_string_range("2..X")
    end
    assert_raise(ArgumentError) do
      BCDice::DiceTable::D66LeftRangeTable.conv_string_range("hoge")
    end
    assert_raise(ArgumentError) do
      BCDice::DiceTable::D66LeftRangeTable.conv_string_range([])
    end
  end

  class TestD66LeftRangeTableI18n < Test::Unit::TestCase
    setup do
      data = {
        dummy: {
          RT: {
            name: "Table",
            d66_sort_type: "asc",
            items: [
              ["1..3", ["A", "B", "C", "D", "E", "F"]],
              ["3..6", ["a", "b", "c", "d", "e", "f"]],
            ]
          },
          InvalidRT: {
            name: "Invalid Table",
            d66_sort_type: "asc",
            items: [
              ["1", ["A", "B", "C", "D", "E", "F"]],
              ["2..6", ["a", "b", "c", "d", "e", "f"]],
            ]
          }
        }
      }
      I18n.backend.store_translations(:ja_jp, data)
    end

    teardown do
      I18n.backend.reload!
    end

    def test_valid_range_table_from_i18n_should_be_accepted
      assert_nothing_raised do
        BCDice::DiceTable::D66LeftRangeTable.from_i18n("dummy.RT", :ja_jp)
      end
    end

    def test_invalid_range_table_from_i18n_should_be_denied
      assert_raise(ArgumentError) do
        BCDice::DiceTable::D66LeftRangeTable.from_i18n("dummy.InvalidRT", :ja_jp)
      end
    end
  end
end
