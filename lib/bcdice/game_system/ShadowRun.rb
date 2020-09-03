# frozen_string_literal: true

module BCDice
  module GameSystem
    class ShadowRun < Base
      # ゲームシステムの識別子
      ID = 'ShadowRun'

      # ゲームシステム名
      NAME = 'シャドウラン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しやとうらん'

      # ダイスボットの使い方
      HELP_MESSAGE = "上方無限ロール(xUn)の境界値を6にセットします。\n"

      def initialize
        super
        @sort_add_dice = true
        @sort_barabara_dice = true
        @upper_dice_reroll_threshold = 6
      end
    end
  end
end
