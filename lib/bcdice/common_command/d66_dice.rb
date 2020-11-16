module BCDice
  module CommonCommand
    class D66Dice
      PREFIX_PATTERN = /D66/.freeze

      class << self
        # @param command [String]
        # @param game_system [BCDice::Base]
        # @param randomizer [Randomizer]
        # @return [Result, nil]
        def eval(command, game_system, randomizer)
          cmd = parse(command, game_system)
          cmd&.eval(randomizer)
        end

        private

        def parse(command, game_system)
          return nil unless game_system.enabled_d66?

          m = /^(S)?D66([ANS])?$/i.match(command)
          return nil unless m

          new(
            secret: !m[1].nil?,
            sort_type: sort_type_from_suffix(m[2]) || game_system.d66_sort_type,
            suffix: m[2]
          )
        end

        def sort_type_from_suffix(suffix)
          case suffix
          when "A", "S"
            D66SortType::ASC
          when "N"
            D66SortType::NO_SORT
          end
        end
      end

      # @param secret [Boolean]
      # @param sort_type [Symbol]
      # @param suffix [String, nil]
      def initialize(secret:, sort_type:, suffix:)
        @secret = secret
        @sort_type = sort_type
        @suffix = suffix
      end

      # @param randomizer [Randomizer]
      # @return [Result]
      def eval(randomizer)
        value = roll(randomizer)

        Result.new.tap do |r|
          r.secret = @secret
          r.text = "(D66#{@suffix}) ＞ #{value}"
        end
      end

      private

      def roll(randomizer)
        dice_list = Array.new(2) { randomizer.roll_once(6) }

        case @sort_type
        when D66SortType::ASC
          dice_list.sort!
        when D66SortType::DESC
          dice_list.sort!.reverse!
        end

        return dice_list[0] * 10 + dice_list[1]
      end
    end
  end
end
