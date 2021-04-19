# frozen_string_literal: true

require "bcdice/dice_table/d66_grid_table"

module BCDice
  module DiceTable
    # D66を振って6x6マスの表を参照する
    class D66HalfGridTable < D66GridTable
      # @param key [String]
      # @param locale [Symbol]
      # @return [D66HalfGridTable]
      def self.from_i18n(key, locale)
        table = I18n.t(key, locale: locale, raise: true)
        new(table[:name], table[:items_1_2_3], table[:items_4_5_6])
      end

      # @param [String] name 表の名前
      # @param [Array<String>] items_1_2_3
      # @param [Array<String>] items_4_5_6
      def initialize(name, items_1_2_3, items_4_5_6)
        @name = name
        @items = [
          items_1_2_3,
          items_1_2_3,
          items_1_2_3,
          items_4_5_6,
          items_4_5_6,
          items_4_5_6,
        ].freeze
      end
    end
  end
end
