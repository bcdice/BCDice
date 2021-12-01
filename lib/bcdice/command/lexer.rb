# frozen_string_literal: true

require "strscan"
require "bcdice/normalize"

module BCDice
  module Command
    class Lexer
      SYMBOLS = {
        "+" => :PLUS,
        "-" => :MINUS,
        "*" => :ASTERISK,
        "/" => :SLASH,
        "(" => :PARENL,
        ")" => :PARENR,
        "?" => :QUESTION,
        "@" => :AT,
        "#" => :SHARP,
        "$" => :DOLLAR,
        "&" => :AMPERSAND,
      }.freeze

      def initialize(source, notations)
        # sourceが空文字だとString#splitが空になる
        source = source&.split(" ", 2)&.first || ""
        @scanner = StringScanner.new(source)
        @notations = notations.map do |n|
          n.is_a?(String) ? Regexp.new(n) : n
        end
      end

      def next_token
        return [false, "$"] if @scanner.eos?

        @notations.each do |n|
          token = @scanner.scan(n)
          return [:NOTATION, token] if token
        end

        if (number = @scanner.scan(/\d+/))
          [:NUMBER, number.to_i]
        elsif (cmp_op = @scanner.scan(/[<>!=]+/))
          cmp_op = Normalize.comparison_operator(cmp_op)
          type = cmp_op ? :CMP_OP : :ILLEGAL
          [type, cmp_op]
        else
          char = @scanner.getch.upcase
          type = SYMBOLS[char] || char.to_sym
          [type, char]
        end
      end

      def source
        @scanner.string
      end
    end
  end
end
