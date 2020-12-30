# frozen_string_literal: true

require "singleton"

module BCDice
  module CommonCommand
    module AddDice
      # 加算ロールの構文解析木のノードを格納するモジュール
      module Node
        # 加算ロールコマンドのノード。
        #
        # 目標値が設定されていない場合は +lhs+ のみを使用する。
        # 目標値が設定されている場合は、+lhs+、+cmp_op+、+rhs+ を使用する。
        class Command
          # 左辺のノード
          # @return [Object]
          attr_reader :lhs
          # 比較演算子
          # @return [Symbol]
          attr_reader :cmp_op
          # 右辺のノード
          # @return [Integer, String]
          attr_reader :rhs

          # ノードを初期化する
          # @param [Object] lhs 左辺のノード
          # @param [Symbol] cmp_op 比較演算子
          # @param [Integer, String] rhs 右辺のノード
          def initialize(secret, lhs, cmp_op = nil, rhs = nil)
            @secret = secret
            @lhs = lhs
            @cmp_op = cmp_op
            @rhs = rhs
          end

          # 文字列に変換する
          # @param game_system [BCDice::Base]
          # @return [String]
          def expr(game_system)
            @lhs.expr(game_system) + cmp_op_text + @rhs&.eval(game_system, nil).to_s
          end

          # ノードのS式を返す
          # @return [String]
          def s_exp
            if @cmp_op
              "(Command (#{@cmp_op} #{@lhs.s_exp} #{@rhs.s_exp}))"
            else
              "(Command #{@lhs.s_exp})"
            end
          end

          def eval(game_system, randomizer)
            randomizer = Randomizer.new(randomizer, game_system)
            total = @lhs.eval(game_system, randomizer)

            interrim_expr =
              unless randomizer.rand_results.size <= 1 && @lhs.is_a?(Node::DiceRoll)
                @lhs.output
              end

            result =
              if @cmp_op
                rhs = @rhs.eval(game_system, nil)
                game_system.check_result(total, randomizer.rand_results, @cmp_op, rhs)
              end
            result ||= Result.new

            sequence = [
              "(#{expr(game_system)})",
              interrim_expr,
              total,
              result&.text
            ].compact

            result.tap do |r|
              r.secret = @secret
              r.text = sequence.join(" ＞ ")
            end
          end

          private

          # メッセージ中で比較演算子をどのように表示するかを返す
          # @return [String]
          def cmp_op_text
            case @cmp_op
            when :'!='
              "<>"
            when :==
              "="
            else
              @cmp_op.to_s
            end
          end
        end

        class UndecidedTarget
          include Singleton

          def eval(_game_system, _randomizer)
            "?"
          end

          def include_dice?
            false
          end

          def expr(_game_system)
            "?"
          end

          def output
            "?"
          end

          alias s_exp output
        end

        # 二項演算子のノード
        class BinaryOp
          # ノードを初期化する
          # @param [Object] lhs 左のオペランドのノード
          # @param [Symbol] op 演算子
          # @param [Object] rhs 右のオペランドのノード
          def initialize(lhs, op, rhs)
            @lhs = lhs
            @op = op
            @rhs = rhs
          end

          # ノードを評価する
          #
          # 左右のオペランドをそれぞれ再帰的に評価した後で、演算を行う。
          #
          # @param game_system [BCDice::Base]
          # @param randomizer [Randomizer] ランダマイザ
          # @return [Integer] 評価結果
          def eval(game_system, randomizer)
            lhs = @lhs.eval(game_system, randomizer)
            rhs = @rhs.eval(game_system, randomizer)

            return calc(lhs, rhs, game_system.round_type)
          end

          # @return [Boolean]
          def include_dice?
            @lhs.include_dice? || @rhs.include_dice?
          end

          # 文字列に変換する
          # @return [String]
          def expr(game_system)
            lhs = @lhs.expr(game_system)
            rhs = @rhs.expr(game_system)

            "#{lhs}#{@op}#{rhs}"
          end

          # メッセージへの出力を返す
          # @return [String]
          def output
            "#{@lhs.output}#{@op}#{@rhs.output}"
          end

          # ノードのS式を返す
          # @return [String]
          def s_exp
            "(#{op_for_s_exp} #{@lhs.s_exp} #{@rhs.s_exp})"
          end

          private

          # 演算を行う
          # @param lhs [Integer] lhs 左のオペランド
          # @param rhs [Integer] 右のオペランド
          # @param _round_type [Symbol] ゲームシステムの端数処理設定
          # @return [Integer] 演算の結果
          def calc(lhs, rhs, _round_type)
            lhs.send(@op, rhs)
          end

          # S式で使う演算子の表現を返す
          # @return [String]
          def op_for_s_exp
            @op
          end
        end

        # 除算ノードの基底クラス
        #
        # 定数 +ROUNDING_METHOD+ で端数処理方法を示す記号
        # ( +'U'+, +'R'+, +''+ ) を定義すること。
        # また、除算および端数処理を行う +divide_and_round+ メソッドを実装すること。
        class DivideBase < BinaryOp
          # ノードを初期化する
          # @param [Object] lhs 左のオペランドのノード
          # @param [Object] rhs 右のオペランドのノード
          def initialize(lhs, rhs)
            super(lhs, :/, rhs)
          end

          # 文字列に変換する
          #
          # 通常の結果の末尾に、端数処理方法を示す記号を付加する。
          #
          # @return [String]
          def expr(game_system)
            "#{super(game_system)}#{rounding_method}"
          end

          # メッセージへの出力を返す
          #
          # 通常の結果の末尾に、端数処理方法を示す記号を付加する。
          #
          # @return [String]
          def output
            "#{super}#{rounding_method}"
          end

          private

          # 端数処理方法を示す記号を返す
          # @return [String]
          def rounding_method
            self.class::ROUNDING_METHOD
          end

          # S式で使う演算子の表現を返す
          # @return [String]
          def op_for_s_exp
            "#{@op}#{rounding_method}"
          end

          # 演算を行う
          # @param lhs [Integer] 左のオペランド
          # @param rhs [Integer] 右のオペランド
          # @param round_type [Symbol] ゲームシステムの端数処理設定
          # @return [Integer] 演算の結果
          def calc(lhs, rhs, round_type)
            if rhs.zero?
              return 1
            end

            return divide_and_round(lhs, rhs, round_type)
          end

          # 除算および端数処理を行う
          # @param dividend [Integer] 被除数
          # @param divisor [Integer] 除数（0以外）
          # @param round_type [Symbol] ゲームシステムの端数処理設定
          # @return [Integer]
          def divide_and_round(dividend, divisor, round_type)
            raise NotImplementedError
          end
        end

        # 除算（端数処理はゲームシステム依存）のノード
        class DivideWithGameSystemDefault < DivideBase
          ROUNDING_METHOD = ""

          private

          # 除算および端数処理を行う
          # @param dividend [Integer] 被除数
          # @param divisor [Integer] 除数（0以外）
          # @param round_type [Symbol] ゲームシステムの端数処理設定
          # @return [Integer]
          def divide_and_round(dividend, divisor, round_type)
            case round_type
            when RoundType::CEIL
              (dividend.to_f / divisor).ceil
            when RoundType::ROUND
              (dividend.to_f / divisor).round
            else # RoundType::FLOOR
              dividend / divisor
            end
          end
        end

        # 除算（切り上げ）のノード
        class DivideWithRoundingUp < DivideBase
          # 端数処理方法を示す記号
          ROUNDING_METHOD = "U"

          private

          # 除算および端数処理を行う
          # @param (see DivideWithGameSystemDefault#divide_and_round)
          # @return [Integer]
          def divide_and_round(dividend, divisor, _round_type)
            (dividend.to_f / divisor).ceil
          end
        end

        # 除算（四捨五入）のノード
        class DivideWithRoundingOff < DivideBase
          # 端数処理方法を示す記号
          ROUNDING_METHOD = "R"

          private

          # 除算および端数処理を行う
          # @param (see DivideWithGameSystemDefault#divide_and_round)
          # @return [Integer]
          def divide_and_round(dividend, divisor, _round_type)
            (dividend.to_f / divisor).round
          end
        end

        # 除算（切り捨て）のノード
        class DivideWithRoundingDown < DivideBase
          # 端数処理方法を示す記号
          ROUNDING_METHOD = "F"

          private

          # 除算および端数処理を行う
          # @param (see DivideWithGameSystemDefault#divide_and_round)
          # @return [Integer]
          def divide_and_round(dividend, divisor, _round_type)
            dividend / divisor
          end
        end

        # 符号反転のノード
        class Negate
          # 符号反転の対象
          # @return [Object]
          attr_reader :body

          # ノードを初期化する
          # @param [Object] body 符号反転の対象
          def initialize(body)
            @body = body
          end

          # ノードを評価する
          #
          # 対象オペランドを再帰的に評価した後、評価結果の符号を反転する。
          #
          # @param [Randomizer] randomizer ランダマイザ
          # @return [Integer] 評価結果
          def eval(game_system, randomizer)
            -@body.eval(game_system, randomizer)
          end

          # @return [Boolean]
          def include_dice?
            @body.include_dice?
          end

          # 文字列に変換する
          # @return [String]
          def expr(game_system)
            "-#{@body.expr(game_system)}"
          end

          # メッセージへの出力を返す
          # @return [String]
          def output
            "-#{@body.output}"
          end

          # ノードのS式を返す
          # @return [String]
          def s_exp
            "(- #{@body.s_exp})"
          end
        end

        # ダイスロールのノード
        class DiceRoll
          # ノードを初期化する
          # @param [Number] times ダイスを振る回数のノード
          # @param [Number] sides ダイスの面数のノード
          def initialize(times, sides)
            @times = times
            @sides = sides

            # ダイスを振った結果の出力
            @text = nil
          end

          # ノードを評価する（ダイスを振る）
          #
          # 評価結果は出目の合計値になる。
          # 出目はランダマイザに記録される。
          #
          # @param [Randomizer] randomizer ランダマイザ
          # @return [Integer] 評価結果（出目の合計値）
          def eval(game_system, randomizer)
            times = @times.eval(game_system, nil)
            sides = eval_sides(game_system)

            dice_list = randomizer.roll(times, sides)

            total = dice_list.sum()
            @text = "#{total}[#{dice_list.join(',')}]"

            return total
          end

          # @return [Boolean]
          def include_dice?
            true
          end

          # 文字列に変換する
          # @return [String]
          def expr(game_system)
            times = @times.eval(game_system, nil)
            sides = eval_sides(game_system)

            "#{times}D#{sides}"
          end

          # メッセージへの出力を返す
          # @return [String]
          def output
            @text
          end

          # ノードのS式を返す
          # @return [String]
          def s_exp
            "(DiceRoll #{@times.s_exp} #{@sides.s_exp})"
          end

          private

          def eval_sides(game_system)
            @sides.eval(game_system, nil)
          end
        end

        class ImplicitSidesDiceRoll < DiceRoll
          # @param [Number] times ダイスを振る回数のノード
          def initialize(times)
            @times = times
            @text = nil
          end

          # @return [String]
          def s_exp
            "(ImplicitSidesDiceRoll #{@times.s_exp})"
          end

          private

          def eval_sides(game_system)
            game_system.sides_implicit_d
          end
        end

        # フィルタ処理付きダイスロールのノード。
        #
        # ダイスロール後、条件に従って出目を選択し、和を求める。
        class DiceRollWithFilter
          # フィルタの構造体
          #
          # 各フィルタには、あらかじめソートされた出目の配列が渡される。
          #
          # @!attribute abbr
          #   @return [Symbol] フィルタの略称
          # @!attribute apply
          #   @return [Proc] フィルタ処理の内容
          Filter = Struct.new(:abbr, :apply)

          # 大きな出目から複数個取る
          KEEP_HIGHEST = Filter.new(
            :KH,
            lambda { |sorted_values, n| sorted_values.reverse.take(n) }
          ).freeze

          # 小さな出目から複数個取る
          KEEP_LOWEST = Filter.new(
            :KL,
            lambda { |sorted_values, n| sorted_values.take(n) }
          ).freeze

          # 大きな出目から複数個除く
          DROP_HIGHEST = Filter.new(
            :DH,
            lambda { |sorted_values, n| sorted_values.reverse.drop(n) }
          ).freeze

          # 小さな出目から複数個除く
          DROP_LOWEST = Filter.new(
            :DL,
            lambda { |sorted_values, n| sorted_values.drop(n) }
          ).freeze

          # ノードを初期化する
          # @param [Object] times ダイスを振る回数のノード
          # @param [Object] sides ダイスの面数のノード
          # @param [Object] n_filtering ダイスを残す/減らす個数のノード
          # @param [Filter] filter フィルタ
          def initialize(times, sides, n_filtering, filter)
            @times = times
            @sides = sides
            @n_filtering = n_filtering
            @filter = filter

            # ダイスを振った結果の出力
            @text = nil
          end

          # ノードを評価する（ダイスを振り、出目を選択して和を求める）
          #
          # 評価結果は出目の合計値になる。
          # 出目はランダマイザに記録される。
          #
          # @param [Randomizer] randomizer ランダマイザ
          # @return [Integer] 評価結果（出目の合計値）
          def eval(game_system, randomizer)
            times = @times.eval(game_system, nil)
            sides = @sides.eval(game_system, nil)
            n_filtering = @n_filtering.eval(game_system, nil)

            sorted_values = randomizer.roll(times, sides).sort
            total = @filter
                    .apply[sorted_values, n_filtering]
                    .sum()

            @text = "#{total}[#{sorted_values.join(',')}]"

            return total
          end

          # @return [Boolean]
          def include_dice?
            true
          end

          # 文字列に変換する
          # @return [String]
          def expr(game_system)
            times = @times.eval(game_system, nil)
            sides = @sides.eval(game_system, nil)
            n_filtering = @n_filtering.eval(game_system, nil)

            "#{times}D#{sides}#{@filter.abbr}#{n_filtering}"
          end

          # メッセージへの出力を返す
          # @return [String]
          def output
            @text
          end

          # ノードのS式を返す
          # @return [String]
          def s_exp
            "(DiceRollWithFilter #{@times.s_exp} #{@sides.s_exp} #{@filter.abbr.inspect} #{@n_filtering.s_exp})"
          end
        end

        # カッコで式をまとめるノード
        class Parenthesis
          # @param expr [Object] カッコ内のノード
          def initialize(expr)
            @expr = expr
          end

          # @param randomizer [Randomizer]
          # @return [integer]
          def eval(game_system, randomizer)
            @expr.eval(game_system, randomizer)
          end

          # @return [Boolean]
          def include_dice?
            @expr.include_dice?
          end

          # @return [String]
          def expr(game_system)
            "(#{@expr.expr(game_system)})"
          end

          # @return [String]
          def output
            "(#{@expr.output})"
          end

          # @return [String] S式
          def s_exp
            "(Parenthesis #{@expr.s_exp})"
          end
        end

        # 数値のノード
        class Number
          # 値
          # @return [Integer]
          attr_reader :literal

          # ノードを初期化する
          # @param [Integer] literal 値
          def initialize(literal)
            @literal = literal
          end

          # 符号を反転した結果の数値ノードを返す
          # @return [Number]
          def negate
            Number.new(-@literal)
          end

          # ノードを評価する
          # @return [Integer] 格納している値
          def eval(_game_system, _randomizer)
            @literal
          end

          # @return [Boolean]
          def include_dice?
            false
          end

          # 文字列に変換する
          # @return [String]
          def expr(_game_system)
            @literal.to_s
          end

          def output
            @literal.to_s
          end

          alias s_exp output
        end
      end
    end
  end
end
