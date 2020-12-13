# frozen_string_literal: true

require "bcdice/dice_table/range_table"

module BCDice
  module GameSystem
    class FilledWith
      # ナンバーワンノーマルくじ表（GURPS-FW版）
      #
      # 別の表に飛ぶ場合は、遅延評価のためにlambdaでジャンプ先の表を括る。
      LOT_NORMAL_TABLES = {
        1 => DiceTable::RangeTable.new(
          "ナンバーワンノーマルくじ（phase 1）",
          "1D6",
          [
            [1..3, "イレブンチキン"],
            [4..5, -> { LOT_NORMAL_TABLES[2] }],
            [   6, -> { LOT_NORMAL_TABLES[3] }],
          ]
        ),

        2 => DiceTable::RangeTable.new(
          "ナンバーワンノーマルくじ（phase 2）",
          "1D6",
          [
            [   1, "バロールたわし"],
            [   2, "イグニスジッポ"],
            [   3, "ヤコ仮面or梟の文鎮(選択可)"],
            [   4, "ナレッジのハンモックorジンジャビースト"],
            [5..6, -> { LOT_NORMAL_TABLES[3] }],
          ]
        ),

        3 => DiceTable::RangeTable.new(
          "ナンバーワンノーマルくじ（phase 3）",
          "1D6",
          [
            [1, "特性HPポーション"],
            [2, "特性MPポーション"],
            [3, "黒い甲冑"],
            [4, "天体望遠鏡"],
            [5, "金獅子の剥製"],
            [6, -> { LOT_NORMAL_TABLES[4] }],
          ]
        ),

        4 => DiceTable::RangeTable.new(
          "ナンバーワンノーマルくじ（phase 4）",
          "1D6",
          [
            [1, "特性スタミナポーション"],
            [2, "戦乙女の兜"],
            [3, "フェンリルの首輪"],
            [4, "フェニックスカーペット"],
            [5, "動くアダマンゴーレム"],
            [6, -> { LOT_NORMAL_TABLES[5] }],
          ]
        ),

        5 => DiceTable::RangeTable.new(
          "ナンバーワンノーマルくじ（phase 5）",
          "1D6",
          [
            [1, "キャンディークッション"],
            [2, "屑鉄の金床"],
            [3, "薪割り王の斧"],
            [4, "ロジエの水差し"],
            [5, "箱舟の模型"],
            [6, -> { LOT_PREMIUM_TABLES[5] }],
          ]
        ),
      }

      # ナンバーワンプレミアムくじ表（GURPS-FW版）
      #
      # 別の表に飛ぶ場合は、遅延評価のためにlambdaでジャンプ先の表を括る。
      LOT_PREMIUM_TABLES = {
        1 => DiceTable::RangeTable.new(
          "ナンバーワンプレミアムくじ（phase 1）",
          "1D6",
          [
            [1..3, "プレミアムチキン"],
            [   4, -> { LOT_NORMAL_TABLES[3] }],
            [5..6, -> { LOT_PREMIUM_TABLES[2] }],
          ]
        ),

        2 => DiceTable::RangeTable.new(
          "ナンバーワンプレミアムくじ（phase 2）",
          "1D6",
          [
            [1, "親衛隊バッジ"],
            [2, "ハタモトチャブダイ"],
            [3, "星のコンパス"],
            [4, "白銀の甲冑"],
            [5, -> { LOT_NORMAL_TABLES[4] }],
            [6, -> { LOT_PREMIUM_TABLES[3] }],
          ]
        ),

        3 => DiceTable::RangeTable.new(
          "ナンバーワンプレミアムくじ（phase 3）",
          "1D6",
          [
            [1, "特性クイックHPポーション"],
            [2, "特性クイックMPポーション"],
            [3, "特製クイックスタミナポーション"],
            [4, "火龍のフィギュアor氷龍のフィギュア(選択可)"],
            [5, "ヒメショーグンドレス"],
            [6, -> { LOT_PREMIUM_TABLES[4] }],
          ]
        ),

        4 => DiceTable::RangeTable.new(
          "ナンバーワンプレミアムくじ（phase 4）",
          "1D6",
          [
            [1, "クイックユグドラポーション"],
            [2, "銀河龍のフィギュア/ドラゴン"],
            [3, "銀河龍のフィギュア/魔族"],
            [4, "魔族チェスセット"],
            [5, "イグニスコンロ"],
            [6, -> { LOT_PREMIUM_TABLES[5] }],
          ]
        ),

        5 => DiceTable::RangeTable.new(
          "ナンバーワンプレミアムくじ（phase 5）",
          "1D6",
          [
            [1, "グレヴディバリウス"],
            [2, "天使の望遠鏡orデスの目覚まし時計(選択可)"],
            [3, "世界樹の蔦"],
            [4, "死神の飾りドレス"],
            [5, "ザバーニヤ等身大フィギュア"],
            [6, -> { LOT_PREMIUM_TABLES[6] }],
          ]
        ),

        6 => DiceTable::RangeTable.new(
          "ナンバーワンプレミアムくじ（phase 6）",
          "1D6",
          [
            [1, "イレブンチキン"],
            [2, "イレブンチキン(2ピース)"],
            [3, "イレブンチキン(3ピース)"],
            [4, "イレブンチキン(6ピース)"],
            [5, "イレブンチキン(12ピース)"],
            [6, "wish star"],
          ]
        ),
      }
    end
  end
end
