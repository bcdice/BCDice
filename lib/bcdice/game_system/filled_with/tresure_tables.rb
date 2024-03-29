# frozen_string_literal: true

module BCDice
  module GameSystem
    class FilledWith < Base
      # 夢幻の迷宮財宝表
      def getTresureResult(command)
        m = /^TRS(\d+)([+-]\d)?$/.match(command)
        unless m
          return nil
        end

        rank = m[1].to_i + m[2].to_i
        rank = rank.clamp(0, 12)

        return TRESURE_TABLES[rank].roll(@randomizer)
      end

      TRESURE_TABLES = {
        0 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "HPポーション(消耗品)",
            "FPポーション(消耗品)",
            "マジックパウダー:火(消耗品)",
            "マジックパウダー:氷(消耗品)",
            "マジックパウダー:雷(消耗品)",
            "500GP",
          ]
        ),
        1 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "高級HPポーション(消耗品)",
            "高級FPポーション(消耗品)",
            "高級抵抗ポーション(消耗品)",
            "高級鉄壁ポーション(消耗品)",
            "マジックパウダー:火、氷、雷の3点セット(消耗品)",
            "1000GP",
          ]
        ),
        2 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "鈴のお守り(装飾品)",
            "盗賊の小手(装飾品)",
            "狩人の羽帽子(装飾品)",
            "狙撃手の指貫(装飾品)",
            "「スタミナバンド」「健康お守り」「レザーマント」3点セット",
            "2000GP",
          ]
        ),
        3 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "最高級HPポーション×2(消耗品)",
            "最高級FPポーション×2(消耗品)",
            "最高級抵抗ポーション×2(消耗品)",
            "任意の装飾品1つ(4000GPまでのもの)",
            "アタッチメント割引券(全員に1枚)",
            "3000GP",
          ]
        ),
        4 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の「ミスリル」武器1つ",
            "ミスリルシールド(盾)",
            "ミスリルスケイル(鎧)",
            "任意の装飾品1つ(5000GPまでのもの)",
            "アタッチメント割引券(全員に2枚)",
            "5000GP",
          ]
        ),
        5 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の武器1つ(10000GPまでのもの)",
            "任意の盾1つ(10000GPまでのもの)",
            "任意の鎧1つ(10000GPまでのもの)",
            "最高級HPポーション(人数分)",
            "任意の装飾品1つ(10000GPまでのもの)",
            "7500GP",
          ]
        ),
        6 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の武器1つ(15000GPまでのもの)",
            "任意の盾1つ(15000GPまでのもの)",
            "任意の鎧1つ(15000GPまでのもの)",
            "任意の装飾品1つ(15000GPまでのもの)",
            "最高級FPポーション(人数分)",
            "10000GP",
          ]
        ),
        7 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の武器1つ(30000GPまでのもの)",
            "任意の盾1つ(30000GPまでのもの)",
            "任意の鎧1つ(30000GPまでのもの)",
            "任意の装飾品1つ(30000GPまでのもの)",
            "蘇生ポーション(消耗品)",
            "20000GP",
          ]
        ),
        8 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の武器1つ(60000GPまでのもの)",
            "任意の盾1つ(60000GPまでのもの)",
            "任意の鎧1つ(60000GPまでのもの)",
            "任意の装飾品1つ(60000GPまでのもの)",
            "蘇生ポーション(装飾品)+アタッチメント割引券10枚(割引券は人数分)",
            "40000GP",
          ]
        ),
        9 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の武器1つ(100000GPまでのもの)",
            "任意の盾1つ(100000GPまでのもの)",
            "任意の鎧1つ(100000GPまでのもの)",
            "任意の装飾品1つ(100000GPまでのもの)",
            "蘇生ポーション(装飾品)+アタッチメント割引券20枚(割引券は人数分)",
            "60000GP",
          ]
        ),
        10 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "任意の武器1つ(150000GPまでのもの)",
            "任意の盾1つ(150000GPまでのもの)",
            "任意の鎧1つ(150000GPまでのもの)",
            "任意の装飾品1つ(200000GPまでのもの)",
            "蘇生ポーション(装飾品)+アタッチメント割引券30枚(割引券は人数分)",
            "黄金の守護者の証(装飾品)(【ハッキング】があれば黄金の電子暗号キー(装飾品)も追加)",
          ]
        ),
        11 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "体力の欠片（大事なもの）(全員に10個)",
            "敏捷の欠片（大事なもの）(全員に10個)",
            "感覚の欠片（大事なもの）(全員に10個)",
            "知力の欠片（大事なもの）(全員に10個)",
            "意志の欠片（大事なもの）(全員に10個)",
            "お好きな副能力の欠片（大事なもの）(1人ずつ好きなものを選択して全員に50個)",
          ]
        ),
        12 => DiceTable::Table.new(
          "財宝表",
          "1D6",
          [
            "体力の欠片（大事なもの）(全員に20個)",
            "敏捷の欠片（大事なもの）(全員に20個)",
            "感覚の欠片（大事なもの）(全員に20個)",
            "知力の欠片（大事なもの）(全員に20個)",
            "意志の欠片（大事なもの）(全員に20個)",
            "お好きな副能力の欠片（大事なもの）(1人ずつ好きなものを選択して全員に100個)",
          ]
        )
      }.freeze
    end
  end
end
