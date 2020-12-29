# frozen_string_literal: true

module BCDice
  module Arithmetic
    module Node
      class BinaryOp
        def initialize(lhs, op, rhs)
          @lhs = lhs
          @op = op
          @rhs = rhs
        end

        def eval(round_type)
          l = @lhs.eval(round_type)
          r = @rhs.eval(round_type)
          l.send(@op, r)
        end

        # @return [String] メッセージへの出力
        def output
          "#{@lhs.output}#{@op}#{@rhs.output}"
        end

        # @return [String] ノードのS式
        def s_exp
          "(#{op_for_s_exp} #{@lhs.s_exp} #{@rhs.s_exp})"
        end

        # @return [String] S式で使う演算子の表現
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

        def eval(round_type)
          l = @lhs.eval(round_type)
          r = @rhs.eval(round_type)
          divide_and_round(l, r, round_type)
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

        # 除算および端数処理を行う
        # @param [Integer] _dividend 被除数
        # @param [Integer] _divisor 除数（0以外）
        # @param [Symbol] _round_type ゲームシステムの端数処理設定
        # @return [Integer]
        def divide_and_round(_dividend, _divisor, _round_type)
          raise NotImplementedError
        end
      end

      # 除算（端数処理はゲームシステム依存）のノード
      class DivideWithGameSystemDefault < DivideBase
        # 端数処理方法を示す記号
        ROUNDING_METHOD = ""

        private

        # 除算および端数処理を行う
        # @param [Integer] dividend 被除数
        # @param [Integer] divisor 除数（0以外）
        # @param [Symbol] round_type ゲームシステムの端数処理設定
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
      class DivideWithCeil < DivideBase
        # 端数処理方法を示す記号
        ROUNDING_METHOD = "C"

        private

        # 除算および端数処理を行う
        # @param [Integer] dividend 被除数
        # @param [Integer] divisor 除数（0以外）
        # @param [Symbol] _round_type ゲームシステムの端数処理設定
        # @return [Integer]
        def divide_and_round(dividend, divisor, _round_type)
          (dividend.to_f / divisor).ceil
        end
      end

      # 除算（四捨五入）のノード
      class DivideWithRound < DivideBase
        # 端数処理方法を示す記号
        ROUNDING_METHOD = "R"

        private

        # 除算および端数処理を行う
        # @param [Integer] dividend 被除数
        # @param [Integer] divisor 除数（0以外）
        # @param [Symbol] _round_type ゲームシステムの端数処理設定
        # @return [Integer]
        def divide_and_round(dividend, divisor, _round_type)
          (dividend.to_f / divisor).round
        end
      end

      # 除算（切り捨て）のノード
      class DivideWithFloor < DivideBase
        # 端数処理方法を示す記号
        ROUNDING_METHOD = "F"

        private

        # 除算および端数処理を行う
        # @param [Integer] dividend 被除数
        # @param [Integer] divisor 除数（0以外）
        # @param [Symbol] _round_type ゲームシステムの端数処理設定
        # @return [Integer]
        def divide_and_round(dividend, divisor, _round_type)
          dividend / divisor
        end
      end

      class Negative
        def initialize(body)
          @body = body
        end

        def eval(round_type)
          -@body.eval(round_type)
        end

        # @return [String] メッセージへの出力
        def output
          "-#{@body.output}"
        end

        def s_exp
          "(- #{@body.s_exp})"
        end
      end

      # カッコで式をまとめるノード
      class Parenthesis
        # @param expr [Object] カッコ内のノード
        def initialize(expr)
          @expr = expr
        end

        # @param round_type [Symbol] 端数処理方法
        # @return [Integer] 評価結果
        def eval(round_type)
          @expr.eval(round_type)
        end

        # @return [String] メッセージへの出力
        def output
          "(#{@expr.output})"
        end

        # @return [String] S式
        def s_exp
          "(Parenthesis #{@expr.s_exp})"
        end
      end

      class Number
        def initialize(value)
          @value = value
        end

        def eval(_round_type)
          @value
        end

        # @return [String] メッセージへの出力
        def output
          @value.to_s
        end

        alias s_exp output
      end
    end
  end
end
