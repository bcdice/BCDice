module BCDice
  module CommonCommand
    module Version
      PREFIX_PATTERN = /BCDiceVersion/.freeze

      class << self
        def eval(command, _game_system, _randomizer)
          if command == "BCDICEVERSION"
            Result.new.tap do |r|
              r.text = "BCDice Ver#{BCDice::VERSION}"
            end
          end
        end
      end
    end
  end
end
