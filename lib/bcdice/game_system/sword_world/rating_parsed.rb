# frozen_string_literal: true

module BCDice
  module GameSystem
    class SwordWorld < Base
      class RatingParsed
        # @return [Integer]
        attr_accessor :rate

        # @return [Integer, nil]
        attr_accessor :critical

        # @return [Integer, nil]
        attr_accessor :kept_modify

        # @return [Integer, nil]
        attr_accessor :first_to

        # @return [Integer, nil]
        attr_accessor :first_modify

        # @return [Integer, nil]
        attr_accessor :rateup

        # @return [Boolean]
        attr_accessor :greatest_fortune

        # @return [Integer]
        attr_accessor :modifier

        # @return [Integer, nil]
        attr_accessor :modifier_after_half

        def initialize
          @critical = nil
          @kept_modify = nil
          @first_to = nil
          @first_modify = nil
          @greatest_fortune = nil
          @rateup = nil
        end

        # @return [Boolean]
        def half
          return !modifier_after_half.nil?
        end

        # @return [Integer]
        def sanitized_critical
          crit = @critical || (half ? 13 : 10)
          crit = 3 if crit < 3
          return crit
        end

        # @return [Integer]
        def sanitized_first_modify
          return @first_modify || 0
        end

        # @return @[Integer]
        def sanitized_first_to
          return @first_to || 0
        end

        # @return @[Integer]
        def sanitized_rateup
          return @rateup || 0
        end

        # @return @[Integer]
        def sanitized_kept_modify
          return @kept_modify || 0
        end

        # @return @[Integer]
        def sanitized_modifier_after_half
          return @modifier_after_half || 0
        end

        # @return [String]
        def to_s()
          output = "KeyNo.#{@rate}"

          output += "c[#{sanitized_critical}]" if sanitized_critical < 13
          output += "m[#{Format.modifier(sanitized_first_modify)}]" if sanitized_first_modify != 0
          output += "m[#{sanitized_first_to}]" if sanitized_first_to != 0
          output += "r[#{sanitized_rateup}]" if sanitized_rateup != 0
          output += "gf" if @greatest_fortune
          output += "a[#{Format.modifier(sanitized_kept_modify)}]" if sanitized_kept_modify != 0

          if @modifier != 0
            output += Format.modifier(@modifier)
          end
          return output
        end
      end
    end
  end
end
