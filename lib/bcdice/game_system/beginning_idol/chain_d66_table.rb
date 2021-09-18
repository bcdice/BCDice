# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class ChainD66Table
        # @param [String] name 表の名前
        # @param [Array<Array<String, #roll>>] items 表の項目の配列
        def initialize(name, items)
          @name = name
          @items = items.freeze
        end

        # 表を振る
        # @param randomizer [#roll_sum] ランダマイザ
        # @return [String] 結果
        def roll(randomizer)
          dice = randomizer.roll_barabara(2, 6).sort

          value = dice[0] * 10 + dice[1]
          chosen = @items[value]
          body = chosen.map { |item| item.respond_to?(:roll) ? item.roll(randomizer) : item }.join("\n")

          return "#{@name}(#{value}) ＞ #{body}"
        end
      end
    end
  end
end
