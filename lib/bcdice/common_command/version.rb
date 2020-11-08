module BCDice
  module CommonCommand
    class Version
      PREFIX_PATTERN = /BCDiceVersion/.freeze

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

      # @param command [String]
      # @param _randomizer [Randomizer]
      # @param _game_system [Base]
      def initialize(command, _randomizer, _game_system)
        @command = command
      end

      # @return [Boolean]
      def secret?
        false
      end

      # @return [String, nil]
      def eval
        if @command == "BCDICEVERSION"
          "BCDice Ver#{BCDice::VERSION}"
        end
      end
    end
  end
end
