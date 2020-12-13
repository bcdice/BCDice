# frozen_string_literal: true

require "bcdice/dice_table/range_table"

module BCDice
  module GameSystem
    class FilledWith
      # マジカルクッキング表
      #
      # 別の表に飛ぶ場合は、遅延評価のためにlambdaでジャンプ先の表を括る。
      COOK_TABLES = {
        1 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 1）",
          "1D6",
          [
            [1, "おべんとミートボール"],
            [2, "パリパリ小魚"],
            [3, "キャロットタルト"],
            [4, "おにぎり"],
            [5..6, lambda { COOK_TABLES[2] }],
          ]
        ).freeze,

        2 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 2）",
          "1D6",
          [
            [1, "カリカリミミズ肉"],
            [2, "竹つきチクワ"],
            [3, "トロピカルジュース"],
            [4, "イナリ寿司"],
            [5..6, lambda { COOK_TABLES[3] }],
          ]
        ).freeze,

        3 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 3）",
          "1D6",
          [
            [1, "ホットミートパイ"],
            [2, "魔界魚の目玉"],
            [3, "パンプキンプリン"],
            [4, "スタミナ丼"],
            [5..6, lambda { COOK_TABLES[4] }],
          ]
        ).freeze,

        4 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 4）",
          "1D6",
          [
            [1, "ジャンボ串焼き"],
            [2, "シルヴァまっしぐら"],
            [3, "フラウアイスクリーム"],
            [4, "ピクニックランチ"],
            [5..6, lambda { COOK_TABLES[5] }],
          ]
        ).freeze,

        5 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 5）",
          "1D6",
          [
            [1, "グラント風香草焼き"],
            [2, "エドマエスシ"],
            [3, "スターフルーツパフェ"],
            [4, "具沢山本格カレー"],
            [5..6, lambda { COOK_TABLES[6] }],
          ]
        ).freeze,

        6 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 6）",
          "1D6",
          [
            [1, "ドラゴンステーキ"],
            [2, "刺身盛り合わせ"],
            [3, "エデンのアップルパイ"],
            [4, "フォートレス炒飯"],
            [5..6, lambda { COOK_TABLES[7] }],
          ]
        ).freeze,

        7 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 7）",
          "1D6",
          [
            [1, "マツザカスペシャル"],
            [2, "オオトロスシ"],
            [3, "スノーホワイトボンブ"],
            [4, "よもつへぐい"],
            [5..6, lambda { COOK_TABLES[8] }],
          ]
        ).freeze,

        8 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 8）",
          "1D6",
          [
            [1, "超特大マンガ肉"],
            [2, "特上うな丼"],
            [3, "魔将樹のかき氷"],
            [4, "ヘブンズランチ"],
            [5..6, lambda { COOK_TABLES[9] }],
          ]
        ).freeze,

        9 => DiceTable::RangeTable.new(
          "マジカルクッキング（Lv 9）",
          "1D6",
          [
            [1..3, "世界樹のサラダ"],
            [4..6, "黄金のラダマン鍋"],
          ]
        ).freeze,
      }.freeze
    end
  end
end
