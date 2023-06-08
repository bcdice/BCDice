# frozen_string_literal: true

module BCDice
  module GameSystem
    class Cthulhu7th < Base
      module Rollable
        private

        # 1D100の一の位用のダイスロール
        # 0から9までの値を返す
        #
        # @return [Integer]
        def roll_ones_d10
          dice = @randomizer.roll_once(10)
          return 0 if dice == 10

          return dice
        end

        # @param bonus [Integer] ボーナス・ペナルティダイスの数。負の数ならペナルティダイス。
        # @return [Array<(Integer, Array<Integer>)>]
        def roll_with_bonus(bonus)
          tens_list = Array.new(bonus.abs + 1) { @randomizer.roll_tens_d10 }
          ones = roll_ones_d10()

          dice_list = tens_list.map do |tens|
            dice = tens + ones
            dice == 0 ? 100 : dice
          end

          dice =
            if bonus >= 0
              dice_list.min
            else
              dice_list.max
            end

          return dice, dice_list
        end
      end
    end
  end
end
