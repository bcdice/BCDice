# frozen_string_literal: true

require "bcdice/common_command/add_dice"
require "bcdice/common_command/barabara_dice"
require "bcdice/common_command/barabara_count_dice"
require "bcdice/common_command/calc"
require "bcdice/common_command/choice"
require "bcdice/common_command/d66_dice"
require "bcdice/common_command/repeat"
require "bcdice/common_command/reroll_dice"
require "bcdice/common_command/upper_dice"
require "bcdice/common_command/version"

module BCDice
  module CommonCommand
    COMMANDS = [
      AddDice,
      BarabaraDice,
      BarabaraCountDice,
      Calc,
      Choice,
      D66Dice,
      Repeat,
      RerollDice,
      UpperDice,
      Version,
    ].freeze
  end
end
