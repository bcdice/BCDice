# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      module ItemTable
        ITEMS = [
          "スタミナドリンク",
          "トレーニングウェア",
          "ドリーミングシューズ",
          "キャラアイテム",
          "お菓子",
          "差し入れ",
        ].freeze

        module_function

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

          dice_list = randomizer.roll_barabara(roll_counts, 6).sort
          grouped = dice_list.group_by(&:itself)

          item_list = grouped.map do |dice, list|
            item = ITEMS[dice - 1]
            if grouped.size != 1
              item = "「#{item}」"
            end

            if dice_list.size == grouped.size
              item
            else
              "#{item}#{list.size}つ"
            end
          end

          return "アイテム ＞ [#{dice_list.join(',')}] ＞ #{item_list.join('と')}"
        end
      end
    end
  end
end
