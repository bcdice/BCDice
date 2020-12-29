# frozen_string_literal: true

require "bcdice/arithmetic/node"
require "bcdice/arithmetic/parser"

module BCDice
  module Arithmetic
    class << self
      # 四則演算を評価する
      #
      # @param source [String]
      # @param round_type [Symbol]
      # @return [Integer, nil] パースできない式やゼロ除算が発生した場合にはnilを返す
      def eval(source, round_type)
        node = Parser.parse(source)
        node&.eval(round_type)
      rescue ZeroDivisionError
        nil
      end
    end
  end
end
