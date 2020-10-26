# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'
require 'bcdice/dice_table/range_table'

module BCDice
  module GameSystem
    class DoubleCross < Base
      # ゲームシステムの識別子
      ID = 'DoubleCross'

      # ゲームシステム名
      NAME = 'ダブルクロス2nd,3rd'

      # ゲームシステム名の読みがな
      SORT_KEY = 'たふるくろす2'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定コマンド（xDX+y@c or xDXc+y）
        　"(個数)DX(修正)@(クリティカル値)" もしくは "(個数)DX(クリティカル値)(修正)" で指定します。
        　修正値も付けられます。
        　例）10dx　　10dx+5@8（OD tool式)　　5DX7+7-3（疾風怒濤式）

        ・各種表
        　・感情表（ET）
        　　ポジティブとネガティブの両方を振って、表になっている側に○を付けて表示します。
        　　もちろん任意で選ぶ部分は変更して構いません。

        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix('\d+DX.*', 'ET')

      # 成功判定コマンドのノード
      class DX
        include Translate

        # ノードを初期化する
        # @param [Integer] num ダイス数
        # @param [Integer] critical_value クリティカル値
        # @param [Integer] modifier 修正値
        # @param [Integer] target_value 目標値
        def initialize(num, critical_value, modifier, target_value)
          @num = num
          @critical_value = critical_value
          @modifier = modifier
          @target_value = target_value

          @modifier_str = Format.modifier(@modifier)
          @expression = node_expression()

          @locale = :ja_jp
        end

        # 成功判定を行う
        # @param randomizer [Randomizer]
        # @return [String] 判定結果
        def execute(randomizer)
          if @critical_value < 2
            return "(#{@expression}) ＞ #{translate('DoubleCross.DX.invalid_critical')}"
          end

          if @num < 1
            return "(#{@expression}) ＞ #{translate('DoubleCross.DX.auto_failure')}"
          end

          # 出目のグループの配列
          value_groups = []
          # 次にダイスロールを行う際のダイス数
          num_of_dice = @num
          # 回転数
          loop_count = 0

          while num_of_dice > 0 && loop_count < CommonCommand::RerollDice::REROLL_LIMIT
            values = randomizer.roll_barabara(num_of_dice, 10)

            value_group = ValueGroup.new(values, @critical_value)
            value_groups.push(value_group)

            # 次回はクリティカル発生数と等しい個数のダイスを振る
            # [3rd ルールブック1 p. 185]
            num_of_dice = value_group.num_of_critical_occurrences

            loop_count += 1
          end

          return result_str(value_groups)
        end

        private

        # 数式表記を返す
        # @return [String]
        def node_expression
          lhs = "#{@num}DX#{@critical_value}#{@modifier_str}"

          return @target_value ? "#{lhs}>=#{@target_value}" : lhs
        end

        # 判定結果の文字列を返す
        # @param [Array<ValueGroup>] value_groups 出目のグループの配列
        # @return [String]
        def result_str(value_groups)
          fumble = value_groups[0].values.all? { |value| value == 1 }
          # TODO: Ruby 2.4以降では Array#sum が使える
          sum = value_groups.map(&:max).reduce(0, &:+)
          achieved_value = fumble ? 0 : (sum + @modifier)

          parts = [
            "(#{@expression})",
            "#{value_groups.join('+')}#{@modifier_str}",
            achieved_value_with_if_fumble(achieved_value, fumble),
            compare_result(achieved_value, fumble)
          ]

          return parts.compact.join(' ＞ ')
        end

        # ファンブルかどうかを含む達成値の表記を返す
        # @param [Integer] achieved_value 達成値
        # @param [Boolean] fumble ファンブルしたか
        # @return [String]
        def achieved_value_with_if_fumble(achieved_value, fumble)
          fumble ? "#{achieved_value} (#{translate('fumble')})" : achieved_value.to_s
        end

        # 達成値と目標値を比較した結果を返す
        # @param [Integer] achieved_value 達成値
        # @param [Boolean] fumble ファンブルしたか
        # @return [String, nil]
        def compare_result(achieved_value, fumble)
          return nil unless @target_value

          # ファンブル時は自動失敗
          # [3rd ルールブック1 pp. 186-187]
          return translate("failure") if fumble

          # 達成値が目標値以上ならば行為判定成功
          # [3rd ルールブック1 p. 187]
          return achieved_value >= @target_value ? translate("success") : translate("failure")
        end
      end

      # 出目のグループを表すクラス
      class ValueGroup
        # 出目の配列
        # @return [Array<Integer>]
        attr_reader :values
        # クリティカル値
        # @return [Integer]
        attr_reader :critical_value

        # 出目のグループを初期化する
        # @param [Array<Integer>] values 出目の配列
        # @param [Integer] critical_value クリティカル値
        def initialize(values, critical_value)
          @values = values.sort
          @critical_value = critical_value
        end

        # 出目のグループの文字列表記を返す
        # @return [String]
        def to_s
          "#{max}[#{@values.join(',')}]"
        end

        # 出目のグループ中の最大値を返す
        # @return [Integer]
        #
        # クリティカル値以上の出目が含まれていた場合は10を返す。
        # [3rd ルールブック1 pp. 185-186]
        def max
          @values.any? { |value| critical?(value) } ? 10 : @values.max
        end

        # クリティカルの発生数を返す
        # @return [Integer]
        def num_of_critical_occurrences
          @values
            .select { |value| critical?(value) }
            .length
        end

        private

        # クリティカルが発生したかを返す
        # @param [Integer] value 出目
        # @return [Boolean]
        #
        # クリティカル値以上の値が出た場合、クリティカルとする。
        # [3rd ルールブック1 pp. 185-186]
        def critical?(value)
          value >= @critical_value
        end
      end

      def check_nD10(total, _dice_total, dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        result =
          if dice_list.count(1) == dice_list.size
            translate("fumble")
          elsif total >= target
            translate("success")
          else
            translate("failure")
          end

        return " ＞ #{result}"
      end

      # ダイスボット固有コマンドの処理を行う
      # @param [String] command コマンド
      # @return [String] ダイスボット固有コマンドの結果
      # @return [nil] 無効なコマンドだった場合
      def eval_game_system_specific_command(command)
        if (dx = parse_dx(command))
          return dx.execute(@randomizer)
        end

        if command == 'ET'
          return roll_emotion_table()
        end

        return nil
      end

      private

      # OD Tool式の成功判定コマンドの正規表現
      #
      # キャプチャ内容は以下のとおり:
      #
      # 1. ダイス数
      # 2. 修正値
      # 3. クリティカル値
      # 4. 達成値
      DX_OD_TOOL_RE = /\A(\d+)DX([-+]\d+(?:[-+*]\d+)*)?@(\d+)(?:>=(\d+))?\z/io.freeze

      # 疾風怒濤式の成功判定コマンドの正規表現
      #
      # キャプチャ内容は以下のとおり:
      #
      # 1. ダイス数
      # 2. クリティカル値
      # 3. 修正値
      # 4. 達成値
      DX_SHIPPU_DOTO_RE = /\A(\d+)DX(\d+)?([-+]\d+(?:[-+*]\d+)*)?(?:>=(\d+))?\z/io.freeze

      # 成功判定コマンドの構文解析を行う
      # @param [String] command コマンド文字列
      # @return [DX, nil]
      def parse_dx(command)
        case command
        when DX_OD_TOOL_RE
          return parse_dx_od(Regexp.last_match)
        when DX_SHIPPU_DOTO_RE
          return parse_dx_shippu_doto(Regexp.last_match)
        end

        return nil
      end

      # OD Tool式の成功判定コマンドの正規表現マッチ情報からノードを作る
      # @param [MatchData] m 正規表現のマッチ情報
      # @return [DX]
      def parse_dx_od(m)
        num = m[1].to_i
        modifier = m[2] ? ArithmeticEvaluator.eval(m[2]) : 0
        critical_value = m[3] ? m[3].to_i : 10

        target_value = m[4]&.to_i

        return self.class::DX.new(num, critical_value, modifier, target_value)
      end

      # 疾風怒濤式の成功判定コマンドの正規表現マッチ情報からノードを作る
      # @param [MatchData] m 正規表現のマッチ情報
      # @return [DX]
      def parse_dx_shippu_doto(m)
        num = m[1].to_i
        critical_value = m[2] ? m[2].to_i : 10
        modifier = m[3] ? ArithmeticEvaluator.eval(m[3]) : 0

        target_value = m[4]&.to_i

        return self.class::DX.new(num, critical_value, modifier, target_value)
      end

      # 感情表を振る
      #
      # ポジティブとネガティブの両方を振って、表になっている側に○を付ける。
      #
      # @return [String]
      def roll_emotion_table
        pos_result = self.class::POSITIVE_EMOTION_TABLE.roll(@randomizer)
        neg_result = self.class::NEGATIVE_EMOTION_TABLE.roll(@randomizer)

        positive = @randomizer.roll_once(2) == 1
        pos_neg_text =
          if positive
            ["○#{pos_result.content}", neg_result.content]
          else
            [pos_result.content, "○#{neg_result.content}"]
          end

        name = translate("DoubleCross.ET.name")
        output_parts = [
          "#{name}(#{pos_result.sum}-#{neg_result.sum})",
          pos_neg_text.join(' - ')
        ]

        return output_parts.join(' ＞ ')
      end

      class << self
        private

        # @param locale [Symbol]
        # @return [RangeTable]
        def positive_emotion_table(locale)
          DiceTable::RangeTable.new(
            I18n.translate("DoubleCross.ET.positive.name", locale: locale),
            "1D100",
            [
              # [0, '傾倒(けいとう)'],
              [1..5,    I18n.translate("DoubleCross.ET.positive.items.1_5", locale: locale)],
              [6..10,   I18n.translate("DoubleCross.ET.positive.items.6_10", locale: locale)],
              [11..15,  I18n.translate("DoubleCross.ET.positive.items.11_15", locale: locale)],
              [16..20,  I18n.translate("DoubleCross.ET.positive.items.16_20", locale: locale)],
              [21..25,  I18n.translate("DoubleCross.ET.positive.items.21_25", locale: locale)],
              [26..30,  I18n.translate("DoubleCross.ET.positive.items.26_30", locale: locale)],
              [31..35,  I18n.translate("DoubleCross.ET.positive.items.31_35", locale: locale)],
              [36..40,  I18n.translate("DoubleCross.ET.positive.items.36_40", locale: locale)],
              [41..45,  I18n.translate("DoubleCross.ET.positive.items.41_45", locale: locale)],
              [46..50,  I18n.translate("DoubleCross.ET.positive.items.46_50", locale: locale)],
              [51..55,  I18n.translate("DoubleCross.ET.positive.items.51_55", locale: locale)],
              [56..60,  I18n.translate("DoubleCross.ET.positive.items.56_60", locale: locale)],
              [61..65,  I18n.translate("DoubleCross.ET.positive.items.61_65", locale: locale)],
              [66..70,  I18n.translate("DoubleCross.ET.positive.items.66_70", locale: locale)],
              [71..75,  I18n.translate("DoubleCross.ET.positive.items.71_75", locale: locale)],
              [76..80,  I18n.translate("DoubleCross.ET.positive.items.76_80", locale: locale)],
              [81..85,  I18n.translate("DoubleCross.ET.positive.items.81_85", locale: locale)],
              [86..90,  I18n.translate("DoubleCross.ET.positive.items.86_90", locale: locale)],
              [91..95,  I18n.translate("DoubleCross.ET.positive.items.91_95", locale: locale)],
              [96..100, I18n.translate("DoubleCross.ET.positive.items.96_100", locale: locale)],
              # [101, '懐旧(かいきゅう)'],
              # [102, '任意(にんい)'],
            ]
          )
        end

        # @param locale [Symbol]
        # @return [RangeTable]
        def negative_emotion_table(locale)
          DiceTable::RangeTable.new(
            I18n.translate("DoubleCross.ET.negative.name", locale: locale),
            "1D100",
            [
              # [0, '侮蔑(ぶべつ)'],
              [1..5,    I18n.translate("DoubleCross.ET.negative.items.1_5", locale: locale)],
              [6..10,   I18n.translate("DoubleCross.ET.negative.items.6_10", locale: locale)],
              [11..15,  I18n.translate("DoubleCross.ET.negative.items.11_15", locale: locale)],
              [16..20,  I18n.translate("DoubleCross.ET.negative.items.16_20", locale: locale)],
              [21..25,  I18n.translate("DoubleCross.ET.negative.items.21_25", locale: locale)],
              [26..30,  I18n.translate("DoubleCross.ET.negative.items.26_30", locale: locale)],
              [31..35,  I18n.translate("DoubleCross.ET.negative.items.31_35", locale: locale)],
              [36..40,  I18n.translate("DoubleCross.ET.negative.items.36_40", locale: locale)],
              [41..45,  I18n.translate("DoubleCross.ET.negative.items.41_45", locale: locale)],
              [46..50,  I18n.translate("DoubleCross.ET.negative.items.46_50", locale: locale)],
              [51..55,  I18n.translate("DoubleCross.ET.negative.items.51_55", locale: locale)],
              [56..60,  I18n.translate("DoubleCross.ET.negative.items.56_60", locale: locale)],
              [61..65,  I18n.translate("DoubleCross.ET.negative.items.61_65", locale: locale)],
              [66..70,  I18n.translate("DoubleCross.ET.negative.items.66_70", locale: locale)],
              [71..75,  I18n.translate("DoubleCross.ET.negative.items.71_75", locale: locale)],
              [76..80,  I18n.translate("DoubleCross.ET.negative.items.76_80", locale: locale)],
              [81..85,  I18n.translate("DoubleCross.ET.negative.items.81_85", locale: locale)],
              [86..90,  I18n.translate("DoubleCross.ET.negative.items.86_90", locale: locale)],
              [91..95,  I18n.translate("DoubleCross.ET.negative.items.91_95", locale: locale)],
              [96..100, I18n.translate("DoubleCross.ET.negative.items.96_100", locale: locale)],
              # [101, '無関心(むかんしん)'],
              # [102, '任意(にんい)'],
            ]
          ).freeze
        end
      end

      # 感情表（ポジティブ）
      POSITIVE_EMOTION_TABLE = positive_emotion_table(:ja_jp).freeze

      # 感情表（ネガティブ）
      NEGATIVE_EMOTION_TABLE = negative_emotion_table(:ja_jp).freeze
    end
  end
end
