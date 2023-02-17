# frozen_string_literal: true

require 'bcdice/game_system/SwordWorld'

module BCDice
  module GameSystem
    class SwordWorld_SimplifiedChinese < SwordWorld
      # ゲームシステムの識別子
      ID = 'SwordWorld:SimplifiedChinese'

      # ゲームシステム名
      NAME = '剑世界'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Simplified Chinese:剑世界'

      # ダイスボットの使い方
      HELP_MESSAGE = "・SW　威力表　(Kx[c]+m$f) (x:威力值, c:暴击值, m:加值, f:骰子出目修正)\n"

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :zh_hans
      end
    end
  end
end
