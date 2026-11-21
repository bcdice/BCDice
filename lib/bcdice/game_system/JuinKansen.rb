# frozen_string_literal: true

require "bcdice/base"
require "bcdice/dice_table/table"

module BCDice
  module GameSystem
    class JuinKansen < Base
      # ゲームシステムの識別子
      ID = "JuinKansen"

      # ゲームシステム名
      NAME = "呪印感染"

      # ゲームシステム名の読みがな
      SORT_KEY = "しゆいんかんせん"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ■ 表
          ・日常表 (DAI, Daily)
          ・場所表
            ・「都市」 (PCI, PlaceCity)
            ・「田舎」 (PCO, PlaceCountryside)
            ・「施設内」 (PFA, PlaceFacility)
          ・初見表 (FL, FirstLook)
          ・知己表 (AF, AppreciativeFriend)
          ・伏線表 (FOR, Foreshadow)
          ・感情表 (EMO, Emotion)
          ・状況表 (SIT, Situation)
          ・対象表 (TAR, Target)
          ・狂気表 (INS, Insanity)
          ・終焉表 (DEA, Death)
          ・恐怖表 (FEA, Fear)
      INFO_MESSAGE_TEXT

      def eval_game_system_specific_command(command)
        roll_tables(self.class::ALIAS[command] || command, self.class::TABLES)
      end

      class << self
        private

        def translate_tables(locale)
          {
            "DAILY" => DiceTable::Table.from_i18n("JuinKansen.table.DAILY", locale),
            "PLACECITY" => DiceTable::Table.from_i18n("JuinKansen.table.PLACECITY", locale),
            "PLACECOUNTRYSIDE" => DiceTable::Table.from_i18n("JuinKansen.table.PLACECOUNTRYSIDE", locale),
            "PLACEFACILITY" => DiceTable::Table.from_i18n("JuinKansen.table.PLACEFACILITY", locale),
            "FIRSTLOOK" => DiceTable::Table.from_i18n("JuinKansen.table.FIRSTLOOK", locale),
            "APPRECIATIVEFRIEND" => DiceTable::Table.from_i18n("JuinKansen.table.APPRECIATIVEFRIEND", locale),
            "FORESHADOW" => DiceTable::Table.from_i18n("JuinKansen.table.FORESHADOW", locale),
            "EMOTION" => DiceTable::Table.from_i18n("JuinKansen.table.EMOTION", locale),
            "SITUATION" => DiceTable::Table.from_i18n("JuinKansen.table.SITUATION", locale),
            "TARGET" => DiceTable::Table.from_i18n("JuinKansen.table.TARGET", locale),
            "INSANITY" => DiceTable::Table.from_i18n("JuinKansen.table.INSANITY", locale),
            "DEATH" => DiceTable::Table.from_i18n("JuinKansen.table.DEATH", locale),
            "FEAR" => DiceTable::Table.from_i18n("JuinKansen.table.FEAR", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      ALIAS = {
        "DAI" => "DAILY",
        "PCI" => "PLACECITY",
        "PCO" => "PLACECOUNTRYSIDE",
        "PFA" => "PLACEFACILITY",
        "FL" => "FIRSTLOOK",
        "AF" => "APPRECIATIVEFRIEND",
        "FOR" => "FORESHADOW",
        "EMO" => "EMOTION",
        "SIT" => "SITUATION",
        "TAR" => "TARGET",
        "INS" => "INSANITY",
        "DEA" => "DEATH",
        "FEA" => "FEAR",
      }.freeze

      register_prefix(TABLES.keys, ALIAS.keys)
    end
  end
end
