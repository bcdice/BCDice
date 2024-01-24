# frozen_string_literal: true

module BCDice
  module GameSystem
    class Elric < Base
      # ゲームシステムの識別子
      ID = 'Elric'

      # ゲームシステム名
      NAME = 'エルリック！'

      # ゲームシステム名の読みがな
      SORT_KEY = 'えるりつく'

      # ダイスボットの使い方
      HELP_MESSAGE = "貫通、クリティカル、ファンブルの自動判定を行います。\n"

      # ゲーム別成功度判定(1d100)
      def result_1d100(total, _dice_total, cmp_op, target)
        return nil unless cmp_op == :<=

        if total <= 1
          Result.critical("貫通") # 1は常に貫通
        elsif total >= 100
          Result.fumble("致命的失敗") # 100は常に致命的失敗
        elsif target == '?'
          Result.nothing
        elsif total <= (target / 5.0).ceil
          Result.critical("決定的成功")
        elsif total <= target
          Result.success("成功")
        elsif (total >= 99) && (target < 100)
          Result.fumble("致命的失敗")
        else
          Result.failure("失敗")
        end
      end
    end
  end
end
