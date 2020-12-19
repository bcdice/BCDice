require "bcdice/common_command/barabara_dice/parser"

module BCDice
  module CommonCommand
    module BarabaraDice
      PREFIX_PATTERN = /\d+B\d+/.freeze

      class << self
        def eval(command, game_system, randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system, randomizer)
        end
      end
    end
  end
end
