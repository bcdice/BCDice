# frozen_string_literal: true

require "test/unit"
require "bcdice"
require "bcdice/dice_table/chain_table"
require "bcdice/dice_table/chain_with_text"
require "bcdice/dice_table/d66_table"

require_relative "randomizer_mock"

class TestChainedResult < Test::Unit::TestCase
  def setup
    @test_sub_table_b = BCDice::DiceTable::Table.new(
      "SubTableB",
      "1D6",
      [
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z",
      ]
    )

    @test_sub_table_a = BCDice::DiceTable::ChainTable.new(
      "SubTableA",
      "1D6",
      [
        "H",
        BCDice::DiceTable::ChainWithText.new("I", @test_sub_table_b),
        "J",
        "K",
        BCDice::DiceTable::ChainWithText.new("L", @test_sub_table_b),
        "M",
      ]
    )

    @test_table = BCDice::DiceTable::ChainTable.new(
      "MainTable",
      "1D6",
      [
        BCDice::DiceTable::ChainWithText.new("A", @test_sub_table_a),
        "B",
        BCDice::DiceTable::ChainWithText.new("C", @test_sub_table_b),
        BCDice::DiceTable::ChainWithText.new("D", @test_sub_table_a),
        "E",
        BCDice::DiceTable::ChainWithText.new("F", @test_sub_table_b),
      ]
    )

    @test_table_d66 = BCDice::DiceTable::D66Table.new(
      "TableD66",
      :asc,
      {
        11 => "あ",
        12 => BCDice::DiceTable::ChainWithText.new("い", @test_sub_table_a),
        13 => "う",
        14 => "え",
        15 => "お",
        16 => "か",
        22 => "き",
        23 => "く",
        24 => "け",
        25 => "こ",
        26 => "さ",
        33 => BCDice::DiceTable::ChainWithText.new("し", @test_sub_table_a),
        34 => "す",
        35 => "せ",
        36 => "そ",
        44 => "た",
        45 => "ち",
        46 => "つ",
        55 => "て",
        56 => BCDice::DiceTable::ChainWithText.new("と", @test_sub_table_b),
        66 => "な",
      }
    )
  end

  def test_not_chain
    randomizer = RandomizerMock.new([[2, 6]])
    assert_equal("MainTable(2) ＞ B", @test_table.roll(randomizer).to_s)
  end

  def test_single_chain_1
    randomizer = RandomizerMock.new([[1, 6], [3, 6]])
    assert_equal("MainTable(1) ＞ A ＞ SubTableA(3) ＞ J", @test_table.roll(randomizer).to_s)
  end

  def test_single_chain_2
    randomizer = RandomizerMock.new([[6, 6], [4, 6]])
    assert_equal("MainTable(6) ＞ F ＞ SubTableB(4) ＞ X", @test_table.roll(randomizer).to_s)
  end

  def test_double_chain
    randomizer = RandomizerMock.new([[4, 6], [2, 6], [3, 6]])
    assert_equal("MainTable(4) ＞ D ＞ SubTableA(2) ＞ I ＞ SubTableB(3) ＞ W", @test_table.roll(randomizer).to_s)
  end

  def test_d66_single_chain_1
    randomizer = RandomizerMock.new([[3, 6], [3, 6], [6, 6]])
    assert_equal("TableD66(33) ＞ し ＞ SubTableA(6) ＞ M", @test_table_d66.roll(randomizer).to_s)
  end

  def test_d66_single_chain_2
    randomizer = RandomizerMock.new([[5, 6], [6, 6], [1, 6]])
    assert_equal("TableD66(56) ＞ と ＞ SubTableB(1) ＞ U", @test_table_d66.roll(randomizer).to_s)
  end

  def test_d66_double_chain
    randomizer = RandomizerMock.new([[1, 6], [2, 6], [5, 6], [2, 6]])
    assert_equal("TableD66(12) ＞ い ＞ SubTableA(5) ＞ L ＞ SubTableB(2) ＞ V", @test_table_d66.roll(randomizer).to_s)
  end
end
