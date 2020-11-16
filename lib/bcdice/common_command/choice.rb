module BCDice
  module CommonCommand
    class Choice
      PREFIX_PATTERN = /choice/.freeze

      class << self
        # @param command [String]
        # @param _game_system [BCDice::Base]
        # @param randomizer [Randomizer]
        # @return [Result, nil]
        def eval(command, _game_system, randomizer)
          cmd = parse(command)
          cmd&.roll(randomizer)
        end

        private

        def parse(command)
          m = /^(S)?choice\[([^,]+(?:,[^,]+)+)\]$/i.match(command)
          return nil unless m

          new(
            secret: !m[1].nil?,
            items: m[2].split(",").map(&:strip)
          )
        end
      end

      # @param secret [Boolean]
      # @param items [Array<String>]
      def initialize(secret:, items:)
        @secret = secret
        @items = items
      end

      # @param randomizer [Randomizer]
      # @return [Result]
      def roll(randomizer)
        index = randomizer.roll_index(@items.size)
        chosen = @items[index]

        Result.new.tap do |r|
          r.secret = @secret
          r.text = "(choice[#{@items.join(',')}]) ＞ #{chosen}"
        end
      end
    end
  end
end
