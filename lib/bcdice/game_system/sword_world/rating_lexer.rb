# frozen_string_literal: true

require "strscan"

module BCDice
  module GameSystem
    class SwordWorld < Base
      class RatingLexer
        SYMBOLS = {
          "+" => :PLUS,
          "-" => :MINUS,
          "*" => :ASTERISK,
          "/" => :SLASH,
          "(" => :PARENL,
          ")" => :PARENR,
          "[" => :BRACKETL,
          "]" => :BRACKETR,
          "@" => :AT,
          "#" => :SHARP,
          "$" => :DOLLAR,
          "~" => :TILDE,
        }.freeze

        def initialize(source)
          # sourceが空文字だとString#splitが空になる
          source = source&.split(" ", 2)&.first || ""
          @scanner = StringScanner.new(source)
        end

        def next_token
          return [false, "$"] if @scanner.eos?

          if (number = @scanner.scan(/\d+/))
            [:NUMBER, number.to_i]
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
end
