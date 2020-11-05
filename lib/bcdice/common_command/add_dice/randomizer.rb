module BCDice
  module CommonCommand
    module AddDice
      class Randomizer
        attr_reader :dice_list, :sides

        # @param rand_source [BCDice::Randomizer]
        # @param game_system [BCDice::Base]
        def initialize(rand_source, game_system)
          @rand_source = rand_source
          @game_system = game_system
          @sides = 0
          @dice_list = []
        end

        # ダイスを振る
        # @param times [Integer] ダイス数
        # @param sides [Integer] 面数
        # @return [Array<Integer>] 出目の配列
        def roll(times, sides)
          @sides = sides if @sides < sides

          dice_list =
            if sides == 66 && @game_system.enabled_d66?
              Array.new(times) { @rand_source.roll_d66(@game_system.d66_sort_type) }
            elsif sides == 9 && @game_system.enabled_d9?
              Array.new(times) { @rand_source.roll_d9() }
            else
              @rand_source.roll_barabara(times, sides)
            end

          dice_list.sort! if @game_system.sort_add_dice?
          @dice_list.concat(dice_list)

          dice_list
        end
      end
    end
  end
end
