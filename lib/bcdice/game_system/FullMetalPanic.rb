# frozen_string_literal: true

require 'bcdice/game_system/SRS'

module BCDice
  module GameSystem
    # フルメタル・パニック！のダイスボット
    class FullMetalPanic < SRS
      # ゲームシステムの識別子
      ID = 'FullMetalPanic'

      # ゲームシステム名
      NAME = 'フルメタル・パニック！RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふるめたるはにつくRPG'

      # 固有のコマンドの接頭辞を設定する
      register_prefix('2D6.*', 'MG.*', 'FP.*')

      # 成功判定のエイリアスコマンドを設定する
      set_aliases_for_srs_roll('MG', 'FP')

      HELP_MESSAGE = help_message()
    end
  end
end
