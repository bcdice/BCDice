# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class D6TwiceTable
        # @param name [String]
        # @param items1 [Array<String>]
        # @param items2 [Array<String>]
        def initialize(name, items1, items2)
          @name = name
          @items1 = items1
          @items2 = items2
        end

        # @param [Randomizer]
        # @return [String]
        def roll(randomizer)
          value1, value2 = randomizer.roll_barabara(2, 6)
          chosen1 = @items1[value1]
          chosen2 = @items2[value2]

          "#{@name}[#{value1},#{value2}] ＞ #{chosen1}#{chosen2}"
        end
      end
    end
  end
end
