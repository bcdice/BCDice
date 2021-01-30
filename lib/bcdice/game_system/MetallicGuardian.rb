# frozen_string_literal: true

require 'bcdice/game_system/SRS'

module BCDice
  module GameSystem
    # メタリックガーディアンのダイスボット
    class MetallicGuardian < SRS
      # 固有のコマンドの接頭辞を設定する
      register_prefix('2D6.*', 'MG.*')

      # 成功判定のエイリアスコマンドを設定する
      set_aliases_for_srs_roll('MG')

      # ゲームシステム名
      NAME = 'メタリックガーディアンRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'めたりつくかあていあんRPG'

      # ゲームシステムの識別子
      ID = 'MetallicGuardian'

      HELP_MESSAGE = help_message()
    end
  end
end
