# frozen_string_literal: true

module BCDice
  module GameSystem
    class FateCoreSystem < Base
      # ゲームシステムの識別子
      ID = 'FateCoreSystem'

      # ゲームシステム名
      NAME = 'Fate Core System'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふえいとこあしすてむ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■ ファッジダイスによる判定 (xDF+y>=t)
          ファッジダイスをx個ダイスロールし、結果を判定します。
          x: ダイス数(省略時4)
          y: 修正値（省略可）
          t: 目標値（省略可）
          例）4DF, 4DF>=3, 4DF+1>=3, DF, DF>=3, DF+1>=3
      MESSAGETEXT

      register_prefix('\d*DF')

      def eval_game_system_specific_command(command)
        roll_df(command)
      end

      private

      def roll_df(command)
        parser = Command::Parser.new("DF", round_type: @round_type)
                                .enable_prefix_number()
                                .restrict_cmp_op_to(:>=, nil)

        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_x = 4
        dice_x = parsed.prefix_number if parsed.prefix_number
        dice_list = roll_fate_dice(dice_x)
        total = dice_list.sum() + parsed.modify_number

        fate_dice_list = dice_list.map do |i|
          if i.zero?
            "[ ]"
          elsif i.positive?
            "[+]"
          else
            "[-]"
          end
        end

        result = outcome(total, parsed.target_number)
        sequence = [
          "(#{parsed})",
          "#{fate_dice_list.join()}#{Format.modifier(parsed.modify_number)}",
          result_ladder(total),
          result.text,
        ]

        result.text = sequence.compact.join(" ＞ ")
        return result
      end

      def roll_fate_dice(times)
        @randomizer.roll_barabara(times, 3).map { |i| i - 2 }
      end

      def result_ladder(total)
        ladder =
          case total.clamp(-2, 8)
          when 8
            "Legendary"
          when 7
            "Epic"
          when 6
            "Fantastic"
          when 5
            "Superb"
          when 4
            "Great"
          when 3
            "Good"
          when 2
            "Fair"
          when 1
            "Average"
          when 0
            "Mediocre"
          when -1
            "Poor"
          else
            "Terrible"
          end

        return "#{ladder}(#{format('%+d', total)})"
      end

      def outcome(total, target)
        if target.nil?
          Result.new
        elsif total == target
          Result.success("Tie(+0)")
        elsif total == target + 1
          Result.success("Succeed(+1)")
        elsif total >= target + 3
          Result.critical("Succeed with Style")
        elsif total >= target
          Result.success("Succeed")
        else
          Result.failure("Fail")
        end
      end
    end
  end
end
