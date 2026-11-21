# frozen_string_literal: true

require "bcdice/dice_table/d66_table"

module BCDice
  module DiceTable
    # 左側（十の位）のみ Range を用いる D66 表
    class D66LeftRangeTable < D66Table
      class << self
        def from_i18n(key, locale)
          table = I18n.t(key, locale: locale)
          converted_items = table[:items].map do |item|
            [conv_string_range(item[0]), item[1]]
          end
          new(table[:name], table[:d66_sort_type], converted_items)
        end

        def conv_string_range(x)
          if x.include?("..")
            return Range.new(*x.split("..", 2).map { |n| Integer(n) })
          end

          raise(
            ArgumentError,
            "invalid format"
          )
        end
      end

      # @param name [String] 表の名前
      # @param sort_type [Symbol] 出目入れ替えの方式 BCDice::D66SortType
      # @param items [Array<(Range, Array<String>)>] 表の項目の配列
      def initialize(name, sort_type, items)
        expanded_items = {}
        items.each do |item|
          range, right_items = item

          range.each do |left_value|
            right_items.each_with_index do |right_item, right_value|
              key = left_value * 10 + (right_value + 1)
              expanded_items[key] = right_item
            end
          end
        end

        super(name, sort_type, expanded_items)
      end
    end
  end
end
