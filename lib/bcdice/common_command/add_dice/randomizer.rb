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
        # @return [Array<Array<Integer>>] 出目のグループの配列
        def roll(times, sides)
          # 振り足し分も含めた出目グループの配列
          @dice_list = roll_once(times, sides)
          return [@dice_list]
        end

        # ダイスを振る（振り足しなしの1回分）
        # @param times [Integer] ダイス数
        # @param sides [Integer] 面数
        # @return [Array<Integer>] 出目の配列
        def roll_once(times, sides)
          @sides = sides if @sides < sides

          if sides == 66 && @game_system.enabled_d66?
            return Array.new(times) { @rand_source.roll_d66(@game_system.d66_sort_type) }
          end

          if sides == 9 && @game_system.enabled_d9?
            return Array.new(times) { @rand_source.roll_d9() }
          end

          dice_list = @rand_source.roll_barabara(times, sides)
          dice_list.sort! if @game_system.sort_add_dice?

          return dice_list
        end
      end
    end
  end
end
