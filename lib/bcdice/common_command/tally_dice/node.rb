# frozen_string_literal: true

require "bcdice/result"

module BCDice
  module CommonCommand
    module TallyDice
      # 個数カウントダイスを表すノードをまとめるモジュール
      module Node
        # 個数カウントダイス：コマンドのノード
        class Command
          # 最大面数
          MAX_SIDES = 20

          # @param secret [Boolean] シークレットダイスか
          # @param notation [Notation] ダイス表記
          def initialize(secret:, notation:)
            @secret = secret
            @notation = notation
          end

          # @param game_system [Base] ゲームシステム
          # @param randomizer [Randomizer] ランダマイザ
          # @return [Result, nil]
          def eval(game_system, randomizer)
            dice = @notation.to_dice(game_system.round_type)
            unless dice.valid?
              return nil
            end

            if dice.sides > MAX_SIDES
              return Result.new("(#{dice}) ＞ 面数は1以上、#{MAX_SIDES}以下としてください")
            end

            values = dice.roll(randomizer)

            values_str = (game_system.sort_barabara_dice? ? values.sort : values)
                         .join(",")

            # TODO: Ruby 2.7以降のみサポートするようになった場合
            # Enumerable#tally で書く
            values_count = values
                           .group_by(&:itself)
                           .transform_values(&:length)

            values_count_strs = (1..dice.sides).map do |v|
              count = values_count.fetch(v, 0)

              next nil if count == 0 && !dice.show_zeros?

              "[#{v}]×#{values_count.fetch(v, 0)}"
            end

            sequence = [
              "(#{dice})",
              values_str,
              values_count_strs.compact.join(", "),
            ].compact

            Result.new.tap do |r|
              r.secret = @secret
              r.text = sequence.join(" ＞ ")
            end
          end
        end

        # 個数カウントダイス：ダイス表記のノード
        class Notation
          # @return [Integer] 振る回数
          attr_reader :times
          # @return [Integer] 面数
          attr_reader :sides
          # @return [Boolean] 個数0を表示するか
          attr_reader :show_zeros

          # @param times [#eval] 振る回数
          # @param sides [#eval] 面数
          # @param show_zeros [Boolean] 個数0を表示するか
          def initialize(times:, sides:, show_zeros:)
            @times = times
            @sides = sides
            @show_zeros = show_zeros
          end

          # @param round_type [Symbol] 除算の端数処理方法
          # @return [Dice]
          def to_dice(round_type)
            times = @times.eval(round_type)
            sides = @sides.eval(round_type)

            Dice.new(times: times, sides: sides, show_zeros: @show_zeros)
          end
        end

        # 個数カウントダイス：ダイスのノード
        class Dice
          # @return [Integer] 振る回数
          attr_reader :times
          # @return [Integer] 面数
          attr_reader :sides
          # @return [Boolean] 個数0を表示するか
          attr_reader :show_zeros

          alias show_zeros? show_zeros

          # @param times [Integer] 振る回数
          # @param sides [Integer] 面数
          def initialize(times:, sides:, show_zeros:)
            @times = times
            @sides = sides
            @show_zeros = show_zeros
          end

          # @return [Boolean] ダイスとして有効（振る回数、面数ともに正の数）か
          def valid?
            @times > 0 && @sides > 0
          end

          # ダイスを振る
          # @param randomizer [BCDice::Randomizer] ランダマイザ
          # @return [Array<Integer>] 出目の配列
          def roll(randomizer)
            randomizer.roll_barabara(@times, @sides)
          end

          # @return [String]
          def to_s
            show_zeros_symbol = @show_zeros ? "Z" : "Y"
            "#{@times}T#{show_zeros_symbol}#{@sides}"
          end
        end
      end
    end
  end
end
