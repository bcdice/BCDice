require "test/unit"
require "bcdice"
require "bcdice/user_defined_dice_table"
require_relative "randomizer_mock"

class TestUserDefinedDiceTable < Test::Unit::TestCase
  def setup
    @text_1d6 = <<~TEXT
      テスト表
      1D6
      1:いち
      2:に
      3:さん
      4:し
      5:ご
      6:ろく
    TEXT

    @text_3d4 = <<~TEXT
      抜けありテスト表
      3D4
      3:さん
      4:し
      5:ご
      6:ろく
      12:じゅうに
    TEXT

    @text_d66 = <<~TEXT
      ソートなし表
      D66
      16:いちろく
      61:ろくいち
    TEXT

    @text_d66a = <<~TEXT
      ソート昇順表
      D66a
      16:いちろく
    TEXT

    @text_d66d = <<~TEXT
      ソート降順表
      D66d
      61:ろくいち
    TEXT
  end

  def test_1d6_1
    table = BCDice::UserDefinedDiceTable.new(@text_1d6)
    table.randomizer = RandomizerMock.new([[1, 6]])

    assert_equal("テスト表(1) ＞ いち", table.roll())
  end

  def test_1d6_6
    table = BCDice::UserDefinedDiceTable.new(@text_1d6)
    table.randomizer = RandomizerMock.new([[6, 6]])

    assert_equal("テスト表(6) ＞ ろく", table.roll())
  end

  def test_3d4_3
    table = BCDice::UserDefinedDiceTable.new(@text_3d4)
    table.randomizer = RandomizerMock.new([[1, 4], [1, 4], [1, 4]])

    assert_equal("抜けありテスト表(3) ＞ さん", table.roll())
  end

  def test_3d4_12
    table = BCDice::UserDefinedDiceTable.new(@text_3d4)
    table.randomizer = RandomizerMock.new([[4, 4], [4, 4], [4, 4]])

    assert_equal("抜けありテスト表(12) ＞ じゅうに", table.roll())
  end

  def test_notcontain
    table = BCDice::UserDefinedDiceTable.new(@text_3d4)
    table.randomizer = RandomizerMock.new([[4, 4], [4, 4], [3, 4]])

    assert_nil(table.roll())
  end

  def test_d66_16
    table = BCDice::UserDefinedDiceTable.new(@text_d66)
    table.randomizer = RandomizerMock.new([[1, 6], [6, 6]])

    assert_equal("ソートなし表(16) ＞ いちろく", table.roll())
  end

  def test_d66_61
    table = BCDice::UserDefinedDiceTable.new(@text_d66)
    table.randomizer = RandomizerMock.new([[6, 6], [1, 6]])

    assert_equal("ソートなし表(61) ＞ ろくいち", table.roll())
  end

  def test_d66a_16
    table = BCDice::UserDefinedDiceTable.new(@text_d66a)
    table.randomizer = RandomizerMock.new([[1, 6], [6, 6]])

    assert_equal("ソート昇順表(16) ＞ いちろく", table.roll())
  end

  def test_d66a_61
    table = BCDice::UserDefinedDiceTable.new(@text_d66a)
    table.randomizer = RandomizerMock.new([[6, 6], [1, 6]])

    assert_equal("ソート昇順表(16) ＞ いちろく", table.roll())
  end

  def test_d66d_16
    table = BCDice::UserDefinedDiceTable.new(@text_d66d)
    table.randomizer = RandomizerMock.new([[1, 6], [6, 6]])

    assert_equal("ソート降順表(61) ＞ ろくいち", table.roll())
  end

  def test_d66d_61
    table = BCDice::UserDefinedDiceTable.new(@text_d66d)
    table.randomizer = RandomizerMock.new([[6, 6], [1, 6]])

    assert_equal("ソート降順表(61) ＞ ろくいち", table.roll())
  end

  def invalid_dice_type
    text = <<~TEXT
      不正な表
      D100
      100:ひゃく
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert_nil(table.roll())
  end

  def test_verify_1d6
    table = BCDice::UserDefinedDiceTable.new(@text_1d6)
    assert(table.valid?)
  end

  def test_verify_d66
    text = <<~TEXT
      フォーマット確認(D66)
      D66
      11:a
      12:a
      13:a
      14:a
      15:a
      16:a
      21:a
      22:a
      23:a
      24:a
      25:a
      26:a
      31:a
      32:a
      33:a
      34:a
      35:a
      36:a
      41:a
      42:a
      43:a
      44:a
      45:a
      46:a
      51:a
      52:a
      53:a
      54:a
      55:a
      56:a
      61:a
      62:a
      63:a
      64:a
      65:a
      66:a
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert(table.valid?)
  end

  def test_verify_d66a
    text = <<~TEXT
      フォーマット確認(D66a)
      D66a
      11:a
      12:a
      13:a
      14:a
      15:a
      16:a
      22:a
      23:a
      24:a
      25:a
      26:a
      33:a
      34:a
      35:a
      36:a
      44:a
      45:a
      46:a
      55:a
      56:a
      66:a
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert(table.valid?)
  end

  def test_verify_d66d
    text = <<~TEXT
      フォーマット確認(D66d)
      D66d
      11:a
      21:a
      22:a
      31:a
      32:a
      33:a
      41:a
      42:a
      43:a
      44:a
      51:a
      52:a
      53:a
      54:a
      55:a
      61:a
      62:a
      63:a
      64:a
      65:a
      66:a
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert(table.valid?)
  end

  def test_verify_3d4_miss_rows
    table = BCDice::UserDefinedDiceTable.new(@text_3d4)
    assert_false(table.valid?)
  end

  def test_verify_invalid_dice_type
    text = <<~TEXT
      不正な表
      D100
      100:ひゃく
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert_false(table.valid?)
  end

  def test_verify_dup_rows
    text = <<~TEXT
      重複あり表
      2D4
      2:a
      2:b
      4:c
      5:d
      6:e
      7:f
      8:g
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert_false(table.valid?)
  end

  def test_verify_outrange_row
    text = <<~TEXT
      範囲外表
      1D4
      1:a
      2:b
      3:c
      5:d
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
    assert_false(table.valid?)
  end
end
