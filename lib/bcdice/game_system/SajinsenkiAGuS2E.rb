# frozen_string_literal: true

require 'bcdice/game_system/SajinsenkiAGuS'

module BCDice
  module GameSystem
    class SajinsenkiAGuS2E < SajinsenkiAGuS
      # ゲームシステムの識別子
      ID = 'SajinsenkiAGuS2E'

      # ゲームシステム名
      NAME = '砂塵戦機アーガス2ndEdition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'さしんせんきああかす2'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・一般判定Lv（チャンス出目0→判定0） nAG+x
        　　　nは習得レベル、Lv0の場合nの省略可能。xは判定値修正（数式による修正可）、省略した場合はレベル修正0
        　　　例）AG:習得レベル0の一般技能、1AG+1:習得レベル1・判定値修正+1の技能、AG+2-1：習得レベル0・判定値修正2-1の技能、(1-1)AG：習得レベル1・レベル修正-1の技能

        ・適正距離での命中判定（チャンス出目0→判定0、HR算出）OM+y@z
        　　　yは命中補正値（数式可）、zはクリティカル値。クリティカル値省略時は0
        　　　HRの算出時には、HRが大きくなる場合に出目0を10に読み替えます。
        　　　例）OM+18-6@2:命中補正値+18-6でクリティカル値2、適正距離の判定

        ・非適正距離での命中判定（チャンス出目0→判定0、HR算出）NM+y@z
        　　　yは命中補正値（数式可）、zはクリティカル値。クリティカル値省略時は0
        　　　HRの算出時には、HRが大きくなる場合に出目0を10に読み替えます。
        　　　例）NM+4-3:命中補正値+4-3で非適正距離の判定

        ・クリティカル表 CR
        ・鹵獲結果表　　 CAP
        ・幕間クエスト表 INT
        ・サルベージ表　 SAL

        ※通常の1D10などの10面ダイスにおいて出目10の読み替えはしません。コマンドのみです。

      INFO_MESSAGE_TEXT

      def eval_game_system_specific_command(command)
        roll_ippan(command) || roll_hit_check(command) || roll_tables(command, TABLES)
      end

      private


      TABLES = {
        "CR" => DiceTable::Table.new(
          "クリティカル表",
          "1D10",
          [
            "1：「小破」ダメージ+［5］。耐久値-［1］",
            "2：「小破」ダメージ+［5］。耐久値-［1］",
            "3：「小破」ダメージ+［5］。耐久値-［1］",
            "4：「小破」ダメージ+［5］。耐久値-［1］",
            "5：「兵装」損壊を受けるごとに［1D10］を振り、出目に応じた部位の兵装とオプションが《脱落》",
            "6：「上体」攻撃系能力［白兵/ 火器/ 索敵］は各［- 損壊Lv］",
            "7：「脚部」行動系・防御系能力［Iv 値（イニシア値）/ 最大MP/ 回避］は各［- 損壊Lv］",
            "8：「搭乗者」搭乗者の〈最大HP〉および〈HP〉は［-（4 ×損壊Lv）］",
            "9：「搭乗者」搭乗者の〈最大HP〉および〈HP〉は［-（4 ×損壊Lv）］",
            "0：「小破」ダメージ+［5］。耐久値-［1］",
          ]
        ),
        "CAP" => DiceTable::RangeTable.new(
          "鹵獲結果表",
          "2D10",
          [
            [0..2, '敵A:GuS を完全な状態で鹵獲︕ ※総合価格÷ 2 で売却可。'],
            [3..7, '敵A:GuS の兵装を鹵獲︕ ※敵A︓GuS の装備している任意の兵装1つを獲得。'],
            [8..13, '使えそうな兵装を発見︕ ※1D10 を振り、出目の部位の兵装1つを獲得。'],
            [14..20, '残念、完全にスクラップだ……。※部品代として［バランス値×300］cdtを獲得。'],
          ]
        ),
        "INT" => DiceTable::RangeTable.new(
          "幕間クエスト表",
          "2D10",
          [
            [0..20, ''],
          ]
        ),
        "SAL" => DiceTable::RangeTable.new(
          "サルベージ表",
          "2D10",
          [
            [0..20, ''],
          ]
        ),
      }.freeze
      register_prefix('-?\d*AG', 'OM', 'NM', 'CR', TABLES.keys)
    end
  end
end
