# frozen_string_literal: true

module BCDice
  module CommonCommand
    module RerollDice
      module Node
        class Command
          def initialize(secret:, notations:, source:, cmp_op: nil, target_number: nil, reroll_cmp_op: nil, reroll_threshold: nil)
            @secret = secret
            @notations = notations
            @cmp_op = cmp_op
            @target_number_node = target_number
            @reroll_cmp_op = reroll_cmp_op
            @reroll_threshold_node = reroll_threshold
            @source = source
          end

          def eval(game_system, randomizer)
            @game_system = game_system
            @target_number = @target_number_node&.eval(round_type)
            @reroll_threshold = @reroll_threshold_node&.eval(round_type)

            dice_queue = notations.map { |node| node.to_dice(round_type) }
            unless valid_command?(dice_queue)
              return result_with_text("#{source} ＞ 条件が間違っています。2R6>=5 あるいは 2R6[5] のように振り足し目標値を指定してください。")
            end

            dice_list_list = roll(dice_queue, randomizer)

            dice_list = dice_list_list.flatten
            one_count = dice_list_list.take(notations.size).flatten.count(1) # 振り足し分は出目1の個数をカウントしない
            success_count =
              if cmp_op
                dice_list.count { |val| val.send(cmp_op, target_number) }
              else
                0
              end

            sequence = [
              expr(),
              dice_list_list.map { |list| list.join(",") }.join(" + "),
              "成功数#{success_count}",
              game_system.grich_text(one_count, dice_list.size, success_count),
            ].compact

            result_with_text(sequence.join(" ＞ "))
          end

          private

          def roll(dice_queue, randomizer)
            dice_list_list = []
            loop_count = 0

            while !dice_queue.empty? && loop_count < REROLL_LIMIT
              dice = dice_queue.shift
              loop_count += 1

              dice_list = dice.roll(randomizer)
              dice_list.sort! if sort?
              dice_list_list.push(dice_list)

              reroll_count = dice_list.count { |val| val.send(reroll_cmp_op, reroll_threshold) }
              if reroll_count > 0
                dice_queue.push(Dice.new(reroll_count, dice.sides))
              end
            end

            return dice_list_list
          end

          def valid_command?(dice_queue)
            reroll_threshold && dice_queue.all? { |d| valid_reroll_rule?(d.sides, reroll_cmp_op, reroll_threshold) }
          end

          # @param sides [Integer]
          # @param cmp_op [Symbol]
          # @param reroll_threshold [Integer]
          # @return [Boolean]
          def valid_reroll_rule?(sides, cmp_op, reroll_threshold) # 振り足しロールの条件確認
            case cmp_op
            when :<=
              reroll_threshold < sides
            when :<
              reroll_threshold <= sides
            when :>=
              reroll_threshold > 1
            when :>
              reroll_threshold >= 1
            when :'!='
              (1..sides).include?(reroll_threshold)
            else # :==
              true
            end
          end

          attr_reader :notations, :source

          def cmp_op
            @cmp_op || @game_system.default_cmp_op
          end

          def target_number
            @target_number || @game_system.default_target_number
          end

          def reroll_cmp_op
            @reroll_cmp_op || cmp_op || :>=
          end

          def reroll_threshold
            @reroll_threshold || @game_system.reroll_dice_reroll_threshold || target_number
          end

          def sort?
            @game_system.sort_barabara_dice?
          end

          def round_type
            @game_system.round_type
          end

          def expr
            notation = notations.map { |n| n.to_dice(round_type) }.join("+")
            reroll_cmp_op_text = Format.comparison_operator(reroll_cmp_op) if cmp_op != reroll_cmp_op
            cmp_op_text = Format.comparison_operator(cmp_op)

            "(#{notation}[#{reroll_cmp_op_text}#{reroll_threshold}]#{cmp_op_text}#{target_number})"
          end

          def result_with_text(text)
            Result.new.tap do |r|
              r.secret = @secret
              r.text = text
            end
          end
        end

        class Notation
          def initialize(times, sides)
            @times = times
            @sides = sides
          end

          def to_dice(round_type)
            times = @times.eval(round_type)
            sides = @sides.eval(round_type)

            Dice.new(times, sides)
          end
        end

        class Dice
          attr_reader :times, :sides

          def initialize(times, sides)
            @times = times
            @sides = sides
          end

          def roll(randomizer)
            randomizer.roll_barabara(times, sides)
          end

          def to_s
            "#{times}R#{sides}"
          end
        end
      end
    end
  end
end
