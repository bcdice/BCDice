# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class CostumeTable
        def self.from_i18n(key, locale)
          table = I18n.t(key, locale: locale)
          new(table[:name], table[:items])
        end

        # @param name [String]
        # @param items [Hash{Integer => String}]
        def initialize(name, items)
          @name = name
          @items = items
        end

        # @param randomizer [Randomizer]
        # @return [String]
        def roll(randomizer)
          value = randomizer.roll_d66(D66SortType::ASC)
          "#{@name}(#{value}) ＞ #{@items[value]}"
        end

        # @return [DiceTable::D66Table]
        def brand_only()
          DiceTable::D66Table.new(
            @name,
            D66SortType::ASC,
            @items.transform_values { |e| e.split("\n").first }
          )
        end
      end
    end
  end
end
