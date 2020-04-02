# -*- coding: utf-8 -*-

require "utils/ArithmeticEvaluator"
require "utils/normalize"
require "utils/add_dice/node"
require "utils/add_dice/constant_folding"

class AddDice
  class Parser
    def initialize(expr)
      @expr = expr
      @idx = 0
      @error = false
    end

    def parse()
      lhs, cmp_op, rhs = @expr.partition(/[<>=]+/)

      cmp_op = Normalize.comparison_operator(cmp_op)
      if !rhs.empty? && rhs != "?"
        rhs = ArithmeticEvaluator.new.eval(rhs)
      end

      @tokens = tokenize(lhs)
      lhs = expr()

      if @idx != @tokens.size
        @error = true
      end

      return AddDice::Node::Command.new(lhs, cmp_op, rhs)
    end

    def error?
      @error
    end

    private

    def tokenize(expr)
      expr.gsub(%r{[\+\-\*/DURS@]}) { |e| " #{e} " }.split(' ')
    end

    def expr
      consume("S")

      return add()
    end

    def add
      folder = ConstantFolding.new(mul())

      loop do
        if consume("+")
          folder.push(:+, nil, mul())
        elsif consume("-")
          folder.push(:-, nil, mul())
        else
          break
        end
      end

      return folder.construct_node()
    end

    def mul
      folder = ConstantFolding.new(unary())

      loop do
        if consume("*")
          folder.push(:*, nil, unary())
        elsif consume("/")
          rhs = unary()
          round_type = consume_round_type()
          folder.push(:/, round_type, rhs)
        else
          break
        end
      end

      return folder.construct_node()
    end

    def unary
      if consume("+")
        unary()
      elsif consume("-")
        node = unary()

        case node
        when Node::Negate
          node.body
        when Node::Number
          node.negate()
        else
          AddDice::Node::Negate.new(node)
        end
      else
        term()
      end
    end

    def term
      ret = expect_number()
      if consume("D")
        times = ret
        sides = expect_number()
        critical = consume("@") ? expect_number() : nil

        ret = AddDice::Node::DiceRoll.new(times, sides, critical)
      end

      ret
    end

    def consume(str)
      if @tokens[@idx] != str
        return false
      end

      @idx += 1
      return true
    end

    def consume_round_type()
      if consume("U")
        :roundUp
      elsif consume("R")
        :roundOff
      end
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
        return AddDice::Node::Number.new(0)
      end

      ret = @tokens[@idx].to_i
      @idx += 1
      return AddDice::Node::Number.new(ret)
    end

    def integer?(str)
      # Ruby 1.9 以降では Kernel.#Integer を使うべき
      # Ruby 1.8 にもあるが、基数を指定できない問題がある
      !/^\d+$/.match(str).nil?
    end
  end
end
