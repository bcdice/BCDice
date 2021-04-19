# frozen_string_literal: true

module BCDice
  module GameSystem
    class SharedFantasia < Base
      # ゲームシステムの識別子
      ID = 'SharedFantasia'

      # ゲームシステム名
      NAME = 'Shared†Fantasia'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しえああとふあんたしあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        2D6の成功判定に 自動成功、自動失敗、致命的失敗、劇的成功 の判定があります。

        SF/ST = 2D6のショートカット

        例) SF+4>=9 : 2D6して4を足した値が9以上なら成功
      MESSAGETEXT

      register_prefix('SF', 'ST')

      def change_text(string)
        string.gsub(/S[FT]/i, "2D6")
      end

      def result_2d6(total, dice_total, _dice_list, cmp_op, target)
        return Result.nothing if target == '?'
        return nil unless [:>=, :>].include?(cmp_op)

        critical = false
        fumble   = false

        if dice_total == 12
          critical = true
        elsif dice_total == 2
          fumble = true
        end

        totalValueBonus = (cmp_op == :>= ? 1 : 0)

        if (total + totalValueBonus) > target
          if critical
            Result.critical("自動成功(劇的成功)")
          elsif fumble
            Result.failure("自動失敗")
          else
            Result.success("成功")
          end
        else
          if critical
            Result.success("自動成功")
          elsif fumble
            Result.fumble("自動失敗(致命的失敗)")
          else
            Result.failure("失敗")
          end
        end
      end
    end
  end
end
