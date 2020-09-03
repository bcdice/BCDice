require "bcdice/common_command/add_dice"
require "bcdice/common_command/barabara_dice"
require "bcdice/common_command/calc"
require "bcdice/common_command/choice"
require "bcdice/common_command/d66_dice"
require "bcdice/common_command/reroll_dice"
require "bcdice/common_command/upper_dice"

module BCDice
  module CommonCommand
    COMMANDS = [AddDice, BarabaraDice, Calc, Choice, D66Dice, RerollDice, UpperDice].freeze

    def self.eval(command, randomizer, game_system)
      COMMANDS.each do |klass|
        cmd = klass.new(command, randomizer, game_system)
        out = cmd.eval()

        return out, cmd.secret? if out
      end

      return nil, false
    end
  end
end
