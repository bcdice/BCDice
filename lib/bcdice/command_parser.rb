require "bcdice/arithmetic_evaluator"
require "bcdice/normalize"
require "bcdice/format"

module BCDice
  # よくある形式のコマンドのパースを補助するクラス
  #
  # @example Literal by String
  #   parser = CommandParser.new("MC")
  #   parsed = parser.parse("MC+2*3@30<=10/2-3") #=> <CommandParser::Parsed>
  #
  #   parsed.command #=> "MC"
  #   parsed.modify_number #=> 6
  #   parsed.critical #=> 30
  #   parsed.cmp_op #=> #>=
  #   parsed.target_number #=> 2
  #
  # @example Literal by Regexp
  #   parser = CommandParser.new(/^RE\d+$/)
  #   parsed = parser.parse("RE44+20") #=> <CommandParser::Parsed>
  #
  #   parsed.command #=> "RE44"
  #   parsed.modify_number #=> 20
  class CommandParser < ArithmeticEvaluator
    # @param literals [Array<String, Regexp>]
    def initialize(*literals)
      @literals = literals
      @round_type = RoundType::FLOOR
      @allowed_cmp_op = nil

      @enabled_question_target = false
    end

    # パース結果
    class Parsed
      # @return [String]
      attr_accessor :command

      # @return [Integer, nil]
      attr_accessor :critical

      # @return [Integer, nil]
      attr_accessor :fumble

      # @return [Integer, nil]
      attr_accessor :dollar

      # @return [Integer]
      attr_accessor :modify_number

      # @return [Symbol, nil]
      attr_accessor :cmp_op

      # @return [Integer, nil]
      attr_accessor :target_number

      # @param value [Boolean]
      # @return [Boolean]
      attr_writer :question_target

      def initialize
        @critical = nil
        @fumble = nil
        @dollar = nil
        @cmp_op = nil
        @target_number = nil
        @question_target = false
      end

      # @return [Boolean]
      def question_target?
        @question_target
      end

      # @param suffix_position [Symbol] クリティカルなどの表示位置
      # @return [String]
      def to_s(suffix_position = :after_command)
        c = @critical ? "@#{@critical}" : nil
        f = @fumble ? "##{@fumble}" : nil
        d = @dollar ? "$#{@dollar}" : nil
        m = Format.modifier(@modify_number)
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

    # 目標値 "?" を許容する
    #
    # @return [self]
    def enable_question_target
      @enabled_question_target = true
      self
    end

    # 式をパースする
    #
    # @param expr [String]
    # @param round_type [Symbol]
    # @return [CommandParser::Parsed, nil]
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
