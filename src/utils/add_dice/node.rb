# -*- coding: utf-8 -*-

class AddDice
  module Node
    class Command
      attr_reader :lhs, :cmp_op, :rhs

      def initialize(lhs, cmp_op, rhs)
        @lhs = lhs
        @cmp_op = cmp_op
        @rhs = rhs
      end

      def to_s
        @lhs.to_s + cmp_op_text + @rhs.to_s
      end

      private

      def cmp_op_text
        case @cmp_op
        when :'!='
          '<>'
        when :==
          '='
        else
          @cmp_op.to_s
        end
      end
    end

    class BinaryOp
      def initialize(lhs, op, rhs, round_type = nil)
        @lhs = lhs
        @op = op
        @rhs = rhs
        @round_type = round_type
      end

      def eval(randomizer)
        lhs = @lhs.eval(randomizer)
        rhs = @rhs.eval(randomizer)

        calc(lhs, rhs)
      end

      def to_s
        @lhs.to_s + @op.to_s + @rhs.to_s + round_type_suffix()
      end

      def output
        @lhs.output + @op.to_s + @rhs.output + round_type_suffix()
      end

      private

      def calc(lhs, rhs)
        if @op != :/
          return lhs.send(@op, rhs)
        end

        if rhs.zero?
          return 1
        end

        case @round_type
        when :roundUp
          (lhs.to_f / rhs).ceil
        when :roundOff
          (lhs.to_f / rhs).round
        else
          lhs / rhs
        end
      end

      def round_type_suffix
        case @round_type
        when :roundUp
          "U"
        when :roundOff
          "R"
        else
          ""
        end
      end
    end

    class Negate
      attr_reader :body

      def initialize(body)
        @body = body
      end

      def eval(randomizer)
        -@body.eval(randomizer)
      end

      def to_s
        "-#{@body}"
      end

      def output
        "-#{@body.output}"
      end
    end

    class DiceRoll
      def initialize(times, sides, critical)
        @times = times.literal
        @sides = sides.literal
        @critical = critical.nil? ? nil : critical.literal
        @text = nil
      end

      def eval(randomizer)
        total, @text = randomizer.roll(@times, @sides, @critical)

        total
      end

      def to_s
        if @critical
          "#{@times}D#{@sides}@#{@critical}"
        else
          "#{@times}D#{@sides}"
        end
      end

      def output
        @text
      end
    end

    class Number
      attr_reader :literal

      def initialize(literal)
        @literal = literal
      end

      def negate
        Number.new(-@literal)
      end

      def eval(_randomizer)
        @literal
      end

      def to_s
        @literal.to_s
      end

      alias output to_s
    end
  end
end
