# frozen_string_literal: true

require 'bcdice/game_system/NightWizard'

module BCDice
  module GameSystem
    class NightWizard3rd < NightWizard
      # ゲームシステム名
      NAME = 'ナイトウィザード The 3rd Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ないとういさあと3'

      # ゲームシステムの識別子
      ID = 'NightWizard3rd'

      setPrefixes(['([-+]?\d+)?NW.*', '2R6.*'])

      def fumble_base_number(parsed)
        parsed.passive_modify_number + parsed.active_modify_number
      end
    end
  end
end
