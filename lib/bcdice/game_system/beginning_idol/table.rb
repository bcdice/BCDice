# frozen_string_literal: true

require "bcdice/game_system/beginning_idol/chain_table"
require "bcdice/game_system/beginning_idol/chain_d66_table"
require "bcdice/game_system/beginning_idol/bad_status_table"
require "bcdice/game_system/beginning_idol/random_event_table"
require "bcdice/game_system/beginning_idol/my_skill_name_table"
require "bcdice/game_system/beginning_idol/d6_twice_table"
require "bcdice/game_system/beginning_idol/item_table"
require "bcdice/game_system/beginning_idol/costume_table"
require "bcdice/game_system/beginning_idol/accessories_table"
require "bcdice/game_system/beginning_idol/with_abnormality"
require "bcdice/game_system/beginning_idol/work_table"
require "bcdice/game_system/beginning_idol/skill_table"

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class << self
        private

        def translate_skill_table(locale)
          SkillTable.from_i18n(
            "BeginningIdol.skill_table",
            locale,
            rtt: "AT",
            rttn: ["AT1", "AT2", "AT3", "AT4", "AT5", "AT6"]
          )
        end

        def translate_tables(locale)
          costume_challenge_girls = CostumeTable.from_i18n("BeginningIdol.tables.DT", locale)
          costume_road_to_prince = CostumeTable.from_i18n("BeginningIdol.tables.RC", locale)
          costume_fortune_stars = CostumeTable.from_i18n("BeginningIdol.tables.FC", locale)

          bland = ChainTable.new(
            I18n.t("BeginningIdol.ACB.name", locale: locale),
            "1D6",
            [
              [I18n.t("BeginningIdol.ACB.items.challenge_girls", locale: locale), costume_challenge_girls.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.challenge_girls", locale: locale), costume_challenge_girls.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.road_to_prince", locale: locale), costume_road_to_prince.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.road_to_prince", locale: locale), costume_road_to_prince.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.fortune_stars", locale: locale), costume_fortune_stars.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.fortune_stars", locale: locale), costume_fortune_stars.brand_only()],
            ]
          )

          bad_status_table = BadStatusTable.new(locale)

          skill_table = translate_skill_table(locale)

          rare_skill_table = DiceTable::Table.from_i18n("BeginningIdol.rare_skill_table", locale)

          item_table = ItemTable.new(locale)

          tn = ChainTable.new(
            I18n.t("BeginningIdol.TN.name", locale: locale),
            "1D6",
            I18n.t("BeginningIdol.TN.items", locale: locale).dup.tap { |items| items[3].push(skill_table) }
          )

          cg = ChainTable.new(
            I18n.t("BeginningIdol.CG.name", locale: locale),
            "1D6",
            I18n.t("BeginningIdol.CG.items", locale: locale).map.with_index do |item, index|
              if [3, 4].include?(index)
                [item, item_table]
              else
                [item]
              end
            end
          )

          gg = ChainD66Table.new(
            I18n.t("BeginningIdol.GG.name", locale: locale),
            I18n.t("BeginningIdol.GG.items", locale: locale).to_h do |index, value|
              chain =
                if [23, 24, 25].include?(index)
                  [value, rare_skill_table]
                elsif index == 56
                  [value, item_table]
                else
                  [value]
                end

              [index, chain]
            end
          )

          ha = ChainD66Table.new(
            I18n.t("BeginningIdol.HA.name", locale: locale),
            I18n.t("BeginningIdol.HA.items", locale: locale).dup.tap { |items| items[22].push(SkillHometown.new(skill_table)) }
          )

          {
            "DT" => costume_challenge_girls,
            "RC" => costume_road_to_prince,
            "FC" => costume_fortune_stars,
            "ACB" => bland,
            "TN" => tn,
            "CG" => cg,
            "GG" => gg,
            "HA" => ha,
            "CBT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CBT", locale),
            "RCB" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.RCB", locale),
            "HBT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.HBT", locale),
            "RHB" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.RHB", locale),
            "RU" => DiceTable::Table.from_i18n("BeginningIdol.tables.RU", locale),
            "SIP" => DiceTable::Table.from_i18n("BeginningIdol.tables.SIP", locale),
            "BU" => DiceTable::Table.from_i18n("BeginningIdol.tables.BU", locale),
            "HW" => DiceTable::Table.from_i18n("BeginningIdol.tables.HW", locale),
            "FL" => DiceTable::Table.from_i18n("BeginningIdol.tables.FL", locale),
            "MSE" => DiceTable::Table.from_i18n("BeginningIdol.tables.MSE", locale),
            "ST" => DiceTable::Table.from_i18n("BeginningIdol.tables.ST", locale),
            "FST" => DiceTable::Table.from_i18n("BeginningIdol.tables.FST", locale),
            "BWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.BWT", locale),
            "LWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.LWT", locale),
            "TWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.TWT", locale),
            "CWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CWT", locale),
            "SU" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.SU", locale),
            "WI" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.WI", locale),
            "NA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.NA", locale),
            "GA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.GA", locale),
            "BA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.BA", locale),
            "WT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.WT", locale),
            "VA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.VA", locale),
            "MU" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.MU", locale),
            "DR" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.DR", locale),
            "VI" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.VI", locale),
            "SP" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.SP", locale),
            "CHR" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CHR", locale),
            "PAR" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.PAR", locale),
            "SW" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.SW", locale),
            "AN" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.AN", locale),
            "MOV" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.MOV", locale),
            "FA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.FA", locale),
            "BVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.BVT", locale),
            "LVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.LVT", locale),
            "TVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.TVT", locale),
            "CVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.CVT", locale),
            "BST" => DiceTable::Table.from_i18n("BeginningIdol.tables.BST", locale),
            "LST" => DiceTable::Table.from_i18n("BeginningIdol.tables.LST", locale),
            "TST" => DiceTable::Table.from_i18n("BeginningIdol.tables.TST", locale),
            "CST" => DiceTable::Table.from_i18n("BeginningIdol.tables.CST", locale),
            "BPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.BPT", locale),
            "LPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.LPT", locale),
            "TPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.TPT", locale),
            "CPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.CPT", locale),
            "BIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.BIT", locale),
            "LIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.LIT", locale),
            "TIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.TIT", locale),
            "CIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.CIT", locale),
            "CHO" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CHO", locale),
            "SCH" => DiceTable::Table.from_i18n("BeginningIdol.tables.SCH", locale),
            "WCH" => DiceTable::Table.from_i18n("BeginningIdol.tables.WCH", locale),
            "NCH" => DiceTable::Table.from_i18n("BeginningIdol.tables.NCH", locale),
            "GCH" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.GCH", locale),
            "PCH" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.PCH", locale),
            "LUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.LUR", locale),
            "SUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.SUR", locale),
            "WUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.WUR", locale),
            "NUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.NUR", locale),
            "GUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.GUR", locale),
            "BUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.BUR", locale),
            "ACE" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.ACE", locale),
            "ACT" => translate_accessories_table(locale),
            "MS" => MySkillNameTable.new(locale),
            "RE" => RandomEventTable.new(locale),
            "SH" => D66WithAbnormality.from_i18n("BeginningIdol.tables.SH", bad_status_table, locale),
            "MO" => D66WithAbnormality.from_i18n("BeginningIdol.tables.MO", bad_status_table, locale),
            "SEA" => D66WithAbnormality.from_i18n("BeginningIdol.tables.SEA", bad_status_table, locale),
            "SPA" => D66WithAbnormality.from_i18n("BeginningIdol.tables.SPA", bad_status_table, locale),
            "LN" => TableWithAbnormality.from_i18n("BeginningIdol.tables.LN", bad_status_table, locale),
            "SGT" => SkillGetTable.from_i18n("BeginningIdol.tables.SGT", skill_table, locale),
            "RS" => SkillGetTable.from_i18n("BeginningIdol.tables.RS", skill_table, locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      BAD_STATUS_TABLE = BadStatusTable.new(:ja_jp)

      LOCAL_WORK_TABLE = translate_local_work_table(:ja_jp)
      ITEM_TABLE = ItemTable.new(:ja_jp)

      SKILL_TABLE = translate_skill_table(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
