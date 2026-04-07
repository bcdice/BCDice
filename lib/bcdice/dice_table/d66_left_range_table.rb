# frozen_string_literal: true

require "bcdice/dice_table/d66_table"

module BCDice
  module DiceTable
    # 左側（十の位）のみ Range を用いる D66 表
    class D66LeftRangeTable < D66Table
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
