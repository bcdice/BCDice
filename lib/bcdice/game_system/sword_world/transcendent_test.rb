module BCDice
  module GameSystem
    class SwordWorld2_0 < SwordWorld
      # 超越判定のノード
      class TranscendentTest
        # @param [Integer] critical_value クリティカル値
        # @param [Integer] modifier 修正値
        # @param [String, nil] cmp_op 比較演算子（> または >=）
        # @param [Integer, nil] target 目標値
        def initialize(critical_value, modifier, cmp_op, target)
          @critical_value = critical_value
          @modifier = modifier
          @cmp_op = cmp_op
          @target = target

          @modifier_str = Format.modifier(@modifier)
          @expression = node_expression()
        end

        # 超越判定を行う
        # @param randomizer [Randomizer]
        # @return [String]
        def execute(randomizer)
          if @critical_value < 3
            return "(#{@expression}) ＞ クリティカル値が小さすぎます。3以上を指定してください。"
          end

          first_value_group = randomizer.roll_barabara(2, 6)
          value_groups = [first_value_group]

          fumble = first_value_group == [1, 1]
          critical = first_value_group == [6, 6]

          if !fumble && !critical
            while sum_of_dice(value_groups.last) >= @critical_value
              value_groups.push(randomizer.roll_barabara(2, 6))
            end
          end

          sum = sum_of_dice(value_groups)
          total_sum = sum + @modifier

          parts = [
            "(#{@expression})",
            "#{dice_str(value_groups, sum)}#{@modifier_str}",
            total_sum,
            @target && result_str(total_sum, value_groups.length, fumble, critical)
          ].compact

          return parts.join(" ＞ ")
        end

        private

        # 数式表記を返す
        # @return [String]
        def node_expression
          lhs = "2D6@#{@critical_value}#{@modifier_str}"

          return @target ? "#{lhs}#{@cmp_op}#{@target}" : lhs
        end

        # 出目の合計を返す
        # @param [(Integer, Integer), Array<(Integer, Integer)>] value_groups
        #   出目のグループまたはその配列
        # @return [Integer]
        def sum_of_dice(value_groups)
          value_groups.flatten.sum
        end

        # ダイス部分の文字列を返す
        # @param [Array<(Integer, Integer)>] value_groups 出目のグループの配列
        # @param [Integer] sum 出目の合計
        # @return [String]
        def dice_str(value_groups, sum)
          value_groups_str =
            value_groups
            .map { |values| "[#{values.join(',')}]" }
            .join

          return "#{sum}#{value_groups_str}"
        end

        # 判定結果の文字列を返す
        # @param [Integer] total_sum 合計値
        # @param [Integer] n_value_groups 出目のグループの数
        # @param [Boolean] fumble ファンブルかどうか
        # @param [Boolean] critical クリティカルかどうか
        # @return [String]
        def result_str(total_sum, n_value_groups, fumble, critical)
          return "自動的失敗" if fumble
          return "自動的成功" if critical

          if total_sum.send(@cmp_op, @target)
            # 振り足しが行われ、合計値が41以上ならば「超成功」
            n_value_groups >= 2 && total_sum >= 41 ? "超成功" : "成功"
          else
            "失敗"
          end
        end
      end
    end
  end
end
