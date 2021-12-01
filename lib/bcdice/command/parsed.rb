# frozen_string_literal: true

module BCDice
  module Command
    class Parsed
      # @return [String]
      attr_accessor :command

      # @return [Integer, nil]
      attr_accessor :prefix_number

      # @return [Integer, nil]
      attr_accessor :suffix_number

      # @return [Integer, nil]
      attr_accessor :critical

      # @return [Integer, nil]
      attr_accessor :fumble

      # @return [Integer, nil]
      attr_accessor :dollar

      # @return [Integer, nil]
      attr_accessor :ampersand

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
        @prefix_number = nil
        @suffix_number = nil
        @critical = nil
        @fumble = nil
        @dollar = nil
        @ampersand = nil
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
        a = @ampersand ? "&#{@ampersand}" : nil
        m = Format.modifier(@modify_number)
        target = @question_target ? "?" : @target_number

        case suffix_position
        when :after_command
          [@prefix_number, @command, @suffix_number, c, f, d, a, m, @cmp_op, target].join()
        when :after_modify_number
          [@prefix_number, @command, @suffix_number, m, c, f, d, a, @cmp_op, target].join()
        when :after_target_number
          [@prefix_number, @command, @suffix_number, m, @cmp_op, target, c, f, d, a].join()
        end
      end
    end
  end
end
