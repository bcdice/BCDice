# frozen_string_literal: true

module BCDice
  module GameSystem
    class MeikyuKingdomBasic
      WEAPON_ITEM_TABLE = DiceTable::D66Table.new(
        "武具アイテム表",
        D66SortType::ASC,
        {
          11 => "だんびら",
          12 => "網（だんびら）",
          13 => "短剣",
          14 => "戦斧",
          15 => "盾",
          16 => "ホウキ",
          22 => "棘（だんびら）",
          23 => "鑓",
          24 => "石弓",
          25 => "甲冑",
          26 => "戦鎚",
          33 => "鎖（だんびら）",
          34 => "爆弾",
          35 => "鉄砲",
          36 => "大剣",
          44 => "大弓（だんびら）",
          45 => "徹甲弾",
          46 => "拳銃",
          55 => "手裏剣（だんびら）",
          56 => "大砲",
          66 => "籠手（だんびら）",
        }
      )

      LIFE_ITEM_TABLE = DiceTable::D66Table.new(
        "生活アイテム表",
        D66SortType::ASC,
        {
          11 => "鍋",
          12 => "家畜（鍋）",
          13 => "バックパック",
          14 => "クラッカー",
          15 => "がまぐち",
          16 => "マント",
          22 => "裁縫道具（鍋）",
          23 => "カード",
          24 => "エプロン",
          25 => "住民台帳",
          26 => "携帯電話",
          33 => "外套（鍋）",
          34 => "肖像画",
          35 => "衣装",
          36 => "山吹色のお菓子",
          44 => "鏡（鍋）",
          45 => "眼鏡",
          46 => "クレジットカード",
          55 => "召喚鍵（鍋）",
          56 => "魔道書",
          66 => "宝石（鍋）",
        }
      )

      REST_ITEM_TABLE = DiceTable::D66Table.new(
        "回復アイテム表",
        D66SortType::ASC,
        {
          11 => "チョコレート（お弁当）",
          12 => "砂糖菓子（お弁当）",
          13 => "特効薬",
          14 => "保存食",
          15 => "担架",
          16 => "お弁当（チョコレート）",
          22 => "バナナ（お弁当）",
          23 => "お酒",
          24 => "珈琲",
          25 => "フルコース",
          26 => "ポーション",
          33 => "魔素水（お弁当）",
          34 => "救急箱",
          35 => "強壮剤",
          36 => "迷宮保険",
          44 => "魔薬（お弁当）",
          45 => "科学調味料",
          46 => "惚れ薬",
          55 => "軟膏（お弁当）",
          56 => "復活薬",
          66 => "万能薬（お弁当）",
        }
      )

      SEARCH_ITEM_TABLE = DiceTable::D66Table.new(
        "探索アイテム表",
        D66SortType::ASC,
        {
          11 => "拷問具（星の欠片）",
          12 => "ロープ（星の欠片）",
          13 => "旗",
          14 => "お守り",
          15 => "星の欠片（拷問具）",
          16 => "パワーリスト",
          22 => "松明（星の欠片）",
          23 => "テント",
          24 => "楽器",
          25 => "工具",
          26 => "使い魔",
          33 => "迷宮迷彩（星の欠片）",
          34 => "乗騎",
          35 => "罠百科",
          36 => "迷宮防護服",
          44 => "聴診器（星の欠片）",
          45 => "地図",
          46 => "時計",
          55 => "飛行騎（星の欠片）",
          56 => "カボチャの馬車",
          66 => "もぐら棒（星の欠片）",
        }
      )

      COMMON_ITEM_RANDOM_TABLE = DiceTable::ChainTable.new(
        "コモンアイテムランダム決定表",
        "1D4",
        [
          WEAPON_ITEM_TABLE,
          LIFE_ITEM_TABLE,
          REST_ITEM_TABLE,
          SEARCH_ITEM_TABLE,
        ]
      )

      NORMAL_RARE_ITEM_TABLE = DiceTable::D66GridTable.new(
        "基本レア一般アイテム表",
        [
          ["愚者の冠", "香水", "煙玉", "悪名", "藁人形", "王妃の鏡"],
          ["星籠", "転ばぬ先の杖", "悟りの書", "鉛の兵隊", "黄金の林檎", "百年茸"],
          ["愚者の冠", "香水", "煙玉", "悪名", "藁人形", "王妃の鏡"],
          ["星籠", "転ばぬ先の杖", "悟りの書", "鉛の兵隊", "黄金の林檎", "百年茸"],
          ["操りロープ", "盗賊の七つ道具", "露眼鏡", "災厄王の遺物", "魔法の鞍", "琵琶"],
          ["兎の足", "視肉", "衛星帯", "魔法の絨毯", "軍配", "聖杯"],
        ]
      )

      ADVANCED_RARE_ITEM_TABLE = DiceTable::D66GridTable.new(
        "上級レア一般アイテム表",
        [
          ["砂時計週報", "兵糧丸", "遊星葉書", "百科辞典", "夢枕", "蓄音機"],
          ["砂時計週報", "兵糧丸", "遊星葉書", "百科辞典", "夢枕", "蓄音機"],
          ["水晶球", "狭間の棺桶", "不思議なたまご", "魔法瓶", "不死鳥の羽飾り", "紅葫蘆"],
          ["水晶球", "狭間の棺桶", "不思議なたまご", "魔法瓶", "不死鳥の羽飾り", "紅葫蘆"],
          ["打ち出の小槌", "消火器", "滅びの予言書", "召魔鏡", "鉄仮面", "愛"],
          ["打ち出の小槌", "消火器", "滅びの予言書", "召魔鏡", "鉄仮面", "愛"],
        ]
      )

      RARE_ITEM_RANDOM_TABLE = DiceTable::ChainTable.new(
        "レア一般アイテムランダム決定表",
        "1D6",
        [
          NORMAL_RARE_ITEM_TABLE,
          NORMAL_RARE_ITEM_TABLE,
          NORMAL_RARE_ITEM_TABLE,
          ADVANCED_RARE_ITEM_TABLE,
          ADVANCED_RARE_ITEM_TABLE,
          ADVANCED_RARE_ITEM_TABLE,
        ]
      )

      NORMAL_RARE_WEAPON_ITEM_TABLE = DiceTable::D66GridTable.new(
        "基本レア武具アイテム表",
        [
          ["蛍矢", "小麦粉", "喇叭銃", "まわし", "しゃべる剣", "大盾"],
          ["王笏", "ぬいぐるみ", "魔杖", "獣の毛皮", "バカには見えない鎧", "ビキニアーマー"],
          ["蛍矢", "小麦粉", "喇叭銃", "まわし", "しゃべる剣", "大盾"],
          ["王笏", "ぬいぐるみ", "魔杖", "獣の毛皮", "バカには見えない鎧", "ビキニアーマー"],
          ["チェインソード", "輝く者", "貪る者", "滅ぼす者", "機械の体", "刈り取る者"],
          ["断ち切る者", "竜の鱗鎧", "射貫く者", "貫く者", "剥ぎ取る者", "王剣"],
        ]
      )

      ADVANCED_RARE_WEAPON_ITEM_TABLE = DiceTable::D66GridTable.new(
        "上級レア武具アイテム表",
        [
          ["虚弾", "小鬼の襟巻", "眼弾", "釣竿", "虹柱", "服従の鞭"],
          ["虚弾", "小鬼の襟巻", "眼弾", "釣竿", "虹柱", "服従の鞭"],
          ["星の杖", "聖印", "迷い傘", "邪眼", "徒手空拳", "隠れ兜"],
          ["星の杖", "聖印", "迷い傘", "邪眼", "徒手空拳", "隠れ兜"],
          ["太刀鋏", "破城槌", "黄金の鶴嘴", "ムラサマ", "君主の衣", "蒸気甲冑"],
          ["太刀鋏", "破城槌", "黄金の鶴嘴", "ムラサマ", "君主の衣", "蒸気甲冑"],
        ]
      )

      RARE_WEAPON_ITEM_RANDOM_TABLE = DiceTable::ChainTable.new(
        "レア武具アイテムランダム決定表",
        "1D6",
        [
          NORMAL_RARE_WEAPON_ITEM_TABLE,
          NORMAL_RARE_WEAPON_ITEM_TABLE,
          NORMAL_RARE_WEAPON_ITEM_TABLE,
          ADVANCED_RARE_WEAPON_ITEM_TABLE,
          ADVANCED_RARE_WEAPON_ITEM_TABLE,
          ADVANCED_RARE_WEAPON_ITEM_TABLE,
        ]
      )

      # デヴァイス・ファクトリー
      def roll_device_factory_table(num)
        item = ITEM_RANDOM_TABLE.roll(@randomizer).last_body
        intro = "デヴァイス・ファクトリー表 (特性#{num}個) ＞ ベースアイテム：#{item}（もしくは任意のアイテム）"

        num = [0, num].max
        feature_list = Array.new(num) { ITEM_FEATURES_TABLE.roll(randomizer) }
        return [intro, *feature_list].join("\n")
      end

      # アイテムカテゴリ決定表 (1D6)
      ITEM_RANDOM_TABLE = DiceTable::ChainTable.new(
        "アイテムカテゴリ決定表",
        "1D6",
        [
          WEAPON_ITEM_TABLE,
          LIFE_ITEM_TABLE,
          REST_ITEM_TABLE,
          SEARCH_ITEM_TABLE,
          RARE_ITEM_RANDOM_TABLE,
          RARE_WEAPON_ITEM_RANDOM_TABLE,
        ]
      )

      class ItemFeature
        def initialize(name, type, items)
          @name = name
          @times, @sides = type.split("D", 2).map(&:to_i)
          @items = items
        end

        def choice(randomizer)
          dice = randomizer.roll_sum(@times, @sides)
          index = dice - @times

          chosen = @items[index]
          chosen = chosen.choice(randomizer) if chosen.respond_to?(:choice)

          return "[#{dice}]#{chosen}"
        end
      end

      ITEM_POWER_TABLE = ItemFeature.new(
        "神力決定表",
        "1D6",
        [
          "才覚",
          "魅力",
          "探索",
          "武勇",
          "《器》",
          "《回避値》",
        ]
      )

      ITEM_JYUMON_TABLE = ItemFeature.new(
        "呪紋決定表",
        "2D6",
        [
          "ランダムに選んだモンスターカテゴリ1種のうち、【人類の敵】未習得かつ（2D6）レベル以下のモンスタースキル",
          "便利スキルから好きなスキル1種",
          "芸能スキルから好きなスキル1種",
          "迷宮スキルから好きなスキル1種",
          "星術スキルから好きなスキル1種",
          "一般スキルから好きなスキル1種",
          "召喚スキルから好きなスキル1種",
          "科学スキルから好きなスキル1種",
          "交渉スキルから好きなスキル1種",
          "神官のクラススキルから好きなスキル1種",
          "生まれ表を使用してランダムに決めたジョブのジョブスキル",
        ]
      )

      ITEM_JYUKA_TABLE = ItemFeature.new(
        "呪禍表",
        "1D6",
        [
          "このアイテムを装備している限り「呪い3」の変調を受ける",
          "このアイテムを装備している限り「肥満3」の変調を受ける",
          "このアイテムを装備している限り「憤怒」の変調を受ける",
          "このアイテムを装備している限り「毒2」の変調を受ける",
          "このアイテムを装備している限り、条件を満たしても誰とも人間関係を結べない",
          "このアイテムを装備している限り「散漫1」の変調を受ける",
        ]
      )

      GENDER_TABLE = ItemFeature.new(
        "性別決定表",
        "1D6",
        [
          "性別が男であること",
          "性別が女であること",
          "性別が男であること",
          "性別が女であること",
          "性別が男であること",
          "性別が女であること",
        ]
      )

      ITEM_APTITUDE_TABLE = ItemFeature.new(
        "適正表",
        "1D6",
        [
          "ランダムなクラス1種であること",
          "生まれ表でランダムに選んだジョブであること",
          GENDER_TABLE,
          "上級ジョブであること",
          "モンスタースキルを修得していること",
          "童貞、もしくは処女であること",
        ]
      )

      ITEM_ATTRIBUTE_TABLE = ItemFeature.new(
        "属性表",
        "1D6",
        [
          "自然の力。10レベル以下の人間カテゴリのモンスターと重要NPC",
          "幻夢の力。10レベル以下の異形と呪物カテゴリのモンスター",
          "星炎の力。10レベル以下の魔獣と鬼族カテゴリのモンスター",
          "暗黒の力。10レベル以下の妖精と天使カテゴリのモンスター",
          "聖なる力。10レベル以下の死霊と深人カテゴリのモンスター",
          "災厄の力。支配者として設定されているキャラクター",
        ]
      )

      class ItemFeaturesTable
        def initialize
          @items = [
            ["そのアイテムは「", ITEM_POWER_TABLE, "」の神力を宿す。"],
            ["そのアイテムは寿命を持つ。寿命の値を決定する。\nさらに、", self],
            ["そのアイテムは境界障壁を持つ。《HP》の値を決定する。"],
            ["そのアイテムは銘を持つ。銘を決定する。"],
            ["そのアイテムは合成具である。もう1つの機能は「", ITEM_RANDOM_TABLE, "」である。"],
            ["そのアイテムにレベルがあれば、レベルを1点上昇する。\nレベルが設定されていなければ、", self],
            ["そのアイテムは「", ITEM_JYUMON_TABLE, "」の呪紋を持つ。"],
            ["そのアイテムは「", ITEM_JYUKA_TABLE, "」の呪禍を持つ。\nさらに、", self],
            ["そのアイテムは高価だ。価格を設定する。"],
            ["そのアイテムは「条件：", ITEM_APTITUDE_TABLE, "」の適正を持つ。\nさらに、", self],
            ["そのアイテムは「", ITEM_ATTRIBUTE_TABLE, "」の属性を持つ。"],
          ].freeze
        end

        def roll(randomizer)
          dice = randomizer.roll_sum(2, 6)
          index = dice - 2
          chosen_row = @items[index]

          string_list = chosen_row.map do |s|
            case s
            when String
              s
            when ItemFeature
              s.choice(randomizer)
            else
              s.roll(randomizer)
            end
          end

          return "特性[#{dice}]：#{string_list.join('')}"
        end
      end

      ITEM_FEATURES_TABLE = ItemFeaturesTable.new().freeze

      ITEM_TABLES = {
        "WIT" => WEAPON_ITEM_TABLE,
        "LIT" => LIFE_ITEM_TABLE,
        "RIT" => REST_ITEM_TABLE,
        "SIT" => SEARCH_ITEM_TABLE,
        "CIR" => COMMON_ITEM_RANDOM_TABLE,
        "NRUT" => NORMAL_RARE_ITEM_TABLE,
        "ARUT" => ADVANCED_RARE_ITEM_TABLE,
        "RUIR" => RARE_ITEM_RANDOM_TABLE,
        "NRWT" => NORMAL_RARE_WEAPON_ITEM_TABLE,
        "ARWT" => ADVANCED_RARE_WEAPON_ITEM_TABLE,
        "RWIR" => RARE_WEAPON_ITEM_RANDOM_TABLE,
      }.freeze
    end
  end
end
