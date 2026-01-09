# frozen_string_literal: true

require 'bcdice/dice_table/table'

module BCDice
  module GameSystem
    class Nuekagami < Base
      # ゲームシステムの識別子
      ID = 'Nuekagami'

      # ゲームシステム名
      NAME = '鵺鏡'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ぬえかかみ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・喪失表（xL）
        　BL：血脈、LL：生様、SL：魂魄、FL：因縁
        ・LR：喪失取戻表
        ・門通過描写表（xG）
        　HG：地獄門、RG：羅生門、VG：朱雀門、OG：応天門
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES)
      end

      class << self
        private

        def translate_tables(locale)
          {
            "LR" => DiceTable::Table.from_i18n("Nuekagami.table.LR", locale),
            "BL" => DiceTable::Table.from_i18n("Nuekagami.table.BL", locale),
            "LL" => DiceTable::Table.from_i18n("Nuekagami.table.LL", locale),
            "SL" => DiceTable::Table.from_i18n("Nuekagami.table.SL", locale),
            "FL" => DiceTable::Table.from_i18n("Nuekagami.table.FL", locale),
            "HG" => DiceTable::Table.from_i18n("Nuekagami.table.HG", locale),
            "RG" => DiceTable::Table.from_i18n("Nuekagami.table.RG", locale),
            "VG" => DiceTable::Table.from_i18n("Nuekagami.table.VG", locale),
            "OG" => DiceTable::Table.from_i18n("Nuekagami.table.OG", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
