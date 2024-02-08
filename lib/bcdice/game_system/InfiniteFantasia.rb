# frozen_string_literal: true

module BCDice
  module GameSystem
    class InfiniteFantasia < Base
      # ゲームシステムの識別子
      ID = 'InfiniteFantasia'

      # ゲームシステム名
      NAME = '無限のファンタジア'

      # ゲームシステム名の読みがな
      SORT_KEY = 'むけんのふあんたしあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        1D20に目標値を設定した場合に、成功レベルの自動判定を行います。
        例： 1D20<=16
      INFO_MESSAGE_TEXT

      # ゲーム別成功度判定(1d20)
      def result_1d20(total, _dice_total, cmp_op, target)
        return Result.nothing if target == '?'
        return nil unless cmp_op == :<=

        if total > target
          return Result.failure("失敗")
        end

        output =
          if total <= (target / 32)
            "32レベル成功(32Lv+)"
          elsif total <= (target / 16)
            "16レベル成功(16Lv+)"
          elsif total <= (target / 8)
            "8レベル成功"
          elsif total <= (target / 4)
            "4レベル成功"
          elsif total <= (target / 2)
            "2レベル成功"
          else
            "1レベル成功"
          end

        Result.new.tap do |r|
          r.text = output
          r.success = true
          if total <= 1
            r.critical = true
            r.text += "/クリティカル"
          end
        end
      end
    end
  end
end
