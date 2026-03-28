# frozen_string_literal: true

require 'bcdice/game_system/WorldsEndFrontline'

module BCDice
  module GameSystem
    class WorldsEndFrontline_Korean < WorldsEndFrontline
      # ゲームシステムの識別子
      ID = 'WorldsEndFrontline:Korean'

      # ゲームシステム名
      NAME = '월드 엔드 프론트라인'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:월드 엔드 프론트라인'

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
