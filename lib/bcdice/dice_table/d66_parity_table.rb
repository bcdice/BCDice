module BCDice
  module DiceTable
    # 出目の偶奇による場合分け機能をもつD66表
    class D66ParityTable
      # @param name [String] 表の名前
      # @param items [Hash<(Symbol, Array<string>)>]
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

        if dice1.odd?
          second_table = @items[:odd]
        else
          second_table = @items[:even]
        end

        result = second_table[dice2 - 1]
        key = dice1 * 10 + dice2

        return RollResult.new(@name, key, result)
      end
    end
  end
end
