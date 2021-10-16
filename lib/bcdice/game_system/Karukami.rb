# frozen_string_literal: true

module BCDice
  module GameSystem
    class Karukami < Base
      # ゲームシステムの識別子
      ID = 'Karukami'

      # ゲームシステム名
      NAME = 'カルカミ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かるかみ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP_MESSAGE
        ■ 行為判定、ダメージ算出 (xUB+y@c>=t)
          6面ダイスをx個ダイスロールし、クリティカル値以上の出目が出たら振り足して合計値を算出します。
          x: ダイス数
          y: 修正値（省略可）
          c: クリティカル値（省略可）
          t: 目標値値（省略可）
          例）2UB, 2UB>=7, 3UB+1@5, 3UB+1@5<10
      HELP_MESSAGE

      register_prefix('\d+UB')

      def eval_game_system_specific_command(command)
        roll_ub(command)
      end

      def roll_ub(command)
        parser = Command::Parser.new("UB", round_type: @round_type)
                                .has_prefix_number
                                .enable_critical
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        critical = parsed.critical || 6
        if critical <= 1
          return "(#{parsed}) ＞ クリティカル値は2以上としてください"
        end

        list_list = []
        criticals = 0
        stack = parsed.prefix_number
        while stack > 0
          dice_list = @randomizer.roll_barabara(stack, 6)
          list_list.push(dice_list)
          stack = dice_list.count { |x| x >= critical }
          criticals += stack
        end

        total = list_list.flatten.sum() + parsed.modify_number

        result =
          if list_list.first.all?(1)
            total = 0
            Result.fumble("ファンブル")
          elsif parsed.cmp_op.nil?
            Result.new()
          elsif total.send(parsed.cmp_op, parsed.target_number)
            Result.success("成功")
          else
            Result.failure("失敗")
          end
        result.critical = criticals > 0

        sequence = [
          "(#{parsed})",
          *list_list.map { |list| "[#{list.join(',')}]" },
          total,
          ("#{criticals}クリティカル" if result.critical?),
          result.text,
        ].compact

        result.text = sequence.join(" ＞ ")
        return result
      end
    end
  end
end
