require "bcdice/format"

module BCDice
  module CommonCommand
    class BarabaraDice
      PREFIX_PATTERN = /\d+B\d+/.freeze

      class << self
        def eval(command, game_system, randomizer)
          cmd = parse(command, game_system)
          cmd&.eval(randomizer)
        end

        private

        def parse(command, game_system)
          m = /^(S)?(\d+B\d+(?:\+\d+B\d+)*)(?:([<>=]+)(\d+))?$/i.match(command)
          return nil unless m

          new(
            secret: !m[1].nil?,
            notations: m[2].split("+").map { |notation| notation.split("B", 2).map(&:to_i) },
            cmp_op: Normalize.comparison_operator(m[3]),
            target_number: m[4]&.to_i,
            game_system: game_system
          )
        end
      end

      class Notation
        def initialize(times, sides)
          @times = times
          @sides = sides
        end

        def roll(randomizer)
          randomizer.roll_barabara(@times, @sides)
        end

        def to_s
          "#{@times}B#{@sides}"
        end
      end

      def initialize(secret:, notations:, cmp_op:, target_number:, game_system:)
        @secret = secret
        @notations = notations.map { |times, sides| Notation.new(times, sides) }
        @cmp_op = cmp_op
        @target_number = target_number
        @game_system = game_system
      end

      # @return [String, nil]
      def eval(randomizer)
        dice_list_list = @notations.map { |n| n.roll(randomizer) }
        dice_list_list.map!(&:sort) if @game_system.sort_barabara_dice?

        dice_list = dice_list_list.flatten

        count_of_1 = dice_list.count(1)
        success_num = cmp_op ? dice_list.count { |dice| dice.send(cmp_op, target_number) } : 0
        success_num_text = "成功数#{success_num}" if cmp_op

        sequence = [
          "(#{@notations.join('+')}#{Format.comparison_operator(cmp_op)}#{target_number})",
          dice_list.join(","),
          success_num_text,
          @game_system.grich_text(count_of_1, dice_list.size, success_num)
        ].compact

        Result.new.tap do |r|
          r.secret = @secret
          r.text = sequence.join(" ＞ ")
        end
      end

      private

      def cmp_op
        @cmp_op || @game_system.default_cmp_op
      end

      def target_number
        @target_number || @game_system.default_target_number
      end
    end
  end
end
