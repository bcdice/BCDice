# frozen_string_literal: true

module BCDice
  module DiceTable
    class RollResult
      # @param table_name [String]
      # @param value [Integer]
      # @param body [String, RollResult]
      def initialize(table_name, value, body)
        @table_name = table_name
        @value = value
        @body = body
      end

      # @return [String]
      attr_reader :table_name

      # @return [Integer]
      attr_reader :value

      # @return [String, RollResult]
      attr_reader :body

      # @return [String]
      def to_s
        "#{@table_name}(#{@value}) ＞ #{@body}"
      end

      # @return [String]
      def last_body
        if @body.is_a?(RollResult)
          @body.last_body
        else
          @body
        end
      end

      # 一部のゲームシステムが String#empty? を想定してチェックしているため
      # @return [false]
      def empty?
        false
      end
    end
  end
end
