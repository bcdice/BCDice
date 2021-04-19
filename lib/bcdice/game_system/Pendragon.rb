# frozen_string_literal: true

module BCDice
  module GameSystem
    class Pendragon < Base
      # ゲームシステムの識別子
      ID = 'Pendragon'

      # ゲームシステム名
      NAME = 'ペンドラゴン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'へんとらこん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        クリティカル、成功、失敗、ファンブルの自動判定を行います。
      INFO_MESSAGE_TEXT

      # ゲーム別成功度判定(1d20)
      def result_1d20(total, _dice_total, cmp_op, target)
        return Result.nothing if target == '?'
        return nil unless cmp_op == :<=

        if total <= target
          if (total >= (40 - target)) || (total == target)
            Result.critical("クリティカル")
          else
            Result.success("成功")
          end
        elsif total == 20
          Result.fumble("ファンブル")
        else
          Result.failure("失敗")
        end
      end
    end
  end
end
