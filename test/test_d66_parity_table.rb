require "test/unit"
require "bcdice"
require "bcdice/dice_table/d66_parity_table"

require_relative "randomizer_mock"

class TestD66ParityTable < Test::Unit::TestCase
  # 左桁ダイスは偶奇のみ見て、右桁ダイスは数値で見る
  def test_parity_and_number
    table = BCDice::DiceTable::D66ParityTable.new(
      "テスト",
      [
        "o-1",
        "o-2",
        "o-3",
        "o-4",
        "o-5",
        "o-6",
      ],
      [
        "e-1",
        "e-2",
        "e-3",
        "e-4",
        "e-5",
        "e-6",
      ]
    )

    randomizer = RandomizerMock.new([[3, 6], [5, 6]])
    assert_equal("テスト(35) ＞ o-5", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[5, 6], [4, 6]])
    assert_equal("テスト(54) ＞ o-4", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[2, 6], [1, 6]])
    assert_equal("テスト(21) ＞ e-1", table.roll(randomizer).to_s)

    randomizer = RandomizerMock.new([[4, 6], [6, 6]])
    assert_equal("テスト(46) ＞ e-6", table.roll(randomizer).to_s)
  end
end
