module BCDice
  module DiceTable
    # 項目をRangeを用いて参照するD66表
    class D66RangeTable
      # @param name [String] 表の名前
      # @param items [Array<(Range, String)>] 表の項目の配列
      def initialize(name, items)
        @name = name
        @items = items.freeze
      end

      # 表を振る
      # @param randomizer [#roll_once] ランダマイザ
      # @return [String] 結果
      def roll(randomizer)
        dice1 = randomizer.roll_once(6)
        dice2 = randomizer.roll_once(6)

        key = dice1 * 10 + dice2

        chosen = @items.find { |row| row[0].include?(key) }
        return "#{@name}(#{key}) ＞ #{chosen[1]}"
      end
    end
  end
end
