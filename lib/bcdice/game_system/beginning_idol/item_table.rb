# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class ItemTable
        def initialize(locale)
          @locale = locale
        end

        def roll_command(randomizer, command)
          m = /^IT(\d+)?$/.match(command)
          unless m
            return nil
          end

          roll_counts = m[1]&.to_i || 1
          return roll(randomizer, roll_counts)
        end

        # @param randomizer [BCDice::Randomizer]
        # @param counts [Integer]
        def roll(randomizer, roll_counts = 1)
          if roll_counts == 0
            return nil
          end

          table = I18n.t("BeginningIdol.item_table", locale: @locale)

          dice_list = randomizer.roll_barabara(roll_counts, 6).sort
          grouped = dice_list.group_by(&:itself)

          item_list = grouped.map do |dice, list|
            item = table[:items][dice - 1]
            if grouped.size != 1
              item = format(table[:emph], item: item)
            end

            if dice_list.size == grouped.size
              item
            else
              format(table[:counting], item: item, count: list.size)
            end
          end

          return "#{table[:name]} ＞ [#{dice_list.join(',')}] ＞ #{item_list.join(table[:sep])}"
        end
      end
    end
  end
end
