# frozen_string_literal: true

module BCDice
  module GameSystem
    class WARPS < Base
      # ゲームシステムの識別子
      ID = 'WARPS'

      # ゲームシステム名
      NAME = 'ワープス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わあふす'

      # ダイスボットの使い方
      HELP_MESSAGE = "失敗、成功度の自動判定を行います。\n"

      def result_2d6(total, dice_total, _dice_list, cmp_op, target)
        return nil unless cmp_op == :<=

        if dice_total <= 2
          Result.critical("クリティカル")
        elsif dice_total >= 12
          Result.fumble("ファンブル")
        elsif target == "?"
          Result.nothing
        elsif total <= target
          Result.success("#{target - total}成功")
        else
          Result.failure("失敗")
        end
      end
    end
  end
end
