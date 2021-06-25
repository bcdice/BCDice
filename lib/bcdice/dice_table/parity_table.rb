# frozen_string_literal: true

module BCDice
  module DiceTable
    # 出目の偶奇による場合分け機能をもつ表
    class ParityTable
      # @param [String] name 表の名前
      # @param [String] type 項目を選ぶときのダイスロールの方法 '1D6'など
      # @param [String] odd ダイス目が奇数のときの結果
      # @param [String] even ダイス目が偶数のときの結果
      def initialize(name, type, odd, even)
        @name = name
        @odd = odd.freeze
        @even = even.freeze

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
        return RollResult.new(@name, value, value.odd? ? @odd : @even)
      end
    end
  end
end
