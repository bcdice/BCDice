# frozen_string_literal: true

require "bcdice/normalize"
require "bcdice/common_command/add_dice/parser"
require "bcdice/common_command/add_dice/randomizer"

module BCDice
  module CommonCommand
    module AddDice
      PREFIX_PATTERN = /[+\-(]*(\d+|D\d+)/.freeze

      class << self
        def eval(command, game_system, randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system, randomizer)
        end
      end
    end
  end
end
