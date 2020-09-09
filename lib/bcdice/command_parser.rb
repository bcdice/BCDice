require "bcdice/arithmetic_evaluator"
require "bcdice/normalize"
require "bcdice/modifier_formatter"

module BCDice
  class CommandParser < ArithmeticEvaluator
    def initialize(*literals)
      @literals = literals
      @round_type = RoundType::FLOOR
      @allowed_cmp_op = nil

      @enabled_question_target = false
    end

    # @!attribute [rw] command
    #   @return [String]
    # @!attribute [rw] critical
    #   @return [Integer, nil]
    # @!attribute [rw] fumble
    #   @return [Integer, nil]
    # @!attribute [rw] dollar
    #   @return [Integer, nil]
    # @!attribute [rw] modify_number
    #   @return [Integer]
    # @!attribute [rw] cmp_op
    #   @return [Symbol, nil]
    # @!attribute [rw] target_number
    #   @return [Integer, nil]
    class Parsed
      attr_accessor :command, :critical, :fumble, :dollar, :modify_number, :cmp_op, :target_number

      attr_writer :question_target

      include ModifierFormatter

      def initialize
        @critical = nil
        @fumble = nil
        @dollar = nil
        @cmp_op = nil
        @target_number = nil
        @question_target = false
      end

      def question_target?
        @question_target
      end

      def to_s(suffix_position = :after_command)
        c = @critical ? "@#{@critical}" : nil
        f = @fumble ? "##{@fumble}" : nil
        d = @dollar ? "$#{@dollar}" : nil
        m = format_modifier(@modify_number)
        target = @question_target ? "?" : @target_number

        case suffix_position
        when :after_command
          [@command, c, f, d, m, @cmp_op, target].join()
        when :after_modify_number
          [@command, m, c, f, d, @cmp_op, target].join()
        when :after_target_number
          [@command, m, @cmp_op, target, c, f, d].join()
        end
      end
    end

    # 特定の比較演算子のみ許可するようにする。
    # 比較演算子なしを許可する場合には nil を指定してください。
    #
    # @param cmp_op [Array<Symbol, nil>] 許可する比較演算子の一覧
    # @return [self]
    def allow_cmp_op(*cmp_op)
      @allowed_cmp_op = cmp_op
      self
    end

    def enable_question_target
      @enabled_question_target = true
      self
    end

    # @param expr [String]
    # @param rount_type [Symbol]
    # @return [CommandParser::Parsed]
    # @return [nil]
    def parse(expr, round_type = RoundType::FLOOR)
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
      rhs() if @parsed.cmp_op

      if @idx < @tokens.size || @error
        return nil
      end

      return @parsed
    end

    private

    # @return [Array<String>]
    def tokenize(expr)
      expr.gsub(%r{[\(\)\+\-*/@#\$]|[<>!=]+}) { |e| " #{e} " }.split(" ")
    end

    def lhs
      command = take()
      unless literal?(command)
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

      command_suffix()

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
        elsif consume("$")
          if @parsed.dollar
            @error = true
          end
          @parsed.dollar = unary()
        else
          break
        end
      end
    end

    def rhs
      if @enabled_question_target && consume("?")
        @parsed.question_target = true
        @parsed.target_number = 0
      else
        @parsed.question_target = false
        @parsed.target_number = expr()
      end
    end

    def literal?(command)
      @literals.each do |lit|
        case lit
        when String
          return true if command == lit
        when Regexp
          return true if command =~ lit
        end
      end

      return false
    end

    def take
      ret = @tokens[@idx]
      @idx += 1

      return ret
    end

    def take_cmp_op
      cmp_op = Normalize.comparison_operator(take())
      @error ||= denied_cmp_op?(cmp_op)

      return cmp_op
    end

    def denied_cmp_op?(cmp_op)
      if @allowed_cmp_op.nil?
        false
      else
        !@allowed_cmp_op.include?(cmp_op)
      end
    end
  end
end
