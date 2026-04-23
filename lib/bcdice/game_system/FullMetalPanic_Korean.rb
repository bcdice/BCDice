# frozen_string_literal: true

require 'bcdice/game_system/FullMetalPanic'

module BCDice
  module GameSystem
    class FullMetalPanic_Korean < FullMetalPanic
      # ゲームシステムの識別子
      ID = 'FullMetalPanic:Korean'

      # ゲームシステム名
      NAME = '풀 메탈 패닉! RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:풀 메탈 패닉! RPG'

      set_aliases_for_srs_roll('MG', 'FP')

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
