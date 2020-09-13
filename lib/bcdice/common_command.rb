require "bcdice/common_command/add_dice"
require "bcdice/common_command/barabara_dice"
require "bcdice/common_command/calc"
require "bcdice/common_command/choice"
require "bcdice/common_command/d66_dice"
require "bcdice/common_command/reroll_dice"
require "bcdice/common_command/upper_dice"
require "bcdice/common_command/version"

module BCDice
  module CommonCommand
    COMMANDS = [
      AddDice,
      BarabaraDice,
      Calc,
      Choice,
      D66Dice,
      RerollDice,
      UpperDice,
      Version,
    ].freeze
  end
end
