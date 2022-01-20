# frozen_string_literal: true

require "test/unit"
require "bcdice"
require "bcdice/common_command/add_dice/parser"

class AddDiceParserTest < Test::Unit::TestCase
  # ダイスロールのみ
  def test_parse_dice_roll
    test_parse("2D6", "(Command (DiceRoll 2 6))")
  end

  # ダイスロール + 修正値
  def test_parse_modifier
    test_parse("2D6+1", "(Command (+ (DiceRoll 2 6) 1))")
  end

  # 定数畳み込みはしない
  def test_parse_long_modifier
    test_parse("2D6+1-1-2-3-4", "(Command (- (- (- (- (+ (DiceRoll 2 6) 1) 1) 2) 3) 4))")
  end

  # 複数のダイスロール
  def test_parse_multiple_dice_rolls
    test_parse(
      "2D6*3-1D6+1",
      "(Command (+ (- (* (DiceRoll 2 6) 3) (DiceRoll 1 6)) 1))"
    )
  end

  # 面数の省略
  def test_parse_implicit_d
    test_parse("2D", "(Command (ImplicitSidesDiceRoll 2))")
    test_parse("2D+3", "(Command (+ (ImplicitSidesDiceRoll 2) 3))")
  end

  # 最初の空白までがパース対象となる
  def test_parse_only_first_word
    test_parse("2D6 +1", "(Command (DiceRoll 2 6))")
    test_parse("2D6\n+1", "(Command (DiceRoll 2 6))")
  end

  # 除法
  def test_parse_division
    test_parse("5D6/10", "(Command (/ (DiceRoll 5 6) 10))")
    test_parse("5D6+300/10", "(Command (+ (DiceRoll 5 6) (/ 300 10)))")
  end

  # 除法（切り上げ）
  def test_parse_division_with_rounding_up
    test_parse("3D6/2U", "(Command (/U (DiceRoll 3 6) 2))")
    test_parse("3D6-40/2U", "(Command (- (DiceRoll 3 6) (/U 40 2)))")
  end

  # 除法（四捨五入）
  def test_parse_division_with_rounding_off
    test_parse("1D100/10R", "(Command (/R (DiceRoll 1 100) 10))")
    test_parse("1D100*12/10R", "(Command (/R (* (DiceRoll 1 100) 12) 10))")
  end

  # 符号反転（負の整数で割る）
  def test_parse_negation_1
    test_parse("1D6/-3", "(Command (/ (DiceRoll 1 6) (- 3)))")
  end

  # 符号反転（ダイスロールの符号反転）
  def test_parse_negation_2
    test_parse("-1D6+1", "(Command (+ (- (DiceRoll 1 6)) 1))")
  end

  # 二重符号反転（--1）
  def test_parse_double_negation_1
    test_parse("2D6--1", "(Command (+ (DiceRoll 2 6) 1))")
  end

  # 二重符号反転（---1）
  def test_parse_double_negation_2
    test_parse("2D6---1", "(Command (- (DiceRoll 2 6) 1))")
  end

  # カッコ
  def test_parse_parenthesis
    test_parse("(1D6+2D4)*2", "(Command (* (Parenthesis (+ (DiceRoll 1 6) (DiceRoll 2 4))) 2))")
  end

  def test_parse_nested_dice
    assert_not_parse("(1D6)D6", "ダイス数にダイスロールをネストできない")
    assert_not_parse("1D(1D6)", "面数数にダイスロールをネストできない")
  end

  def test_parse_without_dice
    assert_not_parse("1+2", "ダイスロールがない場合にはエラーになる")
  end

  # 目標値あり（=）
  def test_parse_target_value_eq_1
    test_parse("2D6=7", "(Command (== (DiceRoll 2 6) 7))")
  end

  # 目標値あり（===）
  def test_parse_target_value_eq_2
    test_parse("2D6===7", "(Command (== (DiceRoll 2 6) 7))")
  end

  # 目標値あり（<>）
  def test_parse_target_value_not_eq_1
    test_parse("2D6<>7", "(Command (!= (DiceRoll 2 6) 7))")
  end

  # 目標値あり（!=）
  def test_parse_target_value_not_eq_2
    test_parse("2D6!=7", "(Command (!= (DiceRoll 2 6) 7))")
  end

  # 目標値あり（>=）
  def test_parse_target_value_geq_1
    test_parse("2D6>=7", "(Command (>= (DiceRoll 2 6) 7))")
  end

  # 目標値あり（=>）
  def test_parse_target_value_geq_2
    test_parse("2D6=>7", "(Command (>= (DiceRoll 2 6) 7))")
  end

  # 目標値あり（<=）
  def test_parse_target_value_leq
    test_parse("2D6<=7", "(Command (<= (DiceRoll 2 6) 7))")
  end

  # 目標値あり（>）
  def test_parse_target_value_less
    test_parse("2D6>7", "(Command (> (DiceRoll 2 6) 7))")
  end

  # 目標値あり（<）
  def test_parse_target_value_greater
    test_parse("2D6<7", "(Command (< (DiceRoll 2 6) 7))")
  end

  # 目標値に式を書ける
  def test_parse_target_value_expr
    test_parse("2D6>=(5+1)*2", "(Command (>= (DiceRoll 2 6) (* (Parenthesis (+ 5 1)) 2)))")
  end

  def test_parse_question_target
    test_parse("2D6<=?", "(Command (<= (DiceRoll 2 6) ?))")
  end

  def test_parse_empty_target
    assert_not_parse("2D6<", "目標値無しはパースエラーになる")
  end

  def test_parse_invalid_cmp_op
    assert_not_parse("2D6!!10", "不正な比較演算子はパースエラーになる")
  end

  def test_parse_invalid_question_target
    assert_not_parse("2D6<=?a")
  end

  def test_parse_invalid_target
    assert_not_parse("2D6<=12ab")
  end

  def test_parse_dice_target
    assert_not_parse("2D6<=1D6", "目標値にダイスロールを設定できない")
  end

  # 目標値あり、目標値の定数畳み込み
  def test_parse_target_value_constant_fonding
    test_parse(
      "1D6+1-2>=1+2",
      "(Command (>= (- (+ (DiceRoll 1 6) 1) 2) (+ 1 2)))"
    )
  end

  # 大きな出目から複数個取る
  def test_parse_keep_high
    test_parse(
      "5D10KH3",
      "(Command (DiceRollWithFilter 5 10 :KH 3))"
    )
  end

  # 括弧で指定
  def test_parse_keep_high_with_parentheses
    test_parse(
      "(3+2)D(5+5)KH(5-2)",
      "(Command (DiceRollWithFilter (Parenthesis (+ 3 2)) (Parenthesis (+ 5 5)) :KH (Parenthesis (- 5 2))))"
    )
  end

  # 小さな出目から複数個取る
  def test_parse_keep_low
    test_parse(
      "5D10KL3",
      "(Command (DiceRollWithFilter 5 10 :KL 3))"
    )
  end

  # 大きな出目から複数個除く
  def test_parse_drop_high
    test_parse(
      "5D10DH3",
      "(Command (DiceRollWithFilter 5 10 :DH 3))"
    )
  end

  # 小さな出目から複数個除く
  def test_parse_drop_low
    test_parse(
      "5D10DL3",
      "(Command (DiceRollWithFilter 5 10 :DL 3))"
    )
  end

  # 大きな値キープ機能、修正値付き
  def test_parse_keep_high_with_modifier
    test_parse(
      "5D10KH3+1",
      "(Command (+ (DiceRollWithFilter 5 10 :KH 3) 1))"
    )
  end

  # 小さな値キープ機能、修正値付き
  def test_parse_keep_low_with_modifier
    test_parse(
      "5D10KL3+1",
      "(Command (+ (DiceRollWithFilter 5 10 :KL 3) 1))"
    )
  end

  # 大きな値ドロップ機能、修正値付き
  def test_parse_drop_high_with_modifier
    test_parse(
      "5D10DH3+1",
      "(Command (+ (DiceRollWithFilter 5 10 :DH 3) 1))"
    )
  end

  # 小さな値ドロップ機能、修正値付き
  def test_parse_drop_low_with_modifier
    test_parse(
      "5D10DL3+1",
      "(Command (+ (DiceRollWithFilter 5 10 :DL 3) 1))"
    )
  end

  # 最大値抽出（ KH1 の簡易記法）
  def test_parse_max
    test_parse(
      "3D6MAX",
      "(Command (DiceRollWithFilter 3 6 :KH 1))"
    )
  end

  # 最大値抽出、面数省略
  def test_parse_max_implicit_sides
    test_parse(
      "3DMAX",
      "(Command (ImplicitSidesDiceRollWithFilter 3 :KH 1))"
    )
  end

  # 最大値抽出、修正値つき
  def test_parse_max_with_modifier
    test_parse(
      "3D6MAX+2",
      "(Command (+ (DiceRollWithFilter 3 6 :KH 1) 2))"
    )
  end

  # 最小値抽出（ KL1 の簡易記法）
  def test_parse_min
    test_parse(
      "5D10MIN",
      "(Command (DiceRollWithFilter 5 10 :KL 1))"
    )
  end

  # 最小値抽出、面数省略
  def test_parse_min_implicit_sides
    test_parse(
      "5DMIN",
      "(Command (ImplicitSidesDiceRollWithFilter 5 :KL 1))"
    )
  end

  # 最小値抽出、修正値つき
  def test_parse_min_with_modifier
    test_parse(
      "5D10MIN-3",
      "(Command (- (DiceRollWithFilter 5 10 :KL 1) 3))"
    )
  end

  def test_parse_filter_nested_dice
    assert_not_parse("(1D6)D6HK3", "ダイス数にダイスロールをネストできない")
    assert_not_parse("1D(1D6)HK3", "面数数にダイスロールをネストできない")
    assert_not_parse("1D6HK(1D6)", "ダイス保持数にダイスロールをネストできない")
  end

  private

  # 構文解析をテストする
  # @param [String] command テストするコマンド
  # @param [String] expected_s_exp 期待されるS式
  # @return [void]
  def test_parse(command, expected_s_exp)
    node = BCDice::CommonCommand::AddDice::Parser.parse(command)

    assert_equal(expected_s_exp, node.s_exp, "結果の抽象構文木が正しい")
  end

  # @param command [String]
  def assert_not_parse(command, message = nil)
    message = build_message(message, "? are parsed", command)
    assert_block(message) do
      node = BCDice::CommonCommand::AddDice::Parser.parse(command)

      node.nil?
    end
  end
end
