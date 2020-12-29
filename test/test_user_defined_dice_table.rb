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
      3-4テスト表
      3D4
      3:さん
      4:し
      5:ご
      6:ろく
      7:なな
      8:はち
      9:きゅう
      10:じゅう
      11:じゅういち
      12:じゅうに
    TEXT

    @text_d66 = <<~TEXT
      ソートなし表
      D66
      11:a
      12:a
      13:a
      14:a
      15:a
      16:いちろく
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
      61:ろくいち
      62:a
      63:a
      64:a
      65:a
      66:a
    TEXT

    @text_d66a = <<~TEXT
      ソート昇順表
      D66a
      11:a
      12:a
      13:a
      14:a
      15:a
      16:いちろく
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

    @text_d66d = <<~TEXT
      ソート降順表
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
      61:ろくいち
      62:a
      63:a
      64:a
      65:a
      66:a
    TEXT
  end

  def test_1d6_1
    table = BCDice::UserDefinedDiceTable.new(@text_1d6)
    result = table.roll(randomizer: RandomizerMock.new([[1, 6]]))

    assert_equal("テスト表(1) ＞ いち", result.text)
  end

  def test_1d6_6
    table = BCDice::UserDefinedDiceTable.new(@text_1d6)
    result = table.roll(randomizer: RandomizerMock.new([[6, 6]]))

    assert_equal("テスト表(6) ＞ ろく", result.text)
  end

  def test_3d4_3
    table = BCDice::UserDefinedDiceTable.new(@text_3d4)
    result = table.roll(randomizer: RandomizerMock.new([[1, 4], [1, 4], [1, 4]]))

    assert_equal("3-4テスト表(3) ＞ さん", result.text)
  end

  def test_3d4_12
    table = BCDice::UserDefinedDiceTable.new(@text_3d4)
    result = table.roll(randomizer: RandomizerMock.new([[4, 4], [4, 4], [4, 4]]))

    assert_equal("3-4テスト表(12) ＞ じゅうに", result.text)
  end

  def test_d66_16
    table = BCDice::UserDefinedDiceTable.new(@text_d66)
    result = table.roll(randomizer: RandomizerMock.new([[1, 6], [6, 6]]))

    assert_equal("ソートなし表(16) ＞ いちろく", result.text)
  end

  def test_d66_61
    table = BCDice::UserDefinedDiceTable.new(@text_d66)
    result = table.roll(randomizer: RandomizerMock.new([[6, 6], [1, 6]]))

    assert_equal("ソートなし表(61) ＞ ろくいち", result.text)
  end

  def test_d66a_16
    table = BCDice::UserDefinedDiceTable.new(@text_d66a)
    result = table.roll(randomizer: RandomizerMock.new([[1, 6], [6, 6]]))

    assert_equal("ソート昇順表(16) ＞ いちろく", result.text)
  end

  def test_d66a_61
    table = BCDice::UserDefinedDiceTable.new(@text_d66a)
    result = table.roll(randomizer: RandomizerMock.new([[6, 6], [1, 6]]))

    assert_equal("ソート昇順表(16) ＞ いちろく", result.text)
  end

  def test_d66d_16
    table = BCDice::UserDefinedDiceTable.new(@text_d66d)
    result = table.roll(randomizer: RandomizerMock.new([[1, 6], [6, 6]]))

    assert_equal("ソート降順表(61) ＞ ろくいち", result.text)
  end

  def test_d66d_61
    table = BCDice::UserDefinedDiceTable.new(@text_d66d)
    result = table.roll(randomizer: RandomizerMock.new([[6, 6], [1, 6]]))

    assert_equal("ソート降順表(61) ＞ ろくいち", result.text)
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
    table = BCDice::UserDefinedDiceTable.new(@text_d66)
    assert(table.valid?)
  end

  def test_verify_d66a
    table = BCDice::UserDefinedDiceTable.new(@text_d66a)
    assert(table.valid?)
  end

  def test_verify_d66d
    table = BCDice::UserDefinedDiceTable.new(@text_d66d)
    assert(table.valid?)
  end

  def test_verify_3d4_miss_rows
    text = <<~TEXT
      抜けありテスト表
      3D4
      3:さん
      4:し
      5:ご
      6:ろく
      12:じゅうに
    TEXT

    table = BCDice::UserDefinedDiceTable.new(text)
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

  def test_invalid_d66
    # 表の中身がD66aの物になっている
    text = <<~TEXT
      フォーマット確認(D66)
      D66
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
    assert_false(table.valid?)
  end

  def test_invalid_d66a
    # 表の中身がD66dの物になっている
    text = <<~TEXT
      フォーマット確認(D66d)
      D66a
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
    assert_false(table.valid?)
  end

  def test_invalid_d66d
    # 表の中身がD66aの物になっている
    text = <<~TEXT
      フォーマット確認(D66d)
      D66d
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
    assert_false(table.valid?)
  end
end
