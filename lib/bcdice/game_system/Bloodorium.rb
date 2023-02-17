# frozen_string_literal: true

module BCDice
  module GameSystem
    class Bloodorium < Base
      # ゲームシステムの識別子
      ID = 'Bloodorium'

      # ゲームシステム名
      NAME = 'ブラドリウム'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふらとりうむ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・ダイスチェック xDC+y
        　【ダイスチェック】を行う。《トライアンフ》を結果に自動反映する。
        　x: ダイス数
        　y: 結果への修正値 （省略可）
      INFO_MESSAGE_TEXT

      register_prefix('\dDC')

      def eval_game_system_specific_command(command)
        dicecheck(command)
      end

      private

      def dicecheck(command)
        parser = Command::Parser.new("DC", round_type: @round_type).has_prefix_number.restrict_cmp_op_to(nil)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_list = @randomizer.roll_barabara(parsed.prefix_number, 6).sort
        dice_value = dice_list.max
        values_count = dice_list
                       .group_by(&:itself)
                       .transform_values(&:length)
        triumph = values_count.values.max

        total = dice_value * triumph + parsed.modify_number

        sequence = [
          "(#{parsed})",
          "[#{dice_list.join(',')}]#{Format.modifier(parsed.modify_number)}",
          ("《トライアンフ》(*#{triumph})" if triumph > 1),
          (total_expr(dice_value, triumph, parsed.modify_number) if total != dice_value),
          total,
        ].compact

        return Result.new.tap do |r|
          r.critical = triumph > 1
          r.text = sequence.join(" ＞ ")
        end
      end

      def total_expr(dice_value, triumph, modify_number)
        formated_triumph = triumph > 1 ? "*#{triumph}" : nil

        return "#{dice_value}#{formated_triumph}#{Format.modifier(modify_number)}"
      end
    end
  end
end
