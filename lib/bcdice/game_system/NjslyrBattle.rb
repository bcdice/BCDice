# frozen_string_literal: true

module BCDice
  module GameSystem
    class NjslyrBattle < Base
      # ゲームシステムの識別子
      ID = 'NjslyrBattle'

      # ゲームシステム名
      NAME = 'NJSLYRBATTLE'

      # ゲームシステム名の読みがな
      SORT_KEY = 'にんしやすれいやあはとる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・カラテロール
        2d6<=(カラテ点)
        例）2d6<=5
        (2D6<=5) ＞ 2[1,1] ＞ 2 ＞ 成功 重点 3 溜まる
      INFO_MESSAGE_TEXT

      # ゲーム別成功度判定(2D6)
      def result_2d6(total, _dice_total, dice_list, cmp_op, target)
        return Result.nothing if target == "?"
        return nil if cmp_op != :<=

        result = (total <= target ? Result.success("成功") : Result.failure("失敗"))
        result.text += juuten(dice_list)

        return result
      end

      private

      def juuten(dice_list)
        juuten = dice_list.count(1) + dice_list.count(6)

        if dice_list[0] == dice_list[1]
          juuten += 1
        end

        if juuten > 0
          " 重点 #{juuten} 溜まる"
        else
          ""
        end
      end
    end
  end
end
