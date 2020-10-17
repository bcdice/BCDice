# frozen_string_literal: true

module BCDice
  module GameSystem
    class Insane < Base
      # ゲームシステムの識別子
      ID = 'Insane'

      # ゲームシステム名
      NAME = 'インセイン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'いんせいん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        スペシャル／ファンブル／成功／失敗を判定
        ・各種表
        シーン表　　　ST
        　本当は怖い現代日本シーン表 HJST／狂騒の二〇年代シーン表 MTST
        　暗黒のヴィクトリアシーン表 DVST
        形容表　　　　DT
        　本体表 BT／部位表 PT
        感情表　　　　　　FT
        職業表　　　　　　JT
        バッドエンド表　　BET
        ランダム特技決定表　RTT
        指定特技(暴力)表　　(TVT)
        指定特技(情動)表　　(TET)
        指定特技(知覚)表　　(TPT)
        指定特技(技術)表　　(TST)
        指定特技(知識)表　　(TKT)
        指定特技(怪異)表　　(TMT)
        会話ホラースケープ表(CHT)
        街中ホラースケープ表(VHT)
        不意訪問ホラースケープ表(IHT)
        廃墟遭遇ホラースケープ表(RHT)
        野外遭遇ホラースケープ表(MHT)
        情報潜在ホラースケープ表(LHT)
        遭遇表　都市　(ECT)　山林　(EMT)　海辺　(EAT)/反応表　RET
        残業ホラースケープ表　OHT/残業電話表　OPT/残業シーン表　OWT
        社名決定表1　CNT1/社名決定表2　CNT2/社名決定表3　CNT3
        暫定整理番号作成表　IRN
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix("BET", "RTT", "IRN")

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @sort_barabara_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      # ゲーム別成功度判定(2D6)
      def check_2D6(total, dice_total, _dice_list, cmp_op, target)
        return '' unless cmp_op == :>=

        result =
          if dice_total <= 2
            translate("Insane.fumble")
          elsif dice_total >= 12
            translate("Insane.special")
          elsif target == "?"
            ""
          elsif total >= target
            translate("success")
          else
            translate("failure")
          end

        if result.empty?
          return ""
        end

        return " ＞ #{result}"
      end

      def eval_game_system_specific_command(command)
        case command
        when 'BET'
          type = translate("Insane.BET.name")
          output, total_n = get_badend_table
        when 'RTT'
          type = translate("Insane.RTT.name")
          output, total_n = get_random_skill_table
        when 'IRN'
          type = translate("Insane.IRN.name")
          output, total_n = get_interim_reference_number
        else
          return roll_tables(command, self.class::TABLES)
        end

        return "#{type}(#{total_n}) ＞ #{output}"
      end

      private

      # バッドエンド表
      def get_badend_table
        table = [
          translate("Insane.BET.items.2"),
          lambda { return translate("Insane.BET.items.3", skill: get_random_skill_table_text_only()) },
          translate("Insane.BET.items.4"),
          translate("Insane.BET.items.5"),
          translate("Insane.BET.items.6"),
          translate("Insane.BET.items.7"),
          translate("Insane.BET.items.8"),
          translate("Insane.BET.items.9"),
          translate("Insane.BET.items.10"),
          lambda { return translate("Insane.BET.items.11", skill: get_random_skill_table_text_only()) },
          translate("Insane.BET.items.12"),
        ]
        return get_table_by_2d6(table)
      end

      # 指定特技ランダム決定表
      def get_random_skill_table
        skillTable, total_n = get_table_by_1d6(translate("Insane.RTT.items"))
        tableName, skillTable = *skillTable
        skill, total_n2 = get_table_by_2d6(skillTable)
        return "「#{tableName}」≪#{skill}≫", "#{total_n},#{total_n2}"
      end

      # 特技だけ抜きたい時用 あまりきれいでない
      def get_random_skill_table_text_only
        text, = get_random_skill_table
        return text
      end

      # 暫定整理番号作成表
      def get_interim_reference_number
        table = [
          [11, '1'],
          [12, '2'],
          [13, '3'],
          [14, '4'],
          [15, '5'],
          [16, '6'],
          [22, 'G'],
          [23, 'I'],
          [24, 'J'],
          [25, 'K'],
          [26, 'O'],
          [33, 'P'],
          [34, 'Q'],
          [35, 'S'],
          [36, 'T'],
          [44, 'U'],
          [45, 'V'],
          [46, 'X'],
          [55, 'Y'],
          [56, 'Z'],
          [66, '-'],
        ]

        number = @randomizer.roll_once(6)
        total_n = number.to_s
        counts = 3
        if number <= 4
          counts = number + 5
        elsif number == 5
          counts = 4
        end

        output = ''
        counts.times do
          character, number = get_table_by_d66_swap(table)
          output += character
          total_n += ",#{number}"
        end
        return output, total_n
      end

      class << self
        private

        def translate_tables(locale)
          {
            "ST" => DiceTable::Table.from_i18n("Insane.table.ST", locale),
            "HJST" => DiceTable::Table.from_i18n("Insane.table.HJST", locale),
            "MTST" => DiceTable::Table.from_i18n("Insane.table.MTST", locale),
            "DVST" => DiceTable::Table.from_i18n("Insane.table.DVST", locale),
            "DT" => DiceTable::D66Table.from_i18n("Insane.table.DT", locale),
            "BT" => DiceTable::D66Table.from_i18n("Insane.table.BT", locale),
            "PT" => DiceTable::D66Table.from_i18n("Insane.table.PT", locale),
            "FT" => DiceTable::Table.from_i18n("Insane.table.FT", locale),
            "JT" => DiceTable::D66Table.from_i18n("Insane.table.JT", locale),
            "TVT" => DiceTable::Table.from_i18n("Insane.table.TVT", locale),
            "TET" => DiceTable::Table.from_i18n("Insane.table.TET", locale),
            "TPT" => DiceTable::Table.from_i18n("Insane.table.TPT", locale),
            "TST" => DiceTable::Table.from_i18n("Insane.table.TST", locale),
            "TKT" => DiceTable::Table.from_i18n("Insane.table.TKT", locale),
            "TMT" => DiceTable::Table.from_i18n("Insane.table.TMT", locale),
            "CHT" => DiceTable::Table.from_i18n("Insane.table.CHT", locale),
            "VHT" => DiceTable::Table.from_i18n("Insane.table.VHT", locale),
            "IHT" => DiceTable::Table.from_i18n("Insane.table.IHT", locale),
            "RHT" => DiceTable::Table.from_i18n("Insane.table.RHT", locale),
            "MHT" => DiceTable::Table.from_i18n("Insane.table.MHT", locale),
            "LHT" => DiceTable::Table.from_i18n("Insane.table.LHT", locale),
            "ECT" => DiceTable::Table.from_i18n("Insane.table.ECT", locale),
            "EMT" => DiceTable::Table.from_i18n("Insane.table.EMT", locale),
            "EAT" => DiceTable::Table.from_i18n("Insane.table.EAT", locale),
            "OHT" => DiceTable::Table.from_i18n("Insane.table.OHT", locale),
            "OPT" => DiceTable::Table.from_i18n("Insane.table.OPT", locale),
            "OWT" => DiceTable::Table.from_i18n("Insane.table.OWT", locale),
            "CNT1" => DiceTable::Table.from_i18n("Insane.table.CNT1", locale),
            "CNT2" => DiceTable::Table.from_i18n("Insane.table.CNT2", locale),
            "CNT3" => DiceTable::Table.from_i18n("Insane.table.CNT3", locale),
            "RET" => DiceTable::Table.from_i18n("Insane.table.RET", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
