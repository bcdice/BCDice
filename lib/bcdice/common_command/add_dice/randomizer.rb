module BCDice
  module CommonCommand
    class AddDice
      class Randomizer
        attr_reader :dicebot, :cmp_op, :dice_list, :sides

        def initialize(bcdice, dicebot, cmp_op)
          @bcdice = bcdice
          @dicebot = dicebot
          @cmp_op = cmp_op
          @sides = 0
          @dice_list = []
        end

        # ダイスを振る
        # @param [Integer] times ダイス数
        # @param [Integer] sides 面数
        # @return [Array<Array<Integer>>] 出目のグループの配列
        def roll(times, sides)
          # 振り足し分も含めた出目グループの配列
          @dice_list = roll_once(times, sides)
          return [@dice_list]
        end

        # ダイスを振る（振り足しなしの1回分）
        # @param [Integer] times ダイス数
        # @param [Integer] sides 面数
        # @return [Array<Integer>] 出目の配列
        def roll_once(times, sides)
          @sides = sides if @sides < sides

          if sides == 66 && @dicebot.enable_d66?
            return Array.new(times) { @bcdice.roll_d66(@dicebot.d66_sort_type) }
          end

          if sides == 9 && @dicebot.isD9
            return Array.new(times) { @bcdice.roll_d9() }
          end

          _, dice_str, = @bcdice.roll(times, sides, @dicebot.sort_add_dice?)

          # 現在は出目が文字列で返ってきてしまうので、整数の配列に変換する
          return dice_str.split(",").map(&:to_i)
        end
      end
    end
  end
end
