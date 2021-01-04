# frozen_string_literal: true

require "bcdice/game_system/DesperateRun"

module BCDice
  module GameSystem
    class JekyllAndHyde < DesperateRun
      # ゲームシステムの識別子
      ID = "JekyllAndHyde"

      # ゲームシステム名
      NAME = "ジキルとハイドとグリトグラ"

      # ゲームシステム名の読みがな
      SORT_KEY = "しきるとはいととくりとくら"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ・難易度算出コマンド　DDC
        ・判定コマンド　RCx　or　RCx+y　or　RCx-y（x＝難易度、y=修正値（省略可能））
        ・目標決定表　GOALT
      HELP

      TABLES = {
        "GOALT" => DiceTable::Table.new(
          "目標決定表",
          "1D6",
          [
            "「主人格の目的達成」",
            "「主人格の目的阻害」",
            "「主人格のハッピーエンド（目的達成しなくてもよい）」",
            "「主人格のバッドエンド（目的達成していてもよい）」",
            "「自分の人格が目的を決定できる」",
            "「主人格の目的達成」「主人格の目的阻害」「主人格のハッピーエンド（目的達成しなくてもよい）」「主人格のバッドエンド（目的達成していてもよい）」「自分の人格が目的を決定できる」のどれかを自由に選べる"
          ]
        )
      }.freeze

      register_prefix('RC\d+', 'DDC', TABLES.keys)
    end
  end
end
