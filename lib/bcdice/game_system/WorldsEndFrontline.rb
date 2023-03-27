# frozen_string_literal: true

require "bcdice/game_system/Bloodorium"

module BCDice
  module GameSystem
    class WorldsEndFrontline < Bloodorium
      # ゲームシステムの識別子
      ID = 'WorldsEndFrontline'

      # ゲームシステム名
      NAME = 'ワールドエンドフロントライン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わあるとえんとふろんとらいん'

      register_prefix_from_super_class()
    end
  end
end
