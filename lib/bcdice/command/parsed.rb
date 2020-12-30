# frozen_string_literal: true

module BCDice
  module Command
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
  end
end
