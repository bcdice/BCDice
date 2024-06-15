# frozen_string_literal: true

module BCDice
  module GameSystem
    class KizunaBullet < Base
      class RollTwiceRandomizerTable
        def initialize(locale:, a_table:, b_table:)
          @locale = locale
          @a_table = a_table
          @b_table = b_table
        end

        def roll(randomizer)
          results = []

          result_a = @a_table.roll(randomizer).to_s
          results.push(result_a)

          result_b = @b_table.roll(randomizer).to_s
          results.push(result_b)

          return results.join("\n")
        end
      end

      class << self
        private

        def translate_tables(locale)
          ordinary_days_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.ODP", locale)
          ordinary_days_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.ODC", locale)
          communication_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.COP", locale)
          communication_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.COC", locale)
          investigation_basic_table = DiceTable::D66Table.from_i18n("KizunaBullet.table.INB", locale)
          investigation_dynamic_table = DiceTable::D66Table.from_i18n("KizunaBullet.table.IND", locale)
          return {
            "ODP" => ordinary_days_place_table,
            "ODC" => ordinary_days_content_table,
            "ODPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: ordinary_days_place_table,
              b_table: ordinary_days_content_table
            ).freeze,
            "TTC" => DiceTable::D66Table.from_i18n("KizunaBullet.table.TTC", locale),
            "COP" => communication_place_table,
            "COC" => communication_content_table,
            "COPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: communication_place_table,
              b_table: communication_content_table
            ).freeze,
            "INB" => investigation_basic_table,
            "IND" => investigation_dynamic_table,
            "INBD" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: investigation_basic_table,
              b_table: investigation_dynamic_table
            ).freeze,
            "HAZ" => DiceTable::Table.from_i18n("KizunaBullet.table.HAZ", locale),
          }.freeze
        end
      end
    end
  end
end
