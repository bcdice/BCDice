# frozen_string_literal: true

module BCDice
  module CommonCommand
    module UpperDice
      module Node
        class Command
          # @param secret [Boolean]
          # @param notations [Array<Notation>]
          # @param modifier [Integer]
          # @param cmp_op [Symbol, nil]
          # @param target_number [Integer, nil]
          # @param reroll_threshold [Integer]
          def initialize(secret:, notations:, modifier:, cmp_op:, target_number:, reroll_threshold: nil)
            @secret = secret
            @notations = notations
            @modifier = modifier
            @cmp_op = cmp_op
            @target_number = target_number
            @reroll_threshold = reroll_threshold
          end

          # 上方無限ロールを実行する
          #
          # @param randomizer [Randomizer]
          # @return [Result, nil]
          def eval(game_system, randomizer)
            round_type = game_system.round_type

            dice_list = @notations.map { |n| n.to_dice(round_type) }
            reroll_threshold = @reroll_threshold&.eval(round_type) || game_system.upper_dice_reroll_threshold || 0
            modifier = @modifier&.eval(round_type) || 0
            target_number = @target_number&.eval(round_type)

            expr = expr(dice_list, reroll_threshold, modifier, target_number)

            if reroll_threshold <= 1
              return result_with_text("(#{expr}) ＞ 無限ロールの条件がまちがっています")
            end

            roll_list = dice_list.map do |n|
              n.roll(randomizer, reroll_threshold, game_system.sort_barabara_dice?)
            end.reduce([], :concat)

            result =
              if @cmp_op
                result_success_count(roll_list, modifier, target_number)
              else
                result_max_sum(roll_list, modifier)
              end

            sequence = [
              "(#{expr})",
              interlim_expr(roll_list, modifier),
              result
            ]

            result_with_text(sequence.join(" ＞ "))
          end

          private

          def result_success_count(roll_list, modifier, target_number)
            success_count = roll_list.count do |e|
              x = e[:sum] + modifier
              x.send(@cmp_op, target_number)
            end

            "成功数#{success_count}"
          end

          def result_max_sum(roll_list, modifier)
            sum_list = roll_list.map { |e| e[:sum] }
            total = sum_list.sum() + modifier
            max = sum_list.map { |i| i + modifier }.max

            "#{max}/#{total}(最大/合計)"
          end

          # ダイスロールの結果を文字列に変換する
          # 振り足しがなければその数値、振り足しがあれば合計と各ダイスの出目を出力する
          #
          # @param roll_list [Array<Hash>]
          # @param modifier [Integer]
          # @return [String]
          def interlim_expr(roll_list, modifier)
            dice = roll_list.map do |e|
              if e[:list].size == 1
                e[:sum]
              else
                "#{e[:sum]}[#{e[:list].join(',')}]"
              end
            end.join(",")

            dice + Format.modifier(modifier)
          end

          # パース済みのコマンドを文字列で表示する
          #
          # @return [String]
          def expr(dice_list, reroll_threshold, modifier, target_number)
            formated_cmp_op = Format.comparison_operator(@cmp_op)
            formated_modifier = Format.modifier(modifier)

            "#{dice_list.join('+')}[#{reroll_threshold}]#{formated_modifier}#{formated_cmp_op}#{target_number}"
          end

          def result_with_text(text)
            Result.new.tap do |r|
              r.secret = @secret
              r.text = text
            end
          end
        end

        class Notation
          # @param roll_times [Object]
          # @param sides [Object]
          def initialize(roll_times, sides)
            @roll_times = roll_times
            @sides = sides
          end

          # @param round_type [Symbol]
          # @return [Dice]
          def to_dice(round_type)
            roll_times = @roll_times.eval(round_type)
            sides = @sides.eval(round_type)

            Dice.new(roll_times, sides)
          end
        end

        class Dice
          # @param roll_times [Integer]
          # @param sides [Integer]
          def initialize(roll_times, sides)
            @roll_times = roll_times
            @sides = sides
          end

          # @param randomizer [BCDice::Randomizer]
          # @param reroll_threshold [Integer]
          # @param sort [Boolean]
          # @return [Array<Hash>]
          def roll(randomizer, reroll_threshold, sort)
            ret = Array.new(@roll_times) do
              list = roll_ones(randomizer, reroll_threshold)
              {sum: list.sum(), list: list}
            end

            if sort
              ret = ret.sort_by { |e| e[:sum] }
            end

            return ret
          end

          # @return [String]
          def to_s
            "#{@roll_times}U#{@sides}"
          end

          private

          def roll_ones(randomizer, reroll_threshold)
            dice_list = []

            loop do
              value = randomizer.roll_once(@sides)
              dice_list.push(value)
              break if value < reroll_threshold
            end

            return dice_list
          end
        end
      end
    end
  end
end
