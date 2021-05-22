# frozen_string_literal: true

require "bcdice/format"
require "bcdice/common_command/barabara_dice/result"

module BCDice
  module CommonCommand
    module BarabaraDice
      module Node
        class Command
          def initialize(secret:, notations:, cmp_op:, target_number:)
            @secret = secret
            @notations = notations
            @cmp_op = cmp_op
            @target_number = target_number
          end

          # @param game_system [Base] ゲームシステム
          # @param randomizer [Randomizer] ランダマイザ
          # @return [Result]
          def eval(game_system, randomizer)
            round_type = game_system.round_type
            notations = @notations.map { |n| n.to_dice(round_type) }
            cmp_op = @cmp_op || game_system.default_cmp_op
            target_number = @target_number&.eval(round_type) || game_system.default_target_number

            dice_list_list = notations.map { |d| d.roll(randomizer) }
            dice_list_list.map!(&:sort) if game_system.sort_barabara_dice?

            dice_list = dice_list_list.flatten

            count_of_1 = dice_list.count(1)
            success_num = cmp_op ? dice_list.count { |d| d.send(cmp_op, target_number) } : 0
            success_num_text = "成功数#{success_num}" if cmp_op

            sequence = [
              "(#{notations.join('+')}#{Format.comparison_operator(cmp_op)}#{target_number})",
              dice_list.join(","),
              success_num_text,
              game_system.grich_text(count_of_1, dice_list.size, success_num)
            ].compact

            Result.new.tap do |r|
              r.secret = @secret
              r.text = sequence.join(" ＞ ")
              r.last_dice_list_list = dice_list_list
              r.last_dice_list = dice_list
              r.success_num = success_num
            end
          end
        end

        class Notation
          # @param times [#eval]
          # @param sides [#eval]
          def initialize(times, sides)
            @times = times
            @sides = sides
          end

          # @param round_type [Symbol]
          def to_dice(round_type)
            times = @times.eval(round_type)
            sides = @sides.eval(round_type)

            Dice.new(times, sides)
          end
        end

        class Dice
          # @param times [Integer]
          # @param sides [Integer]
          def initialize(times, sides)
            @times = times
            @sides = sides
          end

          # @param randomizer [BCDice::Randomizer]
          # @return [Array<Integer>]
          def roll(randomizer)
            randomizer.roll_barabara(@times, @sides)
          end

          # @return [String]
          def to_s
            "#{@times}B#{@sides}"
          end
        end
      end
    end
  end
end
