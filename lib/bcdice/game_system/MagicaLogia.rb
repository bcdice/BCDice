# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class MagicaLogia < Base
      # ゲームシステムの識別子
      ID = 'MagicaLogia'

      # ゲームシステム名
      NAME = 'マギカロギア'

      # ゲームシステム名の読みがな
      SORT_KEY = 'まきかろきあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        スペシャル／ファンブル／成功／失敗を判定
        ・各種表
        経歴表　BGT/初期アンカー表　DAT/運命属性表　FAT
        願い表　WIT/プライズ表　PT
        時の流れ表　TPT/大判時の流れ表　TPTB
        事件表　AT
        ファンブル表　FT／変調表　WT
        運命変転表　FCT
        　典型的災厄 TCT／物理的災厄 PCT／精神的災厄 MCT／狂気的災厄 ICT
        　社会的災厄 SCT／超常的災厄 XCT／不思議系災厄 WCT／コミカル系災厄 CCT
        　魔法使いの災厄 MGCT
        シーン表　ST／大判シーン表　STB
        　極限環境 XEST／内面世界 IWST／魔法都市 MCST
        　死後世界 WDST／迷宮世界 LWST
        　魔法書架 MBST／魔法学院 MAST／クレドの塔 TCST
        　並行世界 PWST／終末　　 PAST／異世界酒場 GBST
        　ほしかげ SLST／旧図書館 OLST
        世界法則追加表 WLAT/さまよう怪物表 WMT
        ランダム分野表　RCT
        ランダム特技表　RTT
        　星分野ランダム特技表  RTS, RTT1
        　獣分野ランダム特技表  RTB, RTT2
        　力分野ランダム特技表  RTF, RTT3
        　歌分野ランダム特技表  RTP, RTT4
        　夢分野ランダム特技表  RTD, RTT5
        　闇分野ランダム特技表  RTN, RTT6
        ブランク秘密表　BST/
        　宿敵表　MIT/謀略表　MOT/因縁表　MAT
        　奇人表　MUT/力場表　MFT/同盟表　MLT
        落花表　FFT
        その後表 FLT
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @sort_barabara_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      # ゲーム別成功度判定(2D6)
      def result_2d6(total, dice_total, dice_list, cmp_op, target)
        return nil if target == '?'
        return nil unless cmp_op == :>=

        result =
          if dice_total <= 2
            Result.fumble(translate("fumble"))
          elsif dice_total >= 12
            Result.critical(translate("MagicaLogia.special"))
          elsif total >= target
            Result.success(translate("success"))
          else
            Result.failure(translate("failure"))
          end

        result.text += gain_magic_element(dice_list[0], dice_list[1])
        return result
      end

      def eval_game_system_specific_command(command)
        self.class::SKILL_TABLE.roll_command(@randomizer, command) ||
          roll_tables(command, TABLES)
      end

      private

      # 魔素獲得チェック
      def gain_magic_element(dice1, dice2)
        return "" unless dice1 == dice2

        element = translate("MagicaLogia.elements.items")[dice1 - 1]
        return " ＞ " + format(translate("MagicaLogia.elements.format"), text: element)
      end

      class SkillExpandTable
        def self.from_i18n(key, locale, skill_table)
          table = I18n.t(key, locale: locale, raise: false)
          new(table[:name], table[:type], table[:items], skill_table)
        end

        def initialize(name, type, items, skill_table)
          @name = name
          @items = items.freeze
          @skill_table = skill_table

          m = /(\d+)D(\d+)/i.match(type)
          unless m
            raise ArgumentError, "Unexpected table type: #{type}"
          end

          @times = m[1].to_i
          @sides = m[2].to_i
        end

        def roll(randomizer)
          value = randomizer.roll_sum(@times, @sides)
          text = expand(@items[value - @times], randomizer)

          return DiceTable::RollResult.new(@name, value, text)
        end

        private

        def expand(chosen, randomizer)
          chosen.gsub(/\%{([a-z]+)}/) do
            m = Regexp.last_match
            type = m[1].to_sym

            roll_skill(type, randomizer)
          end
        end

        CATEGORIES = [:star, :beast, :force, :poem, :dream, :night].freeze

        def roll_skill(type, randomizer)
          if type == :skill
            return @skill_table.roll_skill(randomizer)
          end

          if type == :element
            return @skill_table.roll_category(randomizer)
          end

          index = CATEGORIES.index(type)
          raise ArgumentError unless index

          @skill_table.categories[index].roll(randomizer).name
        end
      end

      class FallenAfterTable
        def self.from_i18n(key, locale)
          table = I18n.t(key, locale: locale, raise: true)
          new(table[:name], table[:items_lower], table[:items_higher])
        end

        def initialize(name, items_lower, items_higher)
          @name = name
          @lower = items_lower
          @higher = items_higher
        end

        def roll(randomizer)
          val1, val2 = randomizer.roll_barabara(2, 6)

          table = val1 <= 3 ? @lower : @higher

          "#{@name}(#{val1},#{val2}) ＞ #{table[val2 - 1]}"
        end
      end

      class << self
        private

        def translate_skill_table(locale)
          DiceTable::SaiFicSkillTable.from_i18n(
            "MagicaLogia.skill_table",
            locale,
            rttn: ["RTS", "RTB", "RTF", "RTP", "RTD", "RTN"]
          )
        end

        def translate_tables(locale, skill_table)
          inveterate_enemy_table = SkillExpandTable.from_i18n("MagicaLogia.inveterate_enemy_table", locale, skill_table)
          conspiracy_table = DiceTable::Table.from_i18n("MagicaLogia.conspiracy_table", locale)
          fate_table = DiceTable::Table.from_i18n("MagicaLogia.fate_table", locale)
          cueball_table = DiceTable::Table.from_i18n("MagicaLogia.cueball_table", locale)
          force_field_table = DiceTable::Table.from_i18n("MagicaLogia.force_field_table", locale)
          alliance_table = SkillExpandTable.from_i18n("MagicaLogia.alliance_table", locale, skill_table)

          {
            "TPT" => SkillExpandTable.from_i18n("MagicaLogia.tables.TPT", locale, skill_table),
            "ST" => SkillExpandTable.from_i18n("MagicaLogia.tables.ST", locale, skill_table),
            "FT" => DiceTable::Table.from_i18n("MagicaLogia.tables.FT", locale),
            "WT" => SkillExpandTable.from_i18n("MagicaLogia.tables.WT", locale, skill_table),
            "FCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.FCT", locale),
            "AT" => SkillExpandTable.from_i18n("MagicaLogia.tables.AT", locale, skill_table),
            "BGT" => DiceTable::Table.from_i18n("MagicaLogia.tables.BGT", locale),
            "DAT" => DiceTable::Table.from_i18n("MagicaLogia.tables.DAT", locale),
            "FAT" => DiceTable::Table.from_i18n("MagicaLogia.tables.FAT", locale),
            "WIT" => DiceTable::Table.from_i18n("MagicaLogia.tables.WIT", locale),
            "TCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.TCT", locale),
            "PCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.PCT", locale),
            "MCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.MCT", locale),
            "ICT" => DiceTable::Table.from_i18n("MagicaLogia.tables.ICT", locale),
            "SCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.SCT", locale),
            "XCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.XCT", locale),
            "WCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.WCT", locale),
            "CCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.CCT", locale),
            "MIT" => inveterate_enemy_table,
            "MOT" => conspiracy_table,
            "MAT" => fate_table,
            "MUT" => cueball_table,
            "MFT" => force_field_table,
            "MLT" => alliance_table,
            "BST" => DiceTable::ChainTable.new(
              "ブランク秘密表",
              "1D6",
              [
                inveterate_enemy_table,
                conspiracy_table,
                fate_table,
                cueball_table,
                force_field_table,
                alliance_table,
              ]
            ),
            "PT" => DiceTable::Table.from_i18n("MagicaLogia.tables.PT", locale),
            "XEST" => SkillExpandTable.from_i18n("MagicaLogia.tables.XEST", locale, skill_table),
            "IWST" => SkillExpandTable.from_i18n("MagicaLogia.tables.IWST", locale, skill_table),
            "MCST" => SkillExpandTable.from_i18n("MagicaLogia.tables.MCST", locale, skill_table),
            "WDST" => SkillExpandTable.from_i18n("MagicaLogia.tables.WDST", locale, skill_table),
            "LWST" => SkillExpandTable.from_i18n("MagicaLogia.tables.LWST", locale, skill_table),
            "STB" => SkillExpandTable.from_i18n("MagicaLogia.tables.STB", locale, skill_table),
            "MGCT" => DiceTable::Table.from_i18n("MagicaLogia.tables.MGCT", locale),
            "MBST" => SkillExpandTable.from_i18n("MagicaLogia.tables.MBST", locale, skill_table),
            "MAST" => SkillExpandTable.from_i18n("MagicaLogia.tables.MAST", locale, skill_table),
            "TCST" => SkillExpandTable.from_i18n("MagicaLogia.tables.TCST", locale, skill_table),
            "PWST" => SkillExpandTable.from_i18n("MagicaLogia.tables.PWST", locale, skill_table),
            "PAST" => SkillExpandTable.from_i18n("MagicaLogia.tables.PAST", locale, skill_table),
            "GBST" => SkillExpandTable.from_i18n("MagicaLogia.tables.GBST", locale, skill_table),
            "SLST" => SkillExpandTable.from_i18n("MagicaLogia.tables.SLST", locale, skill_table),
            "WLAT" => DiceTable::Table.from_i18n("MagicaLogia.tables.WLAT", locale),
            "WMT" => SkillExpandTable.from_i18n("MagicaLogia.tables.WMT", locale, skill_table),
            "FFT" => DiceTable::Table.from_i18n("MagicaLogia.tables.FFT", locale),
            "OLST" => SkillExpandTable.from_i18n("MagicaLogia.tables.OLST", locale, skill_table),
            "TPTB" => SkillExpandTable.from_i18n("MagicaLogia.tables.TPTB", locale, skill_table),
            "FLT" => FallenAfterTable.from_i18n("MagicaLogia.tables.FLT", locale),
          }
        end
      end

      SKILL_TABLE = translate_skill_table(:ja_jp)
      TABLES = translate_tables(:ja_jp, SKILL_TABLE)

      register_prefix(SKILL_TABLE.prefixes)
      register_prefix(TABLES.keys)
    end
  end
end
