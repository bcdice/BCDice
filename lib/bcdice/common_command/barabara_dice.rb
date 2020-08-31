require "utils/format"

class BCDice
  module CommonCommand
    class BarabaraDice
      def initialize(command, randomizer, game_system)
        @command = command
        @randomizer = randomizer
        @game_system = game_system

        @is_secret = false
      end

      def secret?
        @is_secret
      end

      # @return [String, nil]
      def eval()
        m = /^(S)?(\d+B\d+(?:\+\d+B\d+)*)(?:([<>=]+)(\d+))?$/i.match(@command)
        unless m
          return nil
        end

        @is_secret = !m[1].nil?
        lhs = m[2]
        b_list = lhs.split("+")

        if m[3]
          cmp_op = Normalize.comparison_operator(m[3])
          target_number = m[4].to_i
        elsif (n = /^([<>=]+)(\d+)$/.match(@game_system.defaultSuccessTarget))
          cmp_op = Normalize.comparison_operator(n[1])
          target_number = n[2].to_i
        else
          cmp_op = nil
          target_number = nil
        end

        dice_list = []
        b_list.each do |literal|
          times, sides = literal.split("B", 2).map(&:to_i)
          list = @randomizer.roll(times, sides)[1].split(",").map(&:to_i)
          list.sort! if @game_system.sortType & 2 != 0
          dice_list.concat(list)
        end

        count_of_1 = dice_list.count(1)
        success_num = cmp_op ? dice_list.count { |dice| dice.send(cmp_op, target_number) } : 0
        success_num_text = "成功数#{success_num}" if cmp_op

        sequence = [
          ": (#{lhs}#{Format.comparison_operator(cmp_op)}#{target_number})",
          dice_list.join(","),
          success_num_text,
          @game_system.grich_text(count_of_1, dice_list.size, success_num)
        ].compact

        return sequence.join(" ＞ ")
      end
    end
  end
end
