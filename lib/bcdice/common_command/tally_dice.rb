# frozen_string_literal: true

require "bcdice/common_command/tally_dice/parser"

module BCDice
  module CommonCommand
    # 個数カウントダイスのモジュール
    module TallyDice
      PREFIX_PATTERN = /\d+T[YZ]\d+/.freeze

      class << self
        def eval(command, game_system, randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system, randomizer)
        end
      end
    end
  end
end
