module BCDice
  #
  # 四則演算を評価するクラス
  #
  class ArithmeticEvaluator
    class << self
      # 四則演算を評価する
      # @param expr [String] 評価する式
      # @param round_type [Symbol] 端数処理の種類
      # @return [Integer] 評価結果を返す。不正な式の場合には0を返す。
      def eval(expr, round_type: RoundType::FLOOR)
        ArithmeticEvaluator.new(expr, round_type: round_type).eval()
      end
    end

    # @param [String, nil] expr 評価する式
    # @param [Symbol] round_type 端数処理の種類
    def initialize(expr, round_type: RoundType::FLOOR)
      @expr = expr
      @round_type = round_type

      @error = false
    end

    # @return [Boolean] 式の評価時にエラーが発生したか
    def error?
      @error
    end

    # 四則演算を評価する
    # 同一インスタンスでevalを二回以上実行した場合の挙動は未定義とする
    #
    # @return [Integer] 評価結果を返す。不正な式の場合には0を返す。
    def eval
      if @expr.nil?
        return 0
      end

      unless @expr.is_a?(String)
        raise TypeError, "expr must be String, not #{@expr.class}"
      end

      @tokens = tokenize(@expr)
      @idx = 0
      @error = false

      ret = expr()
      if @error
        return 0
      else
        return ret
      end
    end

    private

    def tokenize(expr)
      expr.gsub(%r{[\(\)\+\-\*/]}) { |e| " #{e} " }.split(" ")
    end

    def add
      ret = mul()

      loop do
        if consume("+")
          ret += mul()
        elsif consume("-")
          ret -= mul()
        else
          break
        end
      end

      return ret
    end
    alias expr add

    def mul
      ret = unary()

      loop do
        if consume("*")
          ret *= unary()
        elsif consume("/")
          ret = div(ret, unary())
        else
          break
        end
      end

      return ret
    end

    def div(left, right)
      if right.zero?
        @error = true
        return 0
      end

      case @round_type
      when RoundType::CEIL
        return (left.to_f / right).ceil
      when RoundType::ROUND
        return (left.to_f / right).round
      when RoundType::FLOOR
        return left / right
      else
        raise ArgumentError, "unknown round type: #{@round_type.inspect}"
      end
    end

    def unary
      if consume("+")
        unary()
      elsif consume("-")
        -unary()
      else
        term()
      end
    end

    def term
      if consume("(")
        ret = expr()
        expect(")")
        return ret
      else
        return expect_number()
      end
    end

    def consume(str)
      if @tokens[@idx] != str
        return false
      end

      @idx += 1
      return true
    end

    def expect(str)
      if @tokens[@idx] != str
        @error = true
      end

      @idx += 1
    end

    def expect_number()
      unless integer?(@tokens[@idx])
        @error = true
        @idx += 1
        return 0
      end

      ret = @tokens[@idx].to_i
      @idx += 1
      return ret
    end

    def integer?(str)
      # Ruby 1.9 以降では Kernel.#Integer を使うべき
      # Ruby 1.8 にもあるが、基数を指定できない問題がある
      !/^\d+$/.match(str).nil?
    end
  end
end
