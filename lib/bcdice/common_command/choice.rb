module BCDice
  module CommonCommand
    class Choice
      PREFIX_PATTERN = /choice/.freeze

      class << self
        def eval(command, game_system, randomizer)
          command = new(command, randomizer, game_system)
          res = command.eval()
          return nil unless res

          Result.new.tap do |r|
            r.secret = command.secret?
            r.text = res
          end
        end
      end

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
