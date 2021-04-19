# frozen_string_literal: true

module BCDice
  module GameSystem
    class Hieizan < Base
      # ゲームシステムの識別子
      ID = 'Hieizan'

      # ゲームシステム名
      NAME = '比叡山炎上'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひえいさんえんしよう'

      # ダイスボットの使い方
      HELP_MESSAGE = "大成功、自動成功、失敗、自動失敗、大失敗の自動判定を行います。\n"

      # ゲーム別成功度判定(1d100)
      def result_1d100(total, _dice_total, cmp_op, target)
        return Result.nothing if target == '?'
        return nil unless cmp_op == :<=

        if total >= 100
          Result.fumble("大失敗")
        elsif total >= 96
          Result.failure("自動失敗")
        elsif total <= (target / 5)
          Result.critical("大成功")
        elsif total <= 1
          Result.success("自動成功")
        elsif total <= target
          Result.success("成功")
        else
          Result.failure("失敗")
        end
      end
    end
  end
end
