# frozen_string_literal: true

require "bcdice/result"

module BCDice
  module CommonCommand
    module BarabaraCountDice
      # 個数カウントダイスを表すノードをまとめるモジュール
      module Node
        # 個数カウントダイス：コマンドのノード
        class Command
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

            values = dice.roll(randomizer)

            values_str = (game_system.sort_barabara_dice? ? values.sort : values)
                         .join(",")

            # TODO: Ruby 2.7以降のみサポートするようになった場合
            # Enumerable#tally で書く
            values_count = values
                           .group_by(&:itself)
                           .to_h { |value, group| [value, group.length] }

            values_count_str = (1..dice.sides)
                               .map { |v| "[#{v}]×#{values_count.fetch(v, 0)}個" }
                               .join(", ")

            sequence = [
              "(#{dice})",
              values_str,
              values_count_str,
            ].compact

            Result.new.tap do |r|
              r.secret = @secret
              r.text = sequence.join(" ＞ ")
            end
          end
        end

        # 個数カウントダイス：ダイス表記のノード
        class Notation
          # @param times [#eval] 振る回数
          # @param sides [#eval] 面数
          def initialize(times, sides)
            @times = times
            @sides = sides
          end

          # @param round_type [Symbol] 除算の端数処理方法
          # @return [Dice]
          def to_dice(round_type)
            times = @times.eval(round_type)
            sides = @sides.eval(round_type)

            Dice.new(times, sides)
          end
        end

        # 個数カウントダイス：ダイスのノード
        class Dice
          # @return [Integer] 振る回数
          attr_reader :times
          # @return [Integer] 面数
          attr_reader :sides

          # @param times [Integer] 振る回数
          # @param sides [Integer] 面数
          def initialize(times, sides)
            @times = times
            @sides = sides
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
            "#{@times}BC#{@sides}"
          end
        end
      end
    end
  end
end
