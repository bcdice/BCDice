# frozen_string_literal: true

module BCDice
  module DiceTable
    # D66を振って6x6マスの表を参照する
    class D66GridTable
      # @param key [String]
      # @param locale [Symbol]
      # @return [D66GridTable]
      def self.from_i18n(key, locale)
        table = I18n.t(key, locale: locale, raise: true)
        new(table[:name], table[:items])
      end

      # @param [String] name 表の名前
      # @param [Array<Array<String>>] items 表の項目の配列
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
        value = dice1 * 10 + dice2

        index1 = dice1 - 1
        index2 = dice2 - 1
        return RollResult.new(@name, value, @items[index1][index2])
      end
    end
  end
end
