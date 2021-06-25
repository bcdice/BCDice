# frozen_string_literal: true

require "test/unit"
require "bcdice"
require "bcdice/dice_table/parity_table"

require_relative "randomizer_mock"

class TestParityTable < Test::Unit::TestCase
  # ダイス目の偶奇のみを見る
  def test_parity
    table = BCDice::DiceTable::ParityTable.new(
      "テスト",
      "1D6",
      "odd",
      "even"
    )

    randomizer = RandomizerMock.new([[1, 6]])
    assert_equal("テスト(1) ＞ odd", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[2, 6]])
    assert_equal("テスト(2) ＞ even", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[3, 6]])
    assert_equal("テスト(3) ＞ odd", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[4, 6]])
    assert_equal("テスト(4) ＞ even", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[5, 6]])
    assert_equal("テスト(5) ＞ odd", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[6, 6]])
    assert_equal("テスト(6) ＞ even", table.roll(randomizer).to_s)
  end
end
