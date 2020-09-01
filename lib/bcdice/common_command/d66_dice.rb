module BCDice
  module CommonCommand
    class D66Dice
      def initialize(command, randomizer, game_system)
        @command = command
        @randomizer = randomizer
        @game_system = game_system

        @is_secret = false
      end

      def secret?
        @is_secret
      end

      def eval
        if @game_system.disable_d66?
          return nil
        end

        m = /^(S)?D66([ANS])?$/i.match(@command)
        unless m
          return nil
        end

        @is_secret = !m[1].nil?
        @sort_type = sort_type_from_suffix(m[2])

        value = roll()

        return ": (D66#{m[2]}) ＞ #{value}"
      end

      private

      def roll()
        dice_list = Array.new(2) { @randomizer.roll(1, 6)[0] }

        case @sort_type
        when :asc
          dice_list.sort!
        when :desc
          dice_list.sort!.reverse!
        end

        return dice_list[0] * 10 + dice_list[1]
      end

      def sort_type_from_suffix(suffix)
        case suffix
        when "A", "S"
          :asc
        when "N"
          :no_sort
        else
          @game_system.d66_sort_type
        end
      end
    end
  end
end
