# frozen_string_literal: true

module BCDice
  module GameSystem
    class ShadowRun4 < Base
      # ゲームシステムの識別子
      ID = 'ShadowRun4'

      # ゲームシステム名
      NAME = 'シャドウラン 4th Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しやとうらん4'

      # ダイスボットの使い方
      HELP_MESSAGE = <<INFO_MESSAGE_TEXT
個数振り足しロール(xRn)の境界値を6にセット、バラバラロール(xBn)の目標値を5以上にセットします。
BコマンドとRコマンド時に、グリッチの表示を行います。
INFO_MESSAGE_TEXT

      def initialize
        super
        @sortType = 3
        @rerollNumber = 6 # 振り足しする出目
        @defaultSuccessTarget = ">=5" # 目標値が空欄の時の目標値
      end

      # シャドウラン4版用グリッチ判定
      def grich_text(numberSpot1, dice_cnt_total, successCount)
        dice_cnt_total_half = (1.0 * dice_cnt_total / 2)
        debug("dice_cnt_total_half", dice_cnt_total_half)

        unless numberSpot1 >= dice_cnt_total_half
          return nil
        end

        # グリッチ！
        if successCount == 0
          'クリティカルグリッチ'
        else
          'グリッチ'
        end
      end
    end
  end
end
