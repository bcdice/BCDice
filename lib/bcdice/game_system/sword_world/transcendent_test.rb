# frozen_string_literal: true

require "bcdice/result"
require "bcdice/translate"

module BCDice
  module GameSystem
    class SwordWorld2_0 < SwordWorld
      # 超越判定のノード
      class TranscendentTest
        include Translate

        # @param [Integer] critical_value クリティカル値
        # @param [Integer] modifier 修正値
        # @param [String, nil] cmp_op 比較演算子（> または >=）
        # @param [Integer, nil] target 目標値
        def initialize(critical_value, modifier, cmp_op, target, locale)
          @critical_value = critical_value
          @modifier = modifier
          @cmp_op = cmp_op
          @target = target
          @locale = locale

          @modifier_str = Format.modifier(@modifier)
          @expression = node_expression()
        end

        # 超越判定を行う
        # @param randomizer [Randomizer]
        # @return [String]
        def execute(randomizer)
          if @critical_value < 3
            return translate("SwordWorld2_0.transcendent_critical_too_small", expression: @expression)
          end

          first_value_group = randomizer.roll_barabara(2, 6)
          value_groups = [first_value_group]

          fumble = first_value_group == [1, 1]
          critical = first_value_group == [6, 6]

          unless fumble
            while sum_of_dice(value_groups.last) >= @critical_value
              value_groups.push(randomizer.roll_barabara(2, 6))
            end
          end

          sum = sum_of_dice(value_groups)
          total_sum = sum + @modifier

          result = result_status(total_sum, value_groups.length, fumble, critical)
          result_str = {
            success: translate("success"),
            failure: translate("failure"),
            super_success: translate("SwordWorld2_0.super_success"),
            critical: translate("SwordWorld.critical"),
            fumble: translate("SwordWorld.fumble"),
          }.freeze[result]

          parts = [
            "(#{@expression})",
            "#{dice_str(value_groups, sum)}#{@modifier_str}",
            total_sum,
            result_str,
          ].compact

          return Result.new.tap do |r|
            r.text = parts.join(" ＞ ")
            r.fumble = result == :fumble
            r.critical = result == :critical
            r.success = [:success, :super_success, :critical].include?(result)
            r.failure = [:failure, :fumble].include?(result)
          end
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
        # @return [Symbol]
        def result_status(total_sum, n_value_groups, fumble, critical)
          return :no_target unless @target
          return :fumble if fumble
          return :critical if critical

          if total_sum.send(@cmp_op, @target)
            # 振り足しが行われ、合計値が41以上ならば「超成功」
            n_value_groups >= 2 && total_sum >= 41 ? :super_success : :success
          else
            :failure
          end
        end
      end
    end
  end
end
