# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class UnsungDuet < Base
      ID = "UnsungDuet"
      NAME = "アンサング・デュエット"
      SORT_KEY = "あんさんくてゆえつと"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ シフター用判定 (shifter, UDS)
          1D10をダイスロールして判定を行います。
          例） shifter, UDS, shifter>=5, shifter+1>=6

        ■ バインダー用判定 (binder, UDB)
          2D6をダイスロールして判定を行います。
          例） binder, UDB, binder>=5, binder+1>=6

        ■ 変異表
          ・外傷 (HIN, HInjury)
          ・体調の変化 (HPH, HPhysical)
          ・恐怖 (HFE, HFear)
          ・幻想化 (HFA, HFantasy)
          ・精神 (HMI, HMind)
          ・そのほか (HOT, HOther)
      MESSAGETEXT

      ALIAS_1D10 = ["shifter", "UDS"].freeze
      ALIAS_2D6 = ["binder", "UDB"].freeze

      SHIFTER_ALIAS_REG = /^#{ALIAS_1D10.join('|')}/i.freeze
      BINDER_ALIAS_REG = /^#{ALIAS_2D6.join('|')}/i.freeze

      register_prefix(ALIAS_1D10, ALIAS_2D6)

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command

        roll_replaced_command_if_match(command, SHIFTER_ALIAS_REG, "1D10") ||
          roll_replaced_command_if_match(command, BINDER_ALIAS_REG, "2D6") ||
          roll_tables(command, TABLES)
      end

      def roll_replaced_command_if_match(command, regexp, dist)
        if command.match?(regexp)
          CommonCommand::AddDice.eval(command.sub(regexp, dist), self, @randomizer)
        end
      end

      ALIAS = {
        "HInjury" => "HIN",
        "HPhysical" => "HPH",
        "HFear" => "HFE",
        "HFantasy" => "HFA",
        "HMind" => "HMI",
        "HOther" => "HOT",
      }.transform_keys(&:upcase)

      class << self
        private

        def translate_tables(locale)
          {
            "HIN" => DiceTable::Table.from_i18n('UnsungDuet.MutatingInjuryTable', locale),
            "HPH" => DiceTable::Table.from_i18n('UnsungDuet.MutatingPhysicalConditionTable', locale),
            "HFE" => DiceTable::Table.from_i18n('UnsungDuet.MutatingFearTable', locale),
            "HFA" => DiceTable::Table.from_i18n('UnsungDuet.MutatingFantasyTable', locale),
            "HMI" => DiceTable::Table.from_i18n('UnsungDuet.MutatingMindTable', locale),
            "HOT" => DiceTable::Table.from_i18n('UnsungDuet.MutatingOtherTable', locale),
          }.freeze
        end
      end

      TABLES = translate_tables(@locale)

      register_prefix(ALIAS.keys, TABLES.keys)
    end
  end
end
