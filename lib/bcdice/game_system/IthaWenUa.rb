# frozen_string_literal: true

module BCDice
  module GameSystem
    class IthaWenUa < Base
      # ゲームシステムの識別子
      ID = 'IthaWenUa'

      # ゲームシステム名
      NAME = 'イサー・ウェン＝アー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'いさあうえんああ'

      # ダイスボットの使い方
      HELP_MESSAGE = "1D100<=m 方式の判定で成否、クリティカル(01)・ファンブル(00)を自動判定します。\n"

      def result_1d100(total, _dice_total, cmp_op, target)
        return nil unless cmp_op == :<=

        if total % 100 == 1
          Result.critical("01 ＞ クリティカル")
        elsif total % 100 == 0
          Result.fumble("00 ＞ ファンブル")
        elsif target == "?"
          Result.nothing
        end
      end
    end
  end
end
