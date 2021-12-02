# frozen_string_literal: true

module BCDice
  module DiceTable
    # 出目の偶奇による場合分け機能をもつD66表
    class D66ParityTable
      # @param key [String]
      # @param locale [Symbol]
      # @return [D66ParityTable]
      def self.from_i18n(key, locale)
        table = I18n.t(key, locale: locale, raise: true)
        new(table[:name], table[:odd], table[:even])
      end

      # @param name [String] 表の名前
      # @param odd [Array<String>] 左ダイスが奇数だったときの次層テーブル（サイズ６）
      # @param even [Array<String>] 左ダイスが偶数だったときの次層テーブル（サイズ６）
      def initialize(name, odd, even)
        @name = name
        @odd = odd.freeze
        @even = even.freeze
      end

      # 表を振る
      # @param randomizer [#roll_once] ランダマイザ
      # @return [String] 結果
      def roll(randomizer)
        dice1 = randomizer.roll_once(6)
        dice2 = randomizer.roll_once(6)

        if dice1.odd?
          second_table = @odd
        else
          second_table = @even
        end

        result = second_table[dice2 - 1]
        key = dice1 * 10 + dice2

        return RollResult.new(@name, key, result)
      end
    end
  end
end
