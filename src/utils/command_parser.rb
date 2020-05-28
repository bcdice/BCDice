require "utils/ArithmeticEvaluator"
require "utils/normalize"

class CommandParser < ArithmeticEvaluator
  def initialize(*literals)
    @literals = literals
    @round_type = :omit
  end

  def parse(expr, round_type = :omit)
    @tokens = tokenize(expr)
    @idx = 0
    @error = false
    @round_type = round_type

    @parsed = Parsed.new()

    lhs()
    if @error
      return nil
    end

    @parsed.cmp_op = take_cmp_op()
    @parsed.target_number = @parsed.cmp_op ? expr() : nil

    if @idx < @tokens.size || @error
      return nil
    end

    return @parsed
  end

  Parsed = Struct.new(:command, :critical, :fumble, :modify_number, :cmp_op, :target_number)

  private

  def tokenize(expr)
    expr.gsub(%r{[\(\)\+\-*/@#]|[<>!=]+}) { |e| " #{e} " }.split(' ')
  end

  def lhs
    command = take()
    unless @literals.include?(command)
      @error = true
      return
    end

    command_suffix()

    ret = 0
    loop do
      if consume("+")
        ret += mul()
      elsif consume("-")
        ret -= mul()
      else
        break
      end
    end

    @parsed.command = command
    @parsed.modify_number = ret
  end

  def command_suffix
    loop do
      if consume("@")
        if @parsed.critical
          @error = true
        end
        @parsed.critical = unary()
      elsif consume("#")
        if @parsed.fumble
          @error = true
        end
        @parsed.fumble = unary()
      else
        break
      end
    end
  end

  def take
    ret = @tokens[@idx]
    @idx += 1

    return ret
  end

  def take_cmp_op
    Normalize.comparison_operator(take())
  end
end
