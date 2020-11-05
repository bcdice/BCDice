# frozen_string_literal: true

module BCDice
  module GameSystem
    class Comes < Base
      # ゲームシステムの識別子
      ID = 'Comes'

      # ゲームシステム名
      NAME = 'カムズ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かむす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・各種表
        　判定ペナルティ表 PT
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        return roll_tables(command, self.class::TABLES)
      end

      def self.translate_tables(locale)
        {
          "PT" => DiceTable::Table.from_i18n("Comes.table.PT", locale),
        }
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
