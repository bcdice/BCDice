# frozen_string_literal: true

module BCDice
  module GameSystem
    class MeikyuKingdom
      # デバイスファクトリー(1D6)
      def mk_device_factory_table()
        output = mk_item_decide_table(@randomizer.roll_once(6))

        dice = @randomizer.roll_sum(2, 6)
        output = output + " / " + mk_item_features_table(dice)
        return output
      end

      # アイテムカテゴリ決定表(1D6)
      def mk_item_decide_table(num)
        functionTable = [
          [1, lambda { mk_weapon_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [2, lambda { mk_life_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [3, lambda { mk_rest_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [4, lambda { mk_search_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [5, lambda { mk_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [6, lambda { mk_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
        ]
        return get_table_by_number(num, functionTable)
      end

      # 武具アイテム表(D66)
      def mk_weapon_item_table(num)
        table = [
          [11, "だんびら"],
          [12, "だんびら"],
          [13, "ダガー"],
          [14, "戦斧"],
          [15, "盾"],
          [16, "鑓"],
          [22, "籠手（だんびら）"],
          [23, "手裏剣"],
          [24, "石弓"],
          [25, "甲冑"],
          [26, "戦鎚"],
          [33, "大弓（だんびら）"],
          [34, "爆弾"],
          [35, "鉄砲"],
          [36, "大剣"],
          [44, "拳銃（だんびら）"],
          [45, "ホウキ"],
          [46, "徹甲弾"],
          [55, "だんびら"],
          [56, "大砲"],
          [66, "だんびら"],
        ]

        return get_table_by_number(num, table)
      end

      # 生活アイテム表(D66)
      def mk_life_item_table(num)
        table = [
          [11, "バックパック"],
          [12, "バックパック"],
          [13, "鍋"],
          [14, "クラッカー"],
          [15, "がまぐち"],
          [16, "マント"],
          [22, "法衣（バックパック）"],
          [23, "カード"],
          [24, "エプロン"],
          [25, "住民台帳"],
          [26, "携帯電話"],
          [33, "召喚鍵（バックパック）"],
          [34, "肖像画"],
          [35, "衣装"],
          [36, "山吹色のお菓子"],
          [44, "バックパック"],
          [45, "眼鏡"],
          [46, "クレジットカード"],
          [55, "バックパック"],
          [56, "魔道書"],
          [66, "バックパック"],
        ]

        return get_table_by_number(num, table)
      end

      # 回復アイテム表(D66)
      def mk_rest_item_table(num)
        table = [
          [11, "お弁当"],
          [12, "お弁当"],
          [13, "特効薬"],
          [14, "保存食"],
          [15, "担架"],
          [16, "珈琲"],
          [22, "軟膏（お弁当）"],
          [23, "チョコレート"],
          [24, "お酒"],
          [25, "フルコース"],
          [26, "ポーション"],
          [33, "お弁当"],
          [34, "救急箱"],
          [35, "強壮剤"],
          [36, "迷宮保険"],
          [44, "お弁当"],
          [45, "科学調味料"],
          [46, "惚れ薬"],
          [55, "お弁当"],
          [56, "復活薬"],
          [66, "お弁当"],
        ]

        return get_table_by_number(num, table)
      end

      # 探索アイテム表(D66)
      def mk_search_item_table(num)
        table = [
          [11, "星の欠片"],
          [12, "星の欠片"],
          [13, "旗"],
          [14, "お守り"],
          [15, "拷問具"],
          [16, "パワーリスト"],
          [22, "工具（星の欠片）"],
          [23, "テント"],
          [24, "楽器"],
          [25, "使い魔"],
          [26, "乗騎"],
          [33, "迷宮迷彩（星の欠片）"],
          [34, "罠百科"],
          [35, "迷宮防護服"],
          [36, "地図"],
          [44, "星の欠片"],
          [45, "時計"],
          [46, "もぐら棒"],
          [55, "星の欠片"],
          [56, "カボチャの馬車"],
          [66, "星の欠片"],
        ]

        return get_table_by_number(num, table)
      end

      # レア武具アイテム表(1D6+1D6)
      def mk_rare_weapon_item_table(num)
        table = [
          [11, "虚弾"],
          [12, "怪物毒"],
          [13, "小鬼の襟巻"],
          [14, "喇叭銃"],
          [15, "蛍矢"],
          [16, "大盾"],
          [21, "まわし"],
          [22, "怪物毒"],
          [23, "しゃべる剣"],
          [24, "小麦粉"],
          [25, "王笏"],
          [26, "服従の鞭"],
          [31, "ぬいぐるみ"],
          [32, "魔杖"],
          [33, "怪物毒"],
          [34, "星衣"],
          [35, "聖印"],
          [36, "獣の毛皮"],
          [41, "日傘"],
          [42, "チェインソード"],
          [43, "邪眼"],
          [44, "怪物毒"],
          [45, "徒手空拳"],
          [46, "バカには見えない鎧"],
          [51, "ビキニアーマー"],
          [52, "輝く者"],
          [53, "貪る者"],
          [54, "滅ぼす者"],
          [55, "機械の体"],
          [56, "破城槌"],
          [61, "刈り取る者"],
          [62, "貫く者"],
          [63, "黄金の鶴嘴"],
          [64, "ムラサマ"],
          [65, "蒸気甲冑"],
          [66, "王剣"],
        ]

        return get_table_by_number(num, table)
      end

      # レア一般アイテム表(1D6+1D6)
      def mk_rare_item_table(num)
        table = [
          [11, "ブルーリボン"],
          [12, "聖痕"],
          [13, "剥製"],
          [14, "愚者の冠"],
          [15, "名刺"],
          [16, "種籾"],
          [21, "香水"],
          [22, "守りの指輪（名刺）"],
          [23, "煙玉"],
          [24, "悪名"],
          [25, "藁人形"],
          [26, "パワー餌"],
          [31, "王妃の鏡"],
          [32, "蓄音機"],
          [33, "無限の心臓（名刺）"],
          [34, "星籠"],
          [35, "水晶球"],
          [36, "転ばぬ先の杖"],
          [41, "悟りの書"],
          [42, "操りロープ"],
          [43, "盗賊の七つ道具"],
          [44, "携帯算術機（名刺）"],
          [45, "棺桶"],
          [46, "カメラ"],
          [51, "不思議なたまご"],
          [52, "ブーケ"],
          [53, "露眼鏡"],
          [54, "災厄王の遺物"],
          [55, "経験値"],
          [56, "鞍"],
          [61, "視肉"],
          [62, "玉璽"],
          [63, "衛星帯"],
          [64, "軍配"],
          [65, "聖杯"],
          [66, "愛"],
        ]

        return get_table_by_number(num, table)
      end

      # アイテムの特性決定表(2D6)
      def mk_item_features_table(num)
        output = ""
        dice = @randomizer.roll_sum(2, 6)

        if num <= 2
          output = "「" + mk_item_power_table(@randomizer.roll_once(6)) + "」の神力を宿す"
        elsif num <= 3
          output = "寿命を持つ。寿命の値を決定する。" + "\n"
          output += "さらに、" + mk_item_features_table(dice)
        elsif num <= 4
          output = "境界障壁を持つ。《HP》の値を決定する。"
        elsif num <= 5
          output = "銘を持つ。銘を決定する。"
        elsif num <= 6
          output = "合成具である。もう1つの機能は「" + mk_item_decide_table(@randomizer.roll_once(6)) + "」である。"
        elsif num <= 7
          output = "そのアイテムにレベルがあれば、レベルを1点上昇する。" + "\n"
          output += "レベルが設定されていなければ、" + mk_item_features_table(dice)
        elsif num <= 8
          output = "「" + mk_item_jyumon_table(dice) + "」の呪紋を持つ。"
        elsif num <= 9
          output = "「" + mk_item_jyuka_table(@randomizer.roll_once(6)) + "」の呪禍を持つ。" + "\n"
          output += "さらに、" + mk_item_features_table(dice)
        elsif num <= 10
          output = "高価だ。価格を設定する。"
        elsif num <= 11
          output = "「条件：" + mk_item_aptitude_table(@randomizer.roll_once(6)) + "」の適性を持つ。" + "\n"
          output += "さらに、" + mk_item_features_table(dice)
        else
          output = "「" + mk_item_attribute_table(@randomizer.roll_once(6)) + "」の属性を持つ。"
        end

        return "特性[" + num.to_s + "]：" + output
      end

      # 神力決定表(1D6)
      def mk_item_power_table(num)
        table = [
          [1, "〔才覚〕"],
          [2, "〔魅力〕"],
          [3, "〔探索〕"],
          [4, "〔武勇〕"],
          [5, "〈器〉"],
          [6, "〈回避値〉"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 呪紋決定表(2D6)
      def mk_item_jyumon_table(num)
        table = [
          [2, "モンスタースキル"],
          [3, "便利スキル"],
          [4, "芸能スキル"],
          [5, "迷宮スキル"],
          [6, "星術スキル"],
          [7, "一般スキル"],
          [8, "召喚スキル"],
          [9, "科学スキル"],
          [10, "交渉スキル"],
          [11, "神官のクラススキル"],
          [12, "ジョブスキル"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 呪禍表(1D6)
      def mk_item_jyuka_table(num)
        table = [
          [1, "「呪い」のバッドステータス"],
          [2, "「肥満」のバッドステータス"],
          [3, "「愚か」のバッドステータス"],
          [4, "サイクルの終了時に《HP》が1点減少する"],
          [5, "条件を満たしても誰とも人間関係を結べない"],
          [6, "〈器〉が1点減少する"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 適正表(1D6)
      def mk_item_aptitude_table(num)
        table = [
          [1, "ランダムなクラス1種"],
          [2, lambda { mk_family_business_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [3, lambda { mk_gender_table(@randomizer.roll_once(6)) + "性" }],
          [4, "上級ジョブ"],
          [5, "モンスタースキルを修得"],
          [6, "童貞、もしくは処女"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 属性表(1D6)
      def mk_item_attribute_table(num)
        table = [
          [1, "自然の力"],
          [2, "幻夢の力"],
          [3, "星炎の力"],
          [4, "暗黒の力"],
          [5, "聖なるの力"],
          [6, "災厄の力"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      def mk_gender_table(num)
        output = "1"

        if num.odd?
          output = "男"
        else
          output = "女"
        end

        return output
      end

      # 生まれ表(D66)
      def mk_family_business_table(num)
        table = [
          [11, "星術師"],
          [12, "魔道師"],
          [13, "召喚師"],
          [14, "博士"],
          [15, "医者"],
          [16, "貴族"],
          [22, "宦官"],
          [23, "武人"],
          [24, "処刑人"],
          [25, "衛視"],
          [26, "商人"],
          [33, "迷宮職人"],
          [34, "亭主"],
          [35, "料理人"],
          [36, "寿ぎ屋"],
          [44, "働きもの"],
          [45, "狩人"],
          [46, "冒険者"],
          [55, "怠け者"],
          [56, "盗賊"],
          [66, "生まれ表の中から、好きなジョブ1つを選ぶ"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end
    end
  end
end
