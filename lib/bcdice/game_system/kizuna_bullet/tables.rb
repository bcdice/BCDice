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

      class Roll4TimesRandomizerTable
        def initialize(locale:, a_table:, b_table:, c_table:, d_table:)
          @locale = locale
          @a_table = a_table
          @b_table = b_table
          @c_table = c_table
          @d_table = d_table
        end

        def roll(randomizer)
          results = []

          result_a = @a_table.roll(randomizer).to_s
          results.push(result_a)

          result_b = @b_table.roll(randomizer).to_s
          results.push(result_b)

          result_c = @c_table.roll(randomizer).to_s
          results.push(result_c)

          result_d = @d_table.roll(randomizer).to_s
          results.push(result_d)

          return results.join("\n")
        end
      end

      class << self
        private

        def translate_tables(locale)
          ordinary_days_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.OP", locale)
          ordinary_days_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.OC", locale)
          ordinary_days_work_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.OWP", locale)
          ordinary_days_work_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.OWC", locale)
          ordinary_days_holiday_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.OHP", locale)
          ordinary_days_holiday_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.OHC", locale)
          ordinary_days_trip_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.OTP", locale)
          ordinary_days_trip_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.OTC", locale)
          encounter_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.EP", locale)
          encounter_order_table = DiceTable::Table.from_i18n("KizunaBullet.table.EO", locale)
          encounter_first_table = DiceTable::Table.from_i18n("KizunaBullet.table.EF", locale)
          encounter_acquaintance_table = DiceTable::Table.from_i18n("KizunaBullet.table.EA", locale)
          encounter_end_table = DiceTable::Table.from_i18n("KizunaBullet.table.EE", locale)
          communication_place_table = DiceTable::Table.from_i18n("KizunaBullet.table.CP", locale)
          communication_content_table = DiceTable::Table.from_i18n("KizunaBullet.table.CC", locale)
          investigation_basic_table = DiceTable::D66Table.from_i18n("KizunaBullet.table.IB", locale)
          investigation_dynamic_table = DiceTable::D66Table.from_i18n("KizunaBullet.table.ID", locale)
          return {
            "OP" => ordinary_days_place_table,
            "OC" => ordinary_days_content_table,
            "OPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: ordinary_days_place_table,
              b_table: ordinary_days_content_table
            ).freeze,
            "OWP" => ordinary_days_work_place_table,
            "OWC" => ordinary_days_work_content_table,
            "OWPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: ordinary_days_work_place_table,
              b_table: ordinary_days_work_content_table
            ).freeze,
            "OHP" => ordinary_days_holiday_place_table,
            "OHC" => ordinary_days_holiday_content_table,
            "OHPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: ordinary_days_holiday_place_table,
              b_table: ordinary_days_holiday_content_table
            ).freeze,
            "OTP" => ordinary_days_trip_place_table,
            "OTC" => ordinary_days_trip_content_table,
            "OTPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: ordinary_days_trip_place_table,
              b_table: ordinary_days_trip_content_table
            ).freeze,
            "TT" => DiceTable::D66Table.from_i18n("KizunaBullet.table.TT", locale),
            "TTI" => DiceTable::D66Table.from_i18n("KizunaBullet.table.TTI", locale),
            "TTC" => DiceTable::D66Table.from_i18n("KizunaBullet.table.TTC", locale),
            "TTH" => DiceTable::D66Table.from_i18n("KizunaBullet.table.TTH", locale),
            "EP" => encounter_place_table,
            "EO" => encounter_order_table,
            "EF" => encounter_first_table,
            "EA" => encounter_acquaintance_table,
            "EE" => encounter_end_table,
            "EFA" => Roll4TimesRandomizerTable.new(
              locale: locale,
              a_table: encounter_place_table,
              b_table: encounter_order_table,
              c_table: encounter_first_table,
              d_table: encounter_end_table
            ).freeze,
            "EAA" => Roll4TimesRandomizerTable.new(
              locale: locale,
              a_table: encounter_place_table,
              b_table: encounter_order_table,
              c_table: encounter_acquaintance_table,
              d_table: encounter_end_table
            ).freeze,
            "CP" => communication_place_table,
            "CC" => communication_content_table,
            "CPC" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: communication_place_table,
              b_table: communication_content_table
            ).freeze,
            "IB" => investigation_basic_table,
            "ID" => investigation_dynamic_table,
            "IBD" => RollTwiceRandomizerTable.new(
              locale: locale,
              a_table: investigation_basic_table,
              b_table: investigation_dynamic_table
            ).freeze,
            "HA" => DiceTable::Table.from_i18n("KizunaBullet.table.HA", locale),
            "NI1" => DiceTable::Table.from_i18n("KizunaBullet.table.NI1", locale),
            "NI2" => DiceTable::Table.from_i18n("KizunaBullet.table.NI2", locale),
            "NI3" => DiceTable::Table.from_i18n("KizunaBullet.table.NI3", locale),
            "NI4" => DiceTable::Table.from_i18n("KizunaBullet.table.NI4", locale),
            "NI5" => DiceTable::Table.from_i18n("KizunaBullet.table.NI5", locale),
            "NI6" => DiceTable::Table.from_i18n("KizunaBullet.table.NI6", locale),
            "NT1" => DiceTable::Table.from_i18n("KizunaBullet.table.NT1", locale),
            "NT2" => DiceTable::Table.from_i18n("KizunaBullet.table.NT2", locale),
            "NT3" => DiceTable::Table.from_i18n("KizunaBullet.table.NT3", locale),
            "NT4" => DiceTable::Table.from_i18n("KizunaBullet.table.NT4", locale),
            "NT5" => DiceTable::Table.from_i18n("KizunaBullet.table.NT5", locale),
            "NT6" => DiceTable::Table.from_i18n("KizunaBullet.table.NT6", locale),
            "HH1" => DiceTable::Table.from_i18n("KizunaBullet.table.HH1", locale),
            "HH2" => DiceTable::Table.from_i18n("KizunaBullet.table.HH2", locale),
            "HH3" => DiceTable::Table.from_i18n("KizunaBullet.table.HH3", locale),
            "HH4" => DiceTable::Table.from_i18n("KizunaBullet.table.HH4", locale),
            "HH5" => DiceTable::Table.from_i18n("KizunaBullet.table.HH5", locale),
            "HH6" => DiceTable::Table.from_i18n("KizunaBullet.table.HH6", locale),
            "HC1" => DiceTable::Table.from_i18n("KizunaBullet.table.HC1", locale),
            "HC2" => DiceTable::Table.from_i18n("KizunaBullet.table.HC2", locale),
            "HC3" => DiceTable::Table.from_i18n("KizunaBullet.table.HC3", locale),
            "HC4" => DiceTable::Table.from_i18n("KizunaBullet.table.HC4", locale),
            "HC5" => DiceTable::Table.from_i18n("KizunaBullet.table.HC5", locale),
            "HC6" => DiceTable::Table.from_i18n("KizunaBullet.table.HC6", locale),
          }.freeze
        end
      end
    end
  end
end
