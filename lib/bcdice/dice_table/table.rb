module BCDice
  module DiceTable
    # 表を表すクラス
    class Table
      # @param key [String]
      # @param locale [Symbol]
      # @return [Table]
      def self.from_i18n(key, locale)
        table = I18n.t(key, locale: locale)
        new(table[:name], table[:type], table[:items])
      end

      # @param [String] name 表の名前
      # @param [String] type 項目を選ぶときのダイスロールの方法 '1D6'など
      # @param [Array<String>] items 表の項目の配列
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
      # @param [BCDice] bcdice ランダマイザ
      # @return [String] 結果
      def roll(bcdice)
        value = bcdice.roll_sum(@times, @sides)
        return choice(value)
      end

      def choice(value)
        index = value - @times
        return RollResult.new(@name, value, @items[index])
      end
    end
  end
end
