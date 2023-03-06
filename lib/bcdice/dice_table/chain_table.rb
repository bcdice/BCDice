# frozen_string_literal: true

module BCDice
  module DiceTable
    class ChainTable
      # @param [String] name 表の名前
      # @param [String] type 項目を選ぶときのダイスロールの方法 '1D6'など
      # @param [Array<String, #roll>] items 表の項目の配列
      def initialize(name, type, items)
        @name = name
        @items = items.freeze

        m = /(\d+)D(\d+)/i.match(type)
        unless m
          raise ArgumentError, "Unexpected table type: #{type}"
        end

        @times = m[1].to_i
        @sides = m[2].to_i
      end

      # 表を振る
      # @param randomizer [#roll_sum] ランダマイザ
      # @return [String] 結果
      def roll(randomizer)
        value = randomizer.roll_sum(@times, @sides)
        index = value - @times
        chosen = @items[index]

        RollResult.new_with_chain(@name, value, chosen, randomizer)
      end
    end
  end
end
