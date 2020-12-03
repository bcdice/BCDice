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
            round_type = game_system.round_type
            cmp_op = @cmp_op || game_system.default_cmp_op
            reroll_cmp_op = @reroll_cmp_op || cmp_op || :>=

            target_number =
              @target_number_node&.eval(round_type) ||
              game_system.default_target_number

            reroll_threshold =
              @reroll_threshold_node&.eval(round_type) ||
              game_system.reroll_dice_reroll_threshold ||
              target_number

            reroll_condition = RerollCondition.new(reroll_cmp_op, reroll_threshold)

            dice_queue = @notations.map { |node| node.to_dice(round_type) }
            unless dice_queue.all? { |d| reroll_condition.valid?(d.sides) }
              return result_with_text("#{@source} ＞ 条件が間違っています。2R6>=5 あるいは 2R6[5] のように振り足し目標値を指定してください。")
            end

            dice_list_list = roll(
              dice_queue,
              randomizer,
              reroll_condition,
              game_system.sort_barabara_dice?
            )

            dice_list = dice_list_list.flatten

            # 振り足し分は出目1の個数をカウントしない
            one_count = dice_list_list
                        .take(@notations.size)
                        .flatten
                        .count(1)

            success_count =
              if cmp_op
                dice_list.count { |val| val.send(cmp_op, target_number) }
              else
                0
              end

            sequence = [
              expr(round_type, reroll_condition, cmp_op, target_number),
              dice_list_list.map { |list| list.join(",") }.join(" + "),
              "成功数#{success_count}",
              game_system.grich_text(one_count, dice_list.size, success_count),
            ].compact

            result_with_text(sequence.join(" ＞ "))
          end

          private

          # ダイスロールを行う
          # @param dice_queue [Array<Dice>] ダイスキュー
          # @param randomizer [Randomizer] 乱数生成器
          # @param reroll_condition [RerollCondition] 振り足し条件
          # @param sort [Boolean] 出目を並び替えるか
          # @return [Array<Array<Integer>>]
          def roll(dice_queue, randomizer, reroll_condition, sort)
            dice_list_list = []
            loop_count = 0

            while !dice_queue.empty? && loop_count < REROLL_LIMIT
              dice = dice_queue.shift
              loop_count += 1

              dice_list = dice.roll(randomizer)
              dice_list.sort! if sort
              dice_list_list.push(dice_list)

              reroll_count = dice_list.count { |val| val.send(reroll_condition.cmp_op, reroll_condition.threshold) }
              if reroll_count > 0
                dice_queue.push(Dice.new(reroll_count, dice.sides))
              end
            end

            return dice_list_list
          end

          def expr(round_type, reroll_condition, cmp_op, target_number)
            notation = @notations.map { |n| n.to_dice(round_type) }.join("+")

            reroll_cmp_op_text =
              if reroll_condition.cmp_op == cmp_op
                ""
              else
                Format.comparison_operator(reroll_condition.cmp_op)
              end

            cmp_op_text = Format.comparison_operator(cmp_op)

            "(#{notation}[#{reroll_cmp_op_text}#{reroll_condition.threshold}]#{cmp_op_text}#{target_number})"
          end

          def result_with_text(text)
            Result.new.tap do |r|
              r.secret = @secret
              r.text = text
            end
          end
        end

        # 振り足し条件を表すクラス。
        class RerollCondition
          # @return [Symbol] 比較演算子
          attr_reader :cmp_op
          # @return [Integer] 振り足しの閾値
          attr_reader :threshold

          # @param cmp_op [Symbol] 比較演算子
          # @param threshold [Integer] 振り足しの閾値
          def initialize(cmp_op, threshold)
            @cmp_op = cmp_op
            @threshold = threshold
          end

          # @param sides [Integer] ダイスの面数
          # @return [Boolean] 振り足し条件が妥当か
          def valid?(sides)
            return false unless @threshold

            case @cmp_op
            when :<=
              @threshold < sides
            when :<
              @threshold <= sides
            when :>=
              @threshold > 1
            when :>
              @threshold >= 1
            when :'!='
              (1..sides).include?(@threshold)
            else # :==
              true
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
