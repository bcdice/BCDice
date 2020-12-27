module BCDice
  module CommonCommand
    module Version
      PREFIX_PATTERN = /BCDiceVersion/.freeze

      class << self
        def eval(command, _game_system, _randomizer)
          command = command.split(" ", 2).first
          if command.match?(/^BCDiceVersion$/i)
            Result.new.tap do |r|
              r.text = "BCDice #{BCDice::VERSION}"
            end
          end
        end
      end
    end
  end
end
