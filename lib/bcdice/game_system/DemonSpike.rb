# frozen_string_literal: true

module BCDice
  module GameSystem
    class DemonSpike < Base
      # ゲームシステムの識別子
      ID = 'DemonSpike'

      # ゲームシステム名
      NAME = 'デモンスパイク'

      # ゲームシステム名の読みがな
      SORT_KEY = 'てもんすはいく'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定 xDS+y
        　行為判定を行い、達成値、成否、成功度を出力する。
        　x: ダイス数（省略：2）
        　y: 能力値やスパイク能力による達成値の修正（省略可）
      INFO_MESSAGE_TEXT

      register_prefix('\d*DS')

      def eval_game_system_specific_command(command)
        roll_action(command)
      end

      private

      def roll_action(command)
        parser = Command::Parser.new("DS", round_type: @round_type)
                                .enable_prefix_number
                                .restrict_cmp_op_to(nil)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        parsed.prefix_number ||= 2
        if parsed.prefix_number < 2
          return nil
        end

        step = roll_step(parsed.prefix_number)
        step_list = [step]
        while step[:dice_sum] == 10
          step = roll_step(parsed.prefix_number)
          step_list.push(step)
        end

        is_fumble = step_list[0][:dice_sum] == 2
        total = is_fumble ? 0 : step_list.sum { |s| s[:dice_sum] } + parsed.modify_number
        success_level = total / 10
        is_success = total >= 10

        res =
          if is_success
            "成功, 成功度#{success_level}"
          elsif is_fumble
            "自動的失敗"
          else
            "失敗"
          end

        sequence = [
          "(#{parsed})",
          step_list.map { |s| "#{s[:dice_sum]}[#{s[:dice_list].join(',')}]" },
          total,
          res,
        ].flatten

        return Result.new.tap do |r|
          r.condition = is_success
          r.critical = step_list.length > 1
          r.fumble = is_fumble
          r.text = sequence.join(" ＞ ")
        end
      end

      def roll_step(times)
        dice_list = @randomizer.roll_barabara(times, 6).sort.reverse
        dice_sum = (dice_list[0] + dice_list[1]).clamp(2, 10)

        return {dice_list: dice_list, dice_sum: dice_sum}
      end
    end
  end
end
