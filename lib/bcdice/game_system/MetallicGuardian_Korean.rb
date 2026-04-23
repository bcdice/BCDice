# frozen_string_literal: true

require 'bcdice/game_system/MetallicGuardian'

module BCDice
  module GameSystem
    class MetallicGuardian_Korean < MetallicGuardian
      # ゲームシステムの識別子
      ID = 'MetallicGuardian:Korean'

      # ゲームシステム名
      NAME = '메탈릭 가디언 RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:메탈릭 가디언 RPG'

      set_aliases_for_srs_roll('MG')

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
