module BCDice
  module GameSystem
    class MeikyuKingdomBasic
      # コモンアイテムランダム決定表(1D4)
      def mk_common_item_random_table(num)
        functionTable = [
          [1, lambda { mk_weapon_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [2, lambda { mk_life_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [3, lambda { mk_rest_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [4, lambda { mk_search_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
        ]
        return get_table_by_number(num, functionTable)
      end

      # レア一般アイテム決定表(1D6)
      def mk_rare_usual_item_random_table(num)
        functionTable = [
          [1, lambda { mk_normal_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [2, lambda { mk_normal_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [3, lambda { mk_normal_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [4, lambda { mk_advanced_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [5, lambda { mk_advanced_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [6, lambda { mk_advanced_rare_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
        ]
        return get_table_by_number(num, functionTable)
      end

      # レア武具アイテム決定表(1D6)
      def mk_rare_weapon_item_random_table(num)
        functionTable = [
          [1, lambda { mk_normal_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [2, lambda { mk_normal_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [3, lambda { mk_normal_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [4, lambda { mk_advanced_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [5, lambda { mk_advanced_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
          [6, lambda { mk_advanced_rare_weapon_item_table(@randomizer.roll_d66(D66SortType::NO_SORT)) }],
        ]
        return get_table_by_number(num, functionTable)
      end

      # 武具アイテム表(D66)
      # @override
      def mk_weapon_item_table(num)
        table = [
          [11, "だんびら"],
          [12, "網（だんびら）"],
          [13, "短剣"],
          [14, "戦斧"],
          [15, "盾"],
          [16, "ホウキ"],
          [22, "棘（だんびら）"],
          [23, "鑓"],
          [24, "石弓"],
          [25, "甲冑"],
          [26, "戦鎚"],
          [33, "鎖（だんびら）"],
          [34, "爆弾"],
          [35, "鉄砲"],
          [36, "大剣"],
          [44, "大弓（だんびら）"],
          [45, "徹甲弾"],
          [46, "拳銃"],
          [55, "手裏剣（だんびら）"],
          [56, "大砲"],
          [66, "籠手（だんびら）"],
        ]
        return get_table_by_number(num, table)
      end

      # 生活アイテム表(D66)
      # @override
      def mk_life_item_table(num)
        table = [
          [11, "鍋"],
          [12, "家畜（鍋）"],
          [13, "バックパック"],
          [14, "クラッカー"],
          [15, "がまぐち"],
          [16, "マント"],
          [22, "裁縫道具（鍋）"],
          [23, "カード"],
          [24, "エプロン"],
          [25, "住民台帳"],
          [26, "携帯電話"],
          [33, "外套（鍋）"],
          [34, "肖像画"],
          [35, "衣装"],
          [36, "山吹色のお菓子"],
          [44, "鏡（鍋）"],
          [45, "眼鏡"],
          [46, "クレジットカード"],
          [55, "召喚鍵（鍋）"],
          [56, "魔道書"],
          [66, "宝石（鍋）"],
        ]
        return get_table_by_number(num, table)
      end

      # 回復アイテム表(D66)
      # @override
      def mk_rest_item_table(num)
        table = [
          [11, "チョコレート（お弁当）"],
          [12, "砂糖菓子（お弁当）"],
          [13, "特効薬"],
          [14, "保存食"],
          [15, "担架"],
          [16, "お弁当（チョコレート）"],
          [22, "バナナ（お弁当）"],
          [23, "お酒"],
          [24, "珈琲"],
          [25, "フルコース"],
          [26, "ポーション"],
          [33, "魔素水（お弁当）"],
          [34, "救急箱"],
          [35, "強壮剤"],
          [36, "迷宮保険"],
          [44, "魔薬（お弁当）"],
          [45, "科学調味料"],
          [46, "惚れ薬"],
          [55, "軟膏（お弁当）"],
          [56, "復活薬"],
          [66, "万能薬（お弁当）"],
        ]
        return get_table_by_number(num, table)
      end

      # 探索アイテム表(D66)
      # @override
      def mk_search_item_table(num)
        table = [
          [11, "拷問具（星の欠片）"],
          [12, "ロープ（星の欠片）"],
          [13, "旗"],
          [14, "お守り"],
          [15, "星の欠片（拷問具）"],
          [16, "パワーリスト"],
          [22, "松明（星の欠片）"],
          [23, "テント"],
          [24, "楽器"],
          [25, "工具"],
          [26, "使い魔"],
          [33, "迷宮迷彩（星の欠片）"],
          [34, "乗騎"],
          [35, "罠百科"],
          [36, "迷宮防護服"],
          [44, "聴診器（星の欠片）"],
          [45, "地図"],
          [46, "時計"],
          [55, "飛行騎（星の欠片）"],
          [56, "カボチャの馬車"],
          [66, "もぐら棒（星の欠片）"],
        ]
        return get_table_by_number(num, table)
      end

      # 基本レア一般アイテム表(1D6+1D6)
      def mk_normal_rare_item_table(num)
        table = [
          [11, "愚者の冠"],
          [12, "香水"],
          [13, "煙玉"],
          [14, "悪名"],
          [15, "藁人形"],
          [16, "王妃の鏡"],
          [21, "星籠"],
          [22, "転ばぬ先の杖"],
          [23, "悟りの書"],
          [24, "鉛の兵隊"],
          [25, "黄金の林檎"],
          [26, "百年茸"],
          [31, "愚者の冠"],
          [32, "香水"],
          [33, "煙玉"],
          [34, "悪名"],
          [35, "藁人形"],
          [36, "王妃の鏡"],
          [41, "星籠"],
          [42, "転ばぬ先の杖"],
          [43, "悟りの書"],
          [44, "鉛の兵隊"],
          [45, "黄金の林檎"],
          [46, "百年茸"],
          [51, "操りロープ"],
          [52, "盗賊の七つ道具"],
          [53, "露眼鏡"],
          [54, "災厄王の遺物"],
          [55, "魔法の鞍"],
          [56, "琵琶"],
          [61, "兎の足"],
          [62, "視肉"],
          [63, "衛星帯"],
          [64, "魔法の絨毯"],
          [65, "軍配"],
          [66, "聖杯"],
        ]
        return get_table_by_number(num, table)
      end

      # 基本レア武具アイテム表(1D6+1D6)
      def mk_normal_rare_weapon_item_table(num)
        table = [
          [11, "蛍矢"],
          [12, "小麦粉"],
          [13, "喇叭銃"],
          [14, "まわし"],
          [15, "しゃべる剣"],
          [16, "大盾"],
          [21, "王笏"],
          [22, "ぬいぐるみ"],
          [23, "魔杖"],
          [24, "獣の毛皮"],
          [25, "バカには見えない鎧"],
          [26, "ビキニアーマー"],
          [31, "蛍矢"],
          [32, "小麦粉"],
          [33, "喇叭銃"],
          [34, "まわし"],
          [35, "しゃべる剣"],
          [36, "大盾"],
          [41, "王笏"],
          [42, "ぬいぐるみ"],
          [43, "魔杖"],
          [44, "獣の毛皮"],
          [45, "バカには見えない鎧"],
          [46, "ビキニアーマー"],
          [51, "チェインソード"],
          [52, "輝く者"],
          [53, "貪る者"],
          [54, "滅ぼす者"],
          [55, "機械の体"],
          [56, "刈り取る者"],
          [61, "断ち切る者"],
          [62, "竜の鱗鎧"],
          [63, "射貫く者"],
          [64, "貫く者"],
          [65, "剥ぎ取る者"],
          [66, "王剣"],
        ]
        return get_table_by_number(num, table)
      end

      # 上級レア一般アイテム表(1D6+1D6)
      def mk_advanced_rare_item_table(num)
        table = [
          [11, "砂時計週報"],
          [12, "兵糧丸"],
          [13, "遊星葉書"],
          [14, "百科辞典"],
          [15, "夢枕"],
          [16, "蓄音機"],
          [21, "砂時計週報"],
          [22, "兵糧丸"],
          [23, "遊星葉書"],
          [24, "百科辞典"],
          [25, "夢枕"],
          [26, "蓄音機"],
          [31, "水晶球"],
          [32, "狭間の棺桶"],
          [33, "不思議なたまご"],
          [34, "魔法瓶"],
          [35, "不死鳥の羽飾り"],
          [36, "紅葫蘆"],
          [41, "水晶球"],
          [42, "狭間の棺桶"],
          [43, "不思議なたまご"],
          [44, "魔法瓶"],
          [45, "不死鳥の羽飾り"],
          [46, "紅葫蘆"],
          [51, "打ち出の小槌"],
          [52, "消火器"],
          [53, "滅びの予言書"],
          [54, "召魔鏡"],
          [55, "鉄仮面"],
          [56, "愛"],
          [61, "打ち出の小槌"],
          [62, "消火器"],
          [63, "滅びの予言書"],
          [64, "召魔鏡"],
          [65, "鉄仮面"],
          [66, "愛"],
        ]
        return get_table_by_number(num, table)
      end

      # 上級レア武具アイテム表(1D6+1D6)
      def mk_advanced_rare_weapon_item_table(num)
        table = [
          [11, "虚弾"],
          [12, "小鬼の襟巻"],
          [13, "眼弾"],
          [14, "釣竿"],
          [15, "虹柱"],
          [16, "服従の鞭"],
          [21, "虚弾"],
          [22, "小鬼の襟巻"],
          [23, "眼弾"],
          [24, "釣竿"],
          [25, "虹柱"],
          [26, "服従の鞭"],
          [31, "星の杖"],
          [32, "聖印"],
          [33, "迷い傘"],
          [34, "邪眼"],
          [35, "徒手空拳"],
          [36, "隠れ兜"],
          [41, "星の杖"],
          [42, "聖印"],
          [43, "迷い傘"],
          [44, "邪眼"],
          [45, "徒手空拳"],
          [46, "隠れ兜"],
          [51, "太刀鋏"],
          [52, "破城槌"],
          [53, "黄金の鶴嘴"],
          [54, "ムラサマ"],
          [55, "君主の衣"],
          [56, "蒸気甲冑"],
          [61, "太刀鋏"],
          [62, "破城槌"],
          [63, "黄金の鶴嘴"],
          [64, "ムラサマ"],
          [65, "君主の衣"],
          [66, "蒸気甲冑"],
        ]
        return get_table_by_number(num, table)
      end

      # デヴァイス・ファクトリー
      # @override
      def mk_device_factory_table(num)
        dice = @randomizer.roll_once(6)
        output = "ベースアイテム：" + mk_item_random_table(dice) + " （もしくは任意のアイテム）"

        if num <= 0
          num = 1
        end
        num.times do |_i|
          dice = @randomizer.roll_sum(2, 6)
          output += "\n" + mk_item_features_table(dice)
          debug("output", output)
        end
        return output
      end

      # アイテムカテゴリ決定表 (1D6)
      def mk_item_random_table(num)
        functionTable = [
          [1, lambda { mk_weapon_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [2, lambda { mk_life_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [3, lambda { mk_rest_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [4, lambda { mk_search_item_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [5, lambda { mk_rare_usual_item_random_table(roll(1, 6)) }],
          [6, lambda { mk_rare_weapon_item_random_table(roll(1, 6)) }],
        ]
        return get_table_by_number(num, functionTable)
      end

      # アイテムの特性決定表(2D6)
      # @override
      def mk_item_features_table(num)
        output = ""
        dice = @randomizer.roll_sum(2, 6)

        if num <= 2
          d1 = @randomizer.roll_once(6)
          output = "そのアイテムは「" + mk_item_power_table(d1) + "」の神力を宿す。"
        elsif num <= 3
          output = "そのアイテムは寿命を持つ。寿命の値を決定する。" + "\n"
          output += "さらに、" + mk_item_features_table(dice)
        elsif num <= 4
          output = "そのアイテムは境界障壁を持つ。《HP》の値を決定する。"
        elsif num <= 5
          output = "そのアイテムは銘を持つ。銘を決定する。"
        elsif num <= 6
          d1 = @randomizer.roll_once(6)
          output = "そのアイテムは合成具である。もう1つの機能は「" + mk_item_random_table(d1) + "」である。"
        elsif num <= 7
          output = "そのアイテムにレベルがあれば、レベルを1点上昇する。" + "\n"
          output += "レベルが設定されていなければ、" + mk_item_features_table(dice)
        elsif num <= 8
          output = "そのアイテムは「" + mk_item_jyumon_table(dice) + "」の呪紋を持つ。"
        elsif num <= 9
          d1 = @randomizer.roll_once(6)
          output = "そのアイテムは「" + mk_item_jyuka_table(d1) + "」の呪禍を持つ。" + "\n"
          output += "さらに、" + mk_item_features_table(dice)
        elsif num <= 10
          output = "そのアイテムは高価だ。価格を設定する。"
        elsif num <= 11
          d1 = @randomizer.roll_once(6)
          output = "そのアイテムは「条件：" + mk_item_aptitude_table(d1) + "」の適正を持つ。" + "\n"
          output += "さらに、" + mk_item_features_table(dice)
        else
          d1 = @randomizer.roll_once(6)
          output = "そのアイテムは「" + mk_item_attribute_table(d1) + "」の属性を持つ。"
        end

        return "特性[" + num.to_s + "]：" + output
      end

      # 神力決定表(1D6)
      # @override
      def mk_item_power_table(num)
        table = [
          [1, "才覚"],
          [2, "魅力"],
          [3, "探索"],
          [4, "武勇"],
          [5, "《器》"],
          [6, "《回避値》"],
        ]
        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 呪紋決定表(2D6)
      # @override
      def mk_item_jyumon_table(num)
        table = [
          [2, "ランダムに選んだモンスターカテゴリ1種のうち、【人類の敵】未習得かつ（2D6）レベル以下のモンスタースキル"],
          [3, "便利スキルから好きなスキル1種"],
          [4, "芸能スキルから好きなスキル1種"],
          [5, "迷宮スキルから好きなスキル1種"],
          [6, "星術スキルから好きなスキル1種"],
          [7, "一般スキルから好きなスキル1種"],
          [8, "召喚スキルから好きなスキル1種"],
          [9, "科学スキルから好きなスキル1種"],
          [10, "交渉スキルから好きなスキル1種"],
          [11, "神官のクラススキルから好きなスキル1種"],
          [12, "生まれ表を使用してランダムに決めたジョブのジョブスキル"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 呪禍表(1D6)
      # @override
      def mk_item_jyuka_table(num)
        table = [
          [1, "このアイテムを装備している限り「呪い3」の変調を受ける"],
          [2, "このアイテムを装備している限り「肥満3」の変調を受ける"],
          [3, "このアイテムを装備している限り「憤怒」の変調を受ける"],
          [4, "このアイテムを装備している限り「毒2」の変調を受ける"],
          [5, "このアイテムを装備している限り、条件を満たしても誰とも人間関係を結べない"],
          [6, "このアイテムを装備している限り「散漫1」の変調を受ける"],
        ]
        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 適正表(1D6)
      # @override
      def mk_item_aptitude_table(num)
        table = [
          [1, "ランダムなクラス1種であること"],
          [2, "生まれ表でランダムに選んだジョブであること"],
          [3, lambda { mk_gender_table(@randomizer.roll_once(6)) }],
          [4, "上級ジョブであること"],
          [5, "モンスタースキルを修得していること"],
          [6, "童貞、もしくは処女であること"],
        ]
        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 属性表(1D6)
      # @override
      def mk_item_attribute_table(num)
        table = [
          [1, "自然の力。10レベル以下の人間カテゴリのモンスターと重要NPC"],
          [2, "幻夢の力。10レベル以下の異形と呪物カテゴリのモンスター"],
          [3, "星炎の力。10レベル以下の魔獣と鬼族カテゴリのモンスター"],
          [4, "暗黒の力。10レベル以下の妖精と天使カテゴリのモンスター"],
          [5, "聖なる力。10レベル以下の死霊と深人カテゴリのモンスター"],
          [6, "災厄の力。支配者として設定されているキャラクター"],
        ]

        return "[#{num}]" + get_table_by_number(num, table)
      end

      # 性別決定用
      # @override
      def mk_gender_table(num)
        output = "1"

        if num.odd?
          output = "性別が男であること"
        else
          output = "性別が女であること"
        end

        return output
      end
    end
  end
end
