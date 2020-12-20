module BCDice
  module CommonCommand
    module AddDice
      class Randomizer
        attr_reader :rand_results

        RandResult = Struct.new(:sides, :value)

        # @param rand_source [BCDice::Randomizer]
        # @param game_system [BCDice::Base]
        def initialize(rand_source, game_system)
          @rand_source = rand_source
          @game_system = game_system
          @rand_results = []
        end

        # ダイスを振る
        # @param times [Integer] ダイス数
        # @param sides [Integer] 面数
        # @return [Array<Integer>] 出目の配列
        def roll(times, sides)
          dice_list =
            if sides == 66
              Array.new(times) { @rand_source.roll_d66(@game_system.d66_sort_type) }
            elsif sides == 9 && @game_system.enabled_d9?
              Array.new(times) { @rand_source.roll_d9() }
            else
              @rand_source.roll_barabara(times, sides)
            end

          dice_list.sort! if @game_system.sort_add_dice?
          rand_results = dice_list.map { |value| RandResult.new(sides, value) }
          @rand_results.concat(rand_results)

          dice_list
        end
      end
    end
  end
end
