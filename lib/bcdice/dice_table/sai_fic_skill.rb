module BCDice
  module DiceTable
    class SaiFicSkill
      def initialize(table, category_dice, row_dice)
        @table = table
        @category_dice = category_dice
        @row_dice = row_dice
      end

      # @return [String]
      attr_reader :table

      # @return [Integer]
      attr_reader :category_dice

      # @return [String]
      attr_reader :row_dice

      def to_s(format = nil)
        if format
          format(format, category_dice: category_dice, row_dice: row_dice, category_name: category_name, skill_name: skill_name, text: to_s)
        else
          "《#{skill_name}/#{category_name}#{row_dice}》"
        end
      end

      # @return [String]
      def category_name
        @table.items[category_dice - 1][0]
      end

      # @return [String]
      def skill_name
        @table.items[category_dice - 1][1][row_dice - 2]
      end

      def result_rtt
        to_s(@table.rtt_format)
      end

      def result_rttn
        to_s(@table.rttn_format)
      end
    end
  end
end
