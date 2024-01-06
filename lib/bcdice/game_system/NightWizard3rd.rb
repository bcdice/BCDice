# frozen_string_literal: true

require 'bcdice/game_system/NightWizard'

module BCDice
  module GameSystem
    class NightWizard3rd < NightWizard
      # ゲームシステムの識別子
      ID = 'NightWizard3rd'

      # ゲームシステム名
      NAME = 'ナイトウィザード The 3rd Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ないとういさあと3'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定用コマンド　(aNW+b@x#y$z+c)
        　　a : 基本値
        　　b : 常時に準じる特技による補正
        　　c : 常時以外の特技、および支援効果による補正
        　　x : クリティカル値のカンマ区切り（省略時 10）
        　　y : ファンブル値のカンマ区切り（省略時 5）
        　　z : プラーナによる達成値補正のプラーナ消費数（ファンブル時には適用されない）
        　クリティカル値、ファンブル値が無い場合は1や13などのあり得ない数値を入れてください。
        　例）12NW-5@7#2$3 1NW 50nw+5@7,10#2,5 50nw-5+10@7,10#2,5+15+25
      INFO_MESSAGE_TEXT

      register_prefix('([-+]?\d+)?NW', '2R6')

      def fumble_base_number(parsed)
        parsed.passive_modify_number + parsed.active_modify_number
      end
    end
  end
end
