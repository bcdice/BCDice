require 'bcdice/common_command/barabara_dice'
require 'bcdice/common_command/choice'

class BCDice
  module CommonCommand
    COMMANDS = [BarabaraDice, Choice].freeze

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
