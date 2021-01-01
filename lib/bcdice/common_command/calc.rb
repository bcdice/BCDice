# frozen_string_literal: true

require "bcdice/common_command/calc/parser"

module BCDice
  module CommonCommand
    module Calc
      PREFIX_PATTERN = /C/.freeze

      class << self
        def eval(command, game_system, _randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system.round_type)
        end
      end
    end
  end
end
