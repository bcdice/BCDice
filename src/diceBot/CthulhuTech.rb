# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'diceBot/DiceBot'
require 'utils/modifier_formatter'
require 'utils/ArithmeticEvaluator'

# クトゥルフテックのダイスボット
class CthulhuTech < DiceBot
  setPrefixes(['\d+D10.*'])

  # ゲームシステムの識別子
  ID = 'CthulhuTech'

  # ゲームシステム名
  NAME = 'クトゥルフテック'

  # ゲームシステム名の読みがな
  SORT_KEY = 'くとうるふてつく'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・行為判定（test）：nD10+m>=d
　n個のダイスを使用して、修正値m、難易度dで行為判定（test）を行います。
　修正値mは省略可能、複数指定可能（例：+2-4）です。
　成功、失敗、クリティカル、ファンブルを自動判定します。
　例）2D10>=12　4D10+2>=28　5D10+2-4>=32

・対抗判定（contest）：nD10+m>d
　行為判定と同様ですが、防御側有利のため「>=」ではなく「>」を入力します。
　ダメージダイスも表示します。
INFO_MESSAGE_TEXT

  # 比較処理のノード（行為判定、対抗判定の基底クラス）
  class Compare
    # 判定値と難易度の比較結果
    # @!attribute diff
    #   @return [Integer] 判定値と難易度の差
    # @!attribute success
    #   @return [Boolean] 成功したかどうか
    # @!attribute fumble
    #   @return [Boolean] ファンブルかどうか
    # @!attribute critical
    #   @return [Boolean] クリティカルかどうか
    Result = Struct.new(:diff, :success, :fumble, :critical)

    include ModifierFormatter

    # ダイス数
    # @return [Integer]
    attr_reader :num
    # 修正値
    # @return [Integer]
    attr_reader :modifier

    # ノードを初期化する
    # @param [Integer] num ダイス数
    # @param [Integer] modifier 修正値
    # @param [Symbol] cmp_op 比較演算子（ +:>=+, +:>+ ）
    # @param [Integer] difficulty 難易度
    def initialize(num, modifier, cmp_op, difficulty)
      @num = num
      @modifier = modifier
      @cmp_op = cmp_op
      @difficulty = difficulty
    end

    # 比較の数式表現を返す
    # @return [String]
    def expression
      modifier_str = format_modifier(@modifier)
      return "#{@num}D10#{modifier_str}#{@cmp_op}#{@difficulty}"
    end

    # 比較を行う
    # @param [TestResult] test_result 判定値
    # @return [Compare::Result]
    def compare(test_result)
      diff = test_result.value - @difficulty

      # 成功したかどうか
      # 例：@cmp_op が :> ならば、diff.send(@cmp_op, 0) は diff > 0 と同じ
      success = !test_result.fumble && diff.send(@cmp_op, 0)

      critical = diff >= 10

      return Result.new(diff, success, test_result.fumble, critical)
    end

    # 比較結果を整形する
    # @param [Compare::Result] result 比較結果
    # @return [String]
    def format_compare_result(result)
      return 'ファンブル' if result.fumble
      return 'クリティカル' if result.critical

      return result.success ? '成功' : '失敗'
    end
  end

  # 行為判定のノード
  class Test < Compare
    # ノードを初期化する
    # @param [Integer] num ダイス数
    # @param [Integer] modifier 修正値
    # @param [Integer] difficulty 難易度
    def initialize(num, modifier, difficulty)
      super(num, modifier, :>=, difficulty)
    end
  end

  # 対抗判定のノード
  class Contest < Compare
    # ノードを初期化する
    # @param [Integer] num ダイス数
    # @param [Integer] modifier 修正値
    # @param [Integer] difficulty 難易度
    def initialize(num, modifier, difficulty)
      super(num, modifier, :>, difficulty)
    end

    # 比較結果を整形する
    #
    # 成功した場合（クリティカルを含む）、ダメージロールのコマンドを末尾に
    # 追加する。
    #
    # @param [Compare::Result] result 比較結果
    # @return [String]
    def format_compare_result(result)
      formatted = super(result)

      if result.success
        damage_roll_num = (result.diff / 5.0).ceil
        damage_roll = "#{damage_roll_num}D10"

        "#{formatted}（ダメージ：#{damage_roll}）"
      else
        formatted
      end
    end
  end

  # 判定値のクラス
  class TestResult
    include ModifierFormatter

    # 計算された判定値（ダイスロール結果 + 修正値）
    # @return [Integer]
    attr_reader :value

    # ファンブルかどうか
    # @return [Boolean]
    attr_reader :fumble

    # 値を初期化し、計算を行う
    # @param [Array<Integer>] dice_values 出目の配列
    # @param [Integer] modifier 修正値
    def initialize(dice_values, modifier)
      @dice_values = dice_values.sort
      @modifier = modifier

      # ファンブル：出目の半分（小数点以下切り上げ）以上が1の場合
      @fumble = @dice_values.count(1) >= (@dice_values.length + 1) / 2

      @roll_result = calculate_roll_result(@dice_values)
      @value = @roll_result + @modifier
    end

    # 数式表現を返す
    # @return [String]
    def expression
      dice_str = @dice_values.join(',')
      modifier_str = format_modifier(@modifier)

      return "#{@roll_result}[#{dice_str}]#{modifier_str}"
    end

    private

    # ダイスロール結果を計算する
    #
    # 以下のうち最大のものを返す。
    #
    # * 出目の最大値
    # * ゾロ目の和の最大値
    # * ストレート（昇順で連続する3個以上の値）の和の最大値
    #
    # @param [Array<Integer>] sorted_values 昇順でソートされた出目の配列
    # @return [Integer]
    def calculate_roll_result(sorted_values)
      highest_single_roll = sorted_values.last

      candidates = [
        highest_single_roll,
        sum_of_highest_set_of_multiples(sorted_values),
        sum_of_largest_straight(sorted_values)
      ]

      return candidates.max
    end

    # ゾロ目の和の最大値を求める
    # @param [Array<Integer>] values 出目の配列
    # @return [Integer]
    def sum_of_highest_set_of_multiples(values)
      values.
        # TODO: Ruby 2.2以降では group_by(&:itself) が使える
        group_by { |i| i }.
        # TODO: Ruby 2.4以降では value_group.sum が使える
        map { |_, value_group| value_group.reduce(0, &:+) }.
        max
    end

    # ストレートの和の最大値を求める
    #
    # ストレートとは、昇順で3個以上連続した値のこと。
    #
    # @param [Array<Integer>] sorted_values 昇順にソートされた出目の配列
    # @return [Integer] ストレートの和の最大値
    # @return [0] ストレートが存在しなかった場合
    def sum_of_largest_straight(sorted_values)
      # 出目が3個未満ならば、ストレートは存在しない
      return 0 if sorted_values.length < 3

      # ストレートの和の最大値
      max_sum = 0

      # 連続した値の数
      n_consecutive_values = 0
      # 連続した値の和
      sum = 0
      # 直前の値
      # 初期値を負の値にして、最初の値と連続にならないようにする
      last = -1

      sorted_values.uniq.each do |value|
        # 値が連続でなければ、状態を初期化する（現在の値を連続1個目とする）
        if value - last > 1
          n_consecutive_values = 1
          sum = value
          last = value

          next
        end

        # 連続した値なので溜める
        n_consecutive_values += 1
        sum += value
        last = value

        # ストレートならば、和の最大値を更新する
        if n_consecutive_values >= 3 && sum > max_sum
          max_sum = sum
        end
      end

      return max_sum
    end
  end

  # ダイスボットを初期化する
  def initialize
    super

    # 加算ロールで出目をソートする
    @sortType = 1
  end

  # ダイスボット固有コマンドの処理を行う
  # @param [String] command コマンド
  # @return [String] ダイスボット固有コマンドの結果
  # @return [nil] 無効なコマンドだった場合
  def rollDiceCommand(command)
    node = parse(command)
    return nil unless node

    return execute(node)
  end

  private

  # 判定コマンドの正規表現
  TEST_RE = /\A(\d+)D10((?:[-+]\d+)+)?(>=?)(\d+)\z/.freeze

  # 構文解析する
  # @param [String] command コマンド
  # @return [Test, Contest] 判定のノード
  # @return [nil] 無効なコマンドだった場合
  def parse(command)
    m = TEST_RE.match(command)
    return nil unless m

    num = m[1].to_i
    modifier = m[2] ? ArithmeticEvaluator.new.eval(m[2]) : 0
    node_class = m[3] == '>' ? Contest : Test
    difficulty = m[4].to_i

    return node_class.new(num, modifier, difficulty)
  end

  # 判定を行う
  # @param [Test, Contest] test 判定のノード
  # @return [String]
  def execute(test)
    dice_values = Array.new(test.num) { roll(1, 10)[0] }
    test_result = TestResult.new(dice_values, test.modifier)
    compare_result = test.compare(test_result)

    output_parts = [
      "(#{test.expression})",
      test_result.expression,
      test_result.value,
      test.format_compare_result(compare_result)
    ]

    return output_parts.join(' ＞ ')
  end
end
