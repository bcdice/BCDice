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
          l = lhs.eval(round_type)
          r = rhs.eval(round_type)
          l.send(op, r)
        end

        def s_exp
          "(#{op} #{lhs.s_exp} #{rhs.s_exp}}"
        end

        private

        attr_reader :op, :lhs, :rhs
      end

      # 除算ノードの基底クラス
      class DivideBase < BinaryOp
        def initialize(lhs, rhs)
          super(lhs, :/, rhs)
        end

        def eval(round_type)
          l = lhs.eval(round_type)
          r = rhs.eval(round_type)
          divide_and_round(l, r, round_type)
        end

        private

        # 除算および端数処理を行う
        # @param [Integer] _dividend 被除数
        # @param [Integer] _divisor 除数（0以外）
        # @param [Symbol] _round_type ゲームシステムの端数処理設定
        # @return [Integer]
        def divide_and_round(_dividend, _divisor, _round_type)
          raise NotImplementedError
        end
      end

      # 除算（切り上げ）のノード
      class DivideWithCeil < DivideBase
        private

        def op
          "/C"
        end

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
        private

        def op
          "/R"
        end

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
        private

        def op
          "/F"
        end

        # 除算および端数処理を行う
        # @param [Integer] dividend 被除数
        # @param [Integer] divisor 除数（0以外）
        # @param [Symbol] _round_type ゲームシステムの端数処理設定
        # @return [Integer]
        def divide_and_round(dividend, divisor, _round_type)
          dividend / divisor
        end
      end

      # 除算（端数処理はゲームシステム依存）のノード
      class DivideWithGameSystemDefault < DivideBase
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

      class Negative
        def initialize(body)
          @body = body
        end

        def eval(round_type)
          -@body.eval(round_type)
        end

        def s_exp
          "(- #{@body.s_exp})"
        end
      end

      class Number
        def initialize(value)
          @value = value
        end

        def eval(_round_type)
          @value
        end

        def s_exp
          @value.to_s
        end
      end
    end
  end
end
