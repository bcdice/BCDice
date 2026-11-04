# frozen_string_literal: true

module BCDice
  module GameSystem
    class Sinless < Base
      ID = "Sinless"
      NAME = "Sinless"
      SORT_KEY = "しんれす"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nSL[U][@t][Rr][>=s または >s])
          n個のD6を振り、目標値t以上の出目を成功として数えます。
          t: 目標値。省略時4。Veteran:4、Professional:5、Prime:6。
             Heatなどによる低下にも対応し、2～6を指定できます。
          U: 未修得技能。成功したダイス4個につき成功数1（端数切り捨て）。
          Rr: 振り直し能力を使用。R1は出目1、R2は出目1・2を1回だけ振り直します。
              最初の出目がすべて1なら、振り直しは行いません。
          >=s: 必要成功数s以上なら成功。省略時は成功数のみ表示します。
          >s: 相手の成功数sと対抗判定。上回れば成功、同数なら引き分け。
          最終的な出目がすべて1なら Argle Bargle Foofaraw（ファンブル）。
          ダイス数nには、使用するプールのダイスとボーナス・ペナルティを適用した個数を指定してください。
          未修得技能Uは、技能・グループ技能がなく、未修得で使用可能な技能に使用します。
          判定前に加えるKismetダイスはnに含めてください。
          判定後のKismet追加はnB6>=tで振り、成功数を手動で合算してください（Uの換算は合算後）。

        例: 7SL、7SL@5、7SLR1、8SLU@4R2>=2、6SL>3
      TEXT

      register_prefix('\d+SL')

      COMMAND = /\A(?<count>\d+)SL(?<untrained>U)?(?:@(?<target>[2-6]))?(?:R(?<reroll>[12]))?(?:(?<comparison>>=|>)(?<required>\d+))?\z/.freeze

      def eval_game_system_specific_command(command)
        m = COMMAND.match(command)
        return nil unless m

        count = m[:count].to_i
        return nil if count <= 0

        target = m[:target] ? m[:target].to_i : 4
        dice = @randomizer.roll_barabara(count, 6)
        parts = ["(#{command})", "目標値#{target}", "[#{dice.join(',')}]"]

        # Sinless p.28: all ones cancel rerolls, regardless of their source.
        unless dice.all?(1)
          reroll(dice, m[:reroll].to_i, parts)
        end

        successes = dice.count { |value| value >= target }
        if m[:untrained]
          parts << "未修得技能:#{successes}/4"
          successes /= 4
        end
        parts << "成功数#{successes}"

        result = judge(dice, successes, m[:comparison], m[:required].to_i)
        parts << result.text if result.text
        result.text = parts.join(" ＞ ")
        return result
      end

      private

      def reroll(dice, threshold, parts)
        indices = dice.each_index.select { |i| dice[i] <= threshold }
        return if indices.empty?

        rerolled = @randomizer.roll_barabara(indices.size, 6)
        indices.zip(rerolled).each { |i, value| dice[i] = value }
        parts << "振り直し[#{rerolled.join(',')}]"
        parts << "最終出目[#{dice.join(',')}]"
      end

      def judge(dice, successes, comparison, required)
        if dice.all?(1)
          return Result.fumble("Argle Bargle Foofaraw")
        end

        case comparison
        when ">="
          return Result.new.tap do |result|
            result.condition = successes >= required
            result.text = result.success? ? "成功" : "失敗"
          end
        when ">"
          if successes > required
            return Result.success("成功（純成功数#{successes - required}）")
          elsif successes < required
            return Result.failure("失敗（相手の純成功数#{required - successes}）")
          else
            return Result.new("引き分け（状況変化なし）")
          end
        else
          return Result.new
        end
      end
    end
  end
end
