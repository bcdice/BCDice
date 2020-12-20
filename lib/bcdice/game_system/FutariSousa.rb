# frozen_string_literal: true

module BCDice
  module GameSystem
    class FutariSousa < Base
      # ゲームシステムの識別子
      ID = 'FutariSousa'

      # ゲームシステム名
      NAME = 'フタリソウサ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふたりそうさ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定用コマンド
        探偵用：【DT】…10面ダイスを2つ振って判定します。『有利』なら【3DT】、『不利』なら【1DT】を使います。
        助手用：【AS】…6面ダイスを2つ振って判定します。『有利』なら【3AS】、『不利』なら【1AS】を使います。
        ・各種表
        【調査時】
        異常な癖決定表 SHRD
        　口から出る表 SHFM／強引な捜査表　　　 SHBT／すっとぼけ表　 SHPI
        　事件に夢中表 SHEG／パートナーと……表 SHWP／何かしている表 SHDS
        　奇想天外表　 SHFT／急なひらめき表　　 SHIN／喜怒哀楽表　　 SHEM
        イベント表
        　現場にて　 EVS／なぜ？　 EVW／協力者と共に EVN
        　向こうから EVC／VS容疑者 EVV
        調査の障害表 OBT　　変調表 ACT　　目撃者表 EWT　　迷宮入り表 WMT
        【設定時】
        背景表
        　探偵　運命の血統 BGDD／天性の才能 BGDG／マニア　　　　 BGDM
        　助手　正義の人　 BGAJ／情熱の人　 BGAP／巻き込まれの人 BGAI
        身長表 HT　　たまり場表 BT　　関係表 GRT　　思い出の品決定表 MIT
        職業表A・B　　JBT66・JBT10　　ファッション特徴表A・B　　　　FST66・FST10
        感情表A／B　　FLT66・FLT10　　好きなもの／嫌いなもの表A・B　LDT66・LDT10
        呼び名表A・B　NCT66・NCT10
      MESSAGETEXT

      def initialize(command)
        super(command)

        @d66_sort_type = D66SortType::ASC
      end

      register_prefix('(\d+)?DT', '(\d+)?AS')

      def eval_game_system_specific_command(command)
        if (m = /^(\d+)?DT$/i.match(command))
          count = m[1]&.to_i || 2
          return roll_dt(command, count)
        elsif (m = /^(\d+)?AS$/i.match(command))
          count = m[1]&.to_i || 2
          return roll_as(command, count)
        end

        return roll_tables(command, self.class::TABLES)
      end

      private

      # 成功の目標値
      SUCCESS_THRESHOLD = 4

      # スペシャルとなる出目
      SPECIAL_DICE = 6

      # 探偵用判定コマンド DT
      def roll_dt(command, count)
        dice_list = @randomizer.roll_barabara(count, 10)
        max = dice_list.max

        result =
          if max <= 1
            translate("FutariSousa.DT.fumble")
          elsif dice_list.include?(SPECIAL_DICE)
            translate("FutariSousa.DT.special")
          elsif max >= SUCCESS_THRESHOLD
            translate("success")
          else
            translate("failure")
          end

        return "#{command}(#{dice_list.join(',')}) ＞ #{result}"
      end

      # 助手用判定コマンド AS
      def roll_as(command, count)
        dice_list = @randomizer.roll_barabara(count, 6)
        max = dice_list.max

        result =
          if max <= 1
            translate("FutariSousa.AS.fumble")
          elsif dice_list.include?(SPECIAL_DICE)
            translate("FutariSousa.AS.special")
          elsif max >= SUCCESS_THRESHOLD
            translate("FutariSousa.AS.success")
          else
            translate("failure")
          end

        return "#{command}(#{dice_list.join(',')}) ＞ #{result}"
      end

      class << self
        private

        def translate_tables(locale)
          {
            "SHRD" => DiceTable::Table.from_i18n("FutariSousa.table.SHRD", locale),
            "SHFM" => DiceTable::Table.from_i18n("FutariSousa.table.SHFM", locale),
            "SHBT" => DiceTable::Table.from_i18n("FutariSousa.table.SHBT", locale),
            "SHPI" => DiceTable::Table.from_i18n("FutariSousa.table.SHPI", locale),
            "SHEG" => DiceTable::Table.from_i18n("FutariSousa.table.SHEG", locale),
            "SHWP" => DiceTable::Table.from_i18n("FutariSousa.table.SHWP", locale),
            "SHDS" => DiceTable::Table.from_i18n("FutariSousa.table.SHDS", locale),
            "SHFT" => DiceTable::Table.from_i18n("FutariSousa.table.SHFT", locale),
            "SHIN" => DiceTable::Table.from_i18n("FutariSousa.table.SHIN", locale),
            "SHEM" => DiceTable::Table.from_i18n("FutariSousa.table.SHEM", locale),
            "EVS" => DiceTable::Table.from_i18n("FutariSousa.table.EVS", locale),
            "EVW" => DiceTable::Table.from_i18n("FutariSousa.table.EVW", locale),
            "EVN" => DiceTable::Table.from_i18n("FutariSousa.table.EVN", locale),
            "EVC" => DiceTable::Table.from_i18n("FutariSousa.table.EVC", locale),
            "EVV" => DiceTable::Table.from_i18n("FutariSousa.table.EVV", locale),
            "OBT" => DiceTable::D66Table.from_i18n("FutariSousa.table.OBT", locale),
            "ACT" => DiceTable::Table.from_i18n("FutariSousa.table.ACT", locale),
            "EWT" => DiceTable::Table.from_i18n("FutariSousa.table.EWT", locale),
            "WMT" => DiceTable::Table.from_i18n("FutariSousa.table.WMT", locale),
            "BGDD" => DiceTable::Table.from_i18n("FutariSousa.table.BGDD", locale),
            "BGDG" => DiceTable::Table.from_i18n("FutariSousa.table.BGDG", locale),
            "BGDM" => DiceTable::Table.from_i18n("FutariSousa.table.BGDM", locale),
            "BGAJ" => DiceTable::Table.from_i18n("FutariSousa.table.BGAJ", locale),
            "BGAP" => DiceTable::Table.from_i18n("FutariSousa.table.BGAP", locale),
            "BGAI" => DiceTable::Table.from_i18n("FutariSousa.table.BGAI", locale),
            "HT" => DiceTable::Table.from_i18n("FutariSousa.table.HT", locale),
            "BT" => DiceTable::Table.from_i18n("FutariSousa.table.BT", locale),
            "GRT" => DiceTable::D66Table.from_i18n("FutariSousa.table.GRT", locale),
            "MIT" => DiceTable::D66Table.from_i18n("FutariSousa.table.MIT", locale),
            "JBT66" => DiceTable::D66Table.from_i18n("FutariSousa.table.JBT66", locale),
            "JBT10" => DiceTable::Table.from_i18n("FutariSousa.table.JBT10", locale),
            "FST66" => DiceTable::D66Table.from_i18n("FutariSousa.table.FST66", locale),
            "FST10" => DiceTable::Table.from_i18n("FutariSousa.table.FST10", locale),
            "LDT66" => DiceTable::D66Table.from_i18n("FutariSousa.table.LDT66", locale),
            "LDT10" => DiceTable::Table.from_i18n("FutariSousa.table.LDT10", locale),
            "FLT66" => DiceTable::D66Table.from_i18n("FutariSousa.table.FLT66", locale),
            "FLT10" => DiceTable::Table.from_i18n("FutariSousa.table.FLT10", locale),
            "NCT66" => DiceTable::D66Table.from_i18n("FutariSousa.table.NCT66", locale),
            "NCT10" => DiceTable::Table.from_i18n("FutariSousa.table.NCT10", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
