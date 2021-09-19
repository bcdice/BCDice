# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class BadStatusTable
        def initialize(locale)
          @locale = locale
        end

        def roll_command(randomizer, command)
          m = /^BT(\d+)?$/.match(command)
          unless m
            return nil
          end

          roll_counts = m[1]&.to_i || 1
          return roll(randomizer, roll_counts)
        end

        # @param randomizer [BCDice::Randomizer]
        # @param counts [Integer]
        def roll(randomizer, roll_counts = 1)
          if roll_counts <= 0
            return nil
          end

          name = I18n.t("BeginningIdol.BT.name", locale: @locale)
          items = I18n.t("BeginningIdol.BT.items", locale: @locale)
          prefix_format = I18n.t("BeginningIdol.BT.prefix_format", locale: @locale)

          dice_list = randomizer.roll_barabara(roll_counts, 6).sort
          index_list = dice_list.uniq

          result_prefix = format(prefix_format, count_bad_status: index_list.size) + "\n" if index_list.size > 1
          result_text = index_list.map { |i| items[i - 1] }.join("\n")

          return "#{name} ＞ [#{dice_list.join(',')}] ＞ #{result_prefix}#{result_text}"
        end
      end
    end
  end
end
