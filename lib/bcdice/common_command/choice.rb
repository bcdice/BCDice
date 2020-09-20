module BCDice
  module CommonCommand
    class Choice
      PREFIX_PATTERN = /choice/.freeze

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
        m = /^(S)?choice\[([^,]+(?:,[^,]+)+)\]$/i.match(@command)
        unless m
          return nil
        end

        @is_secret = !m[1].nil?
        items = m[2].split(",").map(&:strip)

        index = @randomizer.roll_index(items.size)
        chosen = items[index]

        expr = "choice[#{items.join(',')}]"
        return "(#{expr}) ＞ #{chosen}"
      end
    end
  end
end
