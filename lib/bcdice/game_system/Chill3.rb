# frozen_string_literal: true

module BCDice
  module GameSystem
    class Chill3 < Base
      # ゲームシステムの識別子
      ID = 'Chill3'

      # ゲームシステム名
      NAME = 'Chill 3rd Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ちる3'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・1D100で判定時に成否、Botchを判定
        　例）1D100<=50
        　　 (1D100<=50) ＞ 55 ＞ Botch
      INFO_MESSAGE_TEXT

      def result_1d100(total, dice_total, cmp_op, target)
        return nil if target == '?'
        return nil unless cmp_op == :<=

        # ゾロ目ならC-ResultかBotch
        tens = (dice_total / 10) % 10
        ones = dice_total % 10

        if tens == ones
          if (total > target) || (dice_total == 100) # 00は必ず失敗
            if target > 100 # 目標値が100を超えている場合は、00を振ってもBotchにならない
              return Result.failure("Failure")
            else
              return Result.fumble("Botch")
            end
          else
            return Result.critical("Colossal Success")
          end
        elsif (total <= target) || (dice_total == 1) # 01は必ず成功
          if total <= (target / 2)
            return Result.success("High Success")
          else
            return Result.success("Low Success")
          end
        else
          return Result.failure("Failure")
        end
      end
    end
  end
end
