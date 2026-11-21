# frozen_string_literal: true

require 'bcdice/game_system/TenkaRyouran'

module BCDice
  module GameSystem
    class TenkaRyouran_Korean < TenkaRyouran
      # ゲームシステムの識別子
      ID = 'TenkaRyouran:Korean'

      # ゲームシステム名
      NAME = '천하요란'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:천하요란'

      # ダイスボットの使い方
      HELP_MESSAGE = help_message()

      set_aliases_for_srs_roll('TR')

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
