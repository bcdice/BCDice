require "bcdice/normalize"
require "bcdice/common_command/add_dice/parser"
require "bcdice/common_command/add_dice/randomizer"

module BCDice
  module CommonCommand
    class AddDice
      def initialize(command, randomizer, game_system)
        @command = command
        @bcdice = randomizer
        @diceBot = game_system

        @dice_list = []
        @is_secret = false
      end

      def secret?
        @is_secret
      end

      def eval()
        parser = Parser.new(@command)

        command = parser.parse()
        if parser.error?
          return nil
        end

        randomizer = Randomizer.new(@bcdice, @diceBot, command.cmp_op)
        total = command.lhs.eval(randomizer)

        output =
          if randomizer.dice_list.size <= 1 && command.lhs.is_a?(Node::DiceRoll)
            ": (#{command}) ＞ #{total}"
          else
            ": (#{command}) ＞ #{command.lhs.output} ＞ #{total}"
          end

        dice_list = randomizer.dice_list

        if command.cmp_op
          dice_total = dice_list.inject(&:+)
          output += @diceBot.check_result(total, dice_total, dice_list, randomizer.sides, command.cmp_op, command.rhs)
        end

        output += @diceBot.add_dice_additional_text(randomizer.dice_list, randomizer.sides) || ""
        @is_secret = parser.secret?

        return output
      end
    end
  end
end
