# -*- coding: utf-8 -*-

class AddDice
  # 定数畳み込みをする
  class ConstantFolding
    def initialize(lhs)
      @sequence = [lhs]
    end

    # 演算子と右辺を追加する
    # @param op [Symbol]
    # @param round_type [Symbol, nil]
    # @param rhs [Object]
    def push(op, round_type, rhs)
      @sequence.push(op, round_type, rhs)
    end

    # 定数畳み込みをしたノードを生成する
    def construct_node
      fold()

      node = @sequence.shift

      while !@sequence.empty?
        op, round_type, rhs = @sequence.shift(3)
        op, rhs = sub_negative_number(op, rhs)
        node = Node::BinaryOp.new(node, op, rhs, round_type)
      end

      node
    end

    private

    # 定数畳み込みをする
    def fold
      optimized = [@sequence.shift]

      while !@sequence.empty?
        lhs = optimized.pop
        op, round_type, rhs = @sequence.shift(3)

        if lhs.is_a?(Node::Number) && rhs.is_a?(Node::Number) && (optimized.empty? || op != :/)
          num = calc(lhs.literal, op, rhs.literal, round_type)
          optimized.push(Node::Number.new(num))
        else
          optimized.push(lhs, op, round_type, rhs)
        end
      end

      @sequence = optimized
    end

    # 定数畳み込み用の事前計算処理
    def calc(lhs, op, rhs, round_type)
      if op != :/
        return lhs.send(op, rhs)
      end

      if rhs.zero?
        @error = true
        return 1
      end

      case round_type
      when :roundUp
        (lhs.to_f / rhs).ceil
      when :roundOff
        (lhs.to_f / rhs).round
      else
        lhs / rhs
      end
    end

    # 負の数の引き算などを事前に処理する
    def sub_negative_number(op, rhs)
      if rhs.is_a?(Node::Number) && rhs.literal < 0
        if op == :+
          return [:-, rhs.negate]
        elsif op == :-
          return [:+, rhs.negate]
        end
      end

      [op, rhs]
    end
  end
end
