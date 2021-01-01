# frozen_string_literal: true

module BCDice
  module ArithmeticEvaluator
    class << self
      # 四則演算を評価する
      # @deprecated +Arithmetic.#eval+ を利用してください。
      # @param expr [String, nil] 評価する式
      # @param round_type [Symbol] 端数処理の種類
      # @return [Integer] 評価結果を返す。不正な式の場合には0を返す。
      def eval(expr, round_type: RoundType::FLOOR)
        return 0 unless expr

        Arithmetic.eval(expr, round_type) || 0
      end
    end
  end
end
