# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'bcdice/game_system/DungeonsAndDragons'

module BCDice
  module GameSystem
    class Pathfinder < DungeonsAndDragons
      # ゲームシステムの識別子
      ID = 'Pathfinder'

      # ゲームシステム名
      NAME = 'Pathfinder'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はすふあいんたあ'

      # ダイスボットの使い方
      HELP_MESSAGE = "※このダイスボットは部屋のシステム名表示用となります。\n"
    end
  end
end
