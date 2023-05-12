# frozen_string_literal: true

require 'bcdice/game_system/SRS'

module BCDice
  module GameSystem
    class TenkaRyouran < SRS
      # ゲームシステムの識別子
      ID = 'TenkaRyouran'

      # ゲームシステム名
      NAME = '天下繚乱'

      # ゲームシステム名の読みがな
      SORT_KEY = 'てんかりようらん'

      # 固有のコマンドの接頭辞を設定する
      register_prefix('2D6', 'TR')

      # 成功判定のエイリアスコマンドを設定する
      set_aliases_for_srs_roll('TR')

      HELP_MESSAGE = help_message()
    end
  end
end
