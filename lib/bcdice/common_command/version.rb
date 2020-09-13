module BCDice
  module CommonCommand
    class Version
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
