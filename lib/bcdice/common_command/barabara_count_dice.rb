# frozen_string_literal: true

require "bcdice/common_command/barabara_count_dice/parser"

module BCDice
  module CommonCommand
    # 個数カウントダイスのモジュール
    module BarabaraCountDice
      PREFIX_PATTERN = /\d+BC\d+/.freeze

      class << self
        def eval(command, game_system, randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system, randomizer)
        end
      end
    end
  end
end
