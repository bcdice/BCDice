# frozen_string_literal: true

module BCDice
  module GameSystem
    class CyberpunkRed < Base
      class ScreamSheetRandomizerTable
        def initialize(locale:, type_table:, a_table:, of_table:, b_table:, c_table:)
          @locale = locale
          @type_table = type_table
          @a_table = a_table
          @of_table = of_table
          @b_table = b_table
          @c_table = c_table
        end

        def roll(randomizer)
          result = ""

          dice = randomizer.roll_once(6)
          scs_type = @type_table.choice(dice)
          result += "#{scs_type}#{I18n.translate('CyberpunkRed.news', locale: @locale, raise: true)}　『"

          dice = randomizer.roll_once(10)
          scs_val_a = @a_table.choice(dice).body
          result += scs_val_a

          dice = randomizer.roll_once(6)
          scs_val_of = @of_table.choice(dice).body
          result += scs_val_of

          dice = randomizer.roll_once(10)
          scs_val_a = @a_table.choice(dice).body
          result += scs_val_a

          dice = randomizer.roll_once(6)
          scs_val_of = @of_table.choice(dice).body
          result += scs_val_of

          dice = randomizer.roll_once(10)
          scs_val_b = @b_table.choice(dice).body
          result += scs_val_b

          dice = randomizer.roll_once(10)
          scs_val_c = @c_table.choice(dice).body
          result += scs_val_c

          result += "』"

          return result
        end
      end

      class ShopPeopleTable
        def initialize(locale:, staff_table:, people_a_table:, people_b_table:)
          @locale = locale
          @staff_table = staff_table
          @people_a_table = people_a_table
          @people_b_table = people_b_table
        end

        def roll(randomizer)
          result = I18n.translate("CyberpunkRed.ShopPeopleTableText.intro", locale: @locale, raise: true)

          dice = randomizer.roll_once(6)
          staff = @staff_table.choice(dice).body
          staff = staff[0..-2]
          result += staff
          result += I18n.translate("CyberpunkRed.ShopPeopleTableText.shop_staff", locale: @locale, raise: true)

          dice = randomizer.roll_once(6)
          people = @people_a_table.choice(dice).body
          people = people[0..-2]
          result += people
          result += I18n.translate("CyberpunkRed.ShopPeopleTableText.people_a", locale: @locale, raise: true)

          dice = randomizer.roll_once(6)
          people = @people_b_table.choice(dice).body
          people = people[0..-2]
          result += people
          result += I18n.translate("CyberpunkRed.ShopPeopleTableText.people_b", locale: @locale, raise: true)
          result += I18n.translate("CyberpunkRed.ShopPeopleTableText.outro", locale: @locale, raise: true)

          return result
        end
      end

      class << self
        private

        def translate_tables(locale)
          nigit_market_type_table = DiceTable::Table.from_i18n("CyberpunkRed.NightMarketTypeTable", locale)
          night_market_foods_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.NightMarketFoodsTable", locale)
          night_market_mechanic_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.NightMarketMechanicTable", locale)
          night_market_weapons_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.NightMarketWeaponsTable", locale)
          night_market_cyberware_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.NightMarketCyberwareTable", locale)
          night_market_fashion_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.NightMarketFashionTable", locale)
          night_market_suvival_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.NightMarketSuvivalTable", locale)

          scream_sheet_type_table = DiceTable::Table.from_i18n("CyberpunkRed.ScreamSheetTypeTable", locale)
          scream_sheet_a_table = DiceTable::Table.from_i18n("CyberpunkRed.ScreamSheetATable", locale)
          scream_sheet_b_table = DiceTable::Table.from_i18n("CyberpunkRed.ScreamSheetBTable", locale)
          scream_sheet_c_table = DiceTable::Table.from_i18n("CyberpunkRed.ScreamSheetCTable", locale)
          scream_sheet_of_table = DiceTable::Table.from_i18n("CyberpunkRed.ScreamSheetOfTable", locale)

          vending_machine_type_table = DiceTable::RangeTable.from_i18n("CyberpunkRed.VendingMachineTypeTable", locale)
          vending_machine_food_table = DiceTable::Table.from_i18n("CyberpunkRed.VendingMachineFoodTable", locale)
          vending_machine_fashion_table = DiceTable::Table.from_i18n("CyberpunkRed.VendingMachineFashionTable", locale)
          vending_machine_strange_table = DiceTable::Table.from_i18n("CyberpunkRed.VendingMachineStrangeTable", locale)

          shop_staff_table = DiceTable::Table.from_i18n("CyberpunkRed.ShopStaffTable", locale)
          shop_people_a_table = DiceTable::Table.from_i18n("CyberpunkRed.ShopPeopleATable", locale)
          shop_people_b_table = DiceTable::Table.from_i18n("CyberpunkRed.ShopPeopleBTable", locale)

          return {
            "FFD" => DiceTable::Table.from_i18n("CyberpunkRed.FrameFatalDamageTable", locale),
            "HFD" => DiceTable::Table.from_i18n("CyberpunkRed.HeadFatalDamageTable", locale),
            "NCDT" => DiceTable::RangeTable.from_i18n("CyberpunkRed.NightCityDaytimeEncounterTable", locale),
            "NCMT" => DiceTable::RangeTable.from_i18n("CyberpunkRed.NightCityMidnightEncounterTable", locale),
            "NMCT" => nigit_market_type_table,
            "NMCFO" => night_market_foods_table,
            "NMCME" => night_market_mechanic_table,
            "NMCWE" => night_market_weapons_table,
            "NMCCY" => night_market_cyberware_table,
            "NMCFA" => night_market_fashion_table,
            "NMCSU" => night_market_suvival_table,
            "SCST" => scream_sheet_type_table,
            "SCSA" => scream_sheet_a_table,
            "SCSB" => scream_sheet_b_table,
            "SCSC" => scream_sheet_c_table,
            "SCSR" => ScreamSheetRandomizerTable.new(
              locale: locale,
              type_table: scream_sheet_type_table,
              a_table: scream_sheet_a_table,
              b_table: scream_sheet_b_table,
              c_table: scream_sheet_c_table,
              of_table: scream_sheet_of_table
            ).freeze,
            "VMCT" => vending_machine_type_table,
            "VMCE" => vending_machine_food_table,
            "VMCF" => vending_machine_fashion_table,
            "VMCS" => vending_machine_strange_table,
            "VMCR" => DiceTable::ChainTable.new(
              I18n.translate("CyberpunkRed.VendingMachineTable.name", locale: locale, raise: true),
              "1D6",
              [
                vending_machine_food_table,
                vending_machine_food_table,
                vending_machine_food_table,
                vending_machine_fashion_table,
                vending_machine_fashion_table,
                vending_machine_strange_table
              ]
            ),
            "STOREA" => shop_staff_table,
            "STOREB" => shop_people_a_table,
            "STOREC" => shop_people_b_table,
            "STORE" => ShopPeopleTable.new(
              locale: locale,
              staff_table: shop_staff_table,
              people_a_table: shop_people_a_table,
              people_b_table: shop_people_b_table
            ).freeze
          }.freeze
        end
      end
    end
  end
end
