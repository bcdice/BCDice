require 'test/unit'
require 'bcdice'
require 'bcdice/dice_table/d66_table'

class TestD66Table < Test::Unit::TestCase
  def setup
    @randomizer = BCDice::Randomizer.new

    @asc_items = {
      11 => "あ",
      12 => "い",
      13 => "う",
      14 => "え",
      15 => "お",
      16 => "か",
      22 => "き",
      23 => "く",
      24 => "け",
      25 => "こ",
      26 => "さ",
      33 => "し",
      34 => "す",
      35 => "せ",
      36 => "そ",
      44 => "た",
      45 => "ち",
      46 => "つ",
      55 => "て",
      56 => "と",
      66 => "な",
    }

    @desc_items = {
      11 => "に",
      21 => "ぬ",
      22 => "ね",
      31 => "の",
      32 => "は",
      33 => "ひ",
      41 => "ふ",
      42 => "へ",
      43 => "ほ",
      44 => "ま",
      51 => "み",
      52 => "む",
      53 => "め",
      54 => "も",
      55 => "や",
      61 => "ゆ",
      62 => "よ",
      63 => "ら",
      64 => "り",
      65 => "る",
      66 => "れ",
    }
  end

  def test_asc
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :asc,
      @asc_items
    )

    @randomizer.setRandomValues([[1, 6], [6, 6]])
    assert_equal("テスト(16) ＞ か", table.roll(@randomizer))
  end

  def test_asc_swap
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :asc,
      @asc_items
    )

    @randomizer.setRandomValues([[6, 6], [1, 6]])
    assert_equal("テスト(16) ＞ か", table.roll(@randomizer))
  end

  def test_asc_11
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :asc,
      @asc_items
    )

    @randomizer.setRandomValues([[1, 6], [1, 6]])
    assert_equal("テスト(11) ＞ あ", table.roll(@randomizer))
  end

  def test_asc_66
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :asc,
      @asc_items
    )

    @randomizer.setRandomValues([[6, 6], [6, 6]])
    assert_equal("テスト(66) ＞ な", table.roll(@randomizer))
  end

  def test_desc
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :desc,
      @desc_items
    )

    @randomizer.setRandomValues([[6, 6], [1, 6]])
    assert_equal("テスト(61) ＞ ゆ", table.roll(@randomizer))
  end

  def test_desc_swap
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :desc,
      @desc_items
    )

    @randomizer.setRandomValues([[1, 6], [6, 6]])
    assert_equal("テスト(61) ＞ ゆ", table.roll(@randomizer))
  end

  def test_desc_11
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :desc,
      @desc_items
    )

    @randomizer.setRandomValues([[1, 6], [1, 6]])
    assert_equal("テスト(11) ＞ に", table.roll(@randomizer))
  end

  def test_desc_66
    table = BCDice::DiceTable::D66Table.new(
      "テスト",
      :desc,
      @desc_items
    )

    @randomizer.setRandomValues([[6, 6], [6, 6]])
    assert_equal("テスト(66) ＞ れ", table.roll(@randomizer))
  end
end
