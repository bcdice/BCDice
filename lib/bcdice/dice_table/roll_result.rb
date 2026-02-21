# frozen_string_literal: true

module BCDice
  module DiceTable
    class RollResult
      class << self
        def new_with_chain(table_name, value, result, randomizer)
          if result.is_a?(ChainWithText)
            new(table_name, value, result.text, result.table.roll(randomizer))
          elsif result.respond_to?(:roll)
            new(table_name, value, result.roll(randomizer))
          else
            new(table_name, value, result)
          end
        end
      end

      # @param table_name [String]
      # @param value [Integer]
      # @param body [String, RollResult]
      # @param succ [RollResult, nil]
      def initialize(table_name, value, body, succ = nil)
        @table_name = table_name
        @value = value
        @body = body
        @succ = succ
      end

      # @return [String]
      attr_reader :table_name

      # @return [Integer]
      attr_reader :value

      # @return [String, RollResult]
      attr_reader :body

      # @return [RollResult, nil]
      attr_reader :succ

      # @return [String]
      def to_s
        if @succ
          "#{@table_name}(#{@value}) ＞ #{@body} ＞ #{@succ}"
        else
          "#{@table_name}(#{@value}) ＞ #{@body}"
        end
      end

      # @return [String]
      def last_body
        if @succ
          @succ.last_body
        elsif @body.is_a?(RollResult)
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
