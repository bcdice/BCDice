# frozen_string_literal: true

module BCDice
  module GameSystem
    class WaresBlade < Base
      # ゲームシステムの識別子
      ID = 'WaresBlade'

      # ゲームシステム名
      NAME = 'ワースブレイド'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わあすふれいと'

      # ダイスボットの使い方
      HELP_MESSAGE = "nD10>=m 方式の判定で成否、完全成功、完全失敗を自動判定します。\n"

      def result_nd10(_total, _dice_total, dice_list, cmp_op, _target)
        return nil unless cmp_op == :>=

        if dice_list.count(10) == dice_list.size
          Result.critical("完全成功")
        elsif dice_list.count(1) == dice_list.size
          Result.fumble("絶対失敗")
        end
      end
    end
  end
end
