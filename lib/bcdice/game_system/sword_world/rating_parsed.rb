# frozen_string_literal: true

module BCDice
  module GameSystem
    class SwordWorld < Base
      class RatingParsed
        # @return [Integer]
        attr_accessor :rate

        # @return [Integer]
        attr_accessor :critical

        # @return [Integer]
        attr_accessor :kept_modify

        # @return [Integer]
        attr_accessor :first_to

        # @return [Integer]
        attr_accessor :first_modify

        # @return [Integer]
        attr_accessor :first_modify_ssp

        # @return [Integer]
        attr_accessor :rateup

        # @return [Boolean]
        attr_accessor :greatest_fortune

        # @return [Integer]
        attr_accessor :semi_fixed_val

        # @return [Integer]
        attr_accessor :tmp_fixed_val

        # @return [Integer]
        attr_accessor :modifier

        # @return [Integer, nil]
        attr_accessor :modifier_after_half

        # @return [Integer, nil]
        attr_accessor :modifier_after_one_and_a_half

        def initialize(rate, modifier)
          @rate = rate
          @modifier = modifier
          @critical = 13
          @kept_modify = 0
          @first_to = 0
          @first_modify = 0
          @first_modify_ssp = 0
          @greatest_fortune = false
          @rateup = 0
          @semi_fixed_val = 0
          @tmp_fixed_val = 0
          @modifier_after_half = nil
          @modifier_after_one_and_a_half = nil
        end

        # @return [Boolean]
        def half
          return !@modifier_after_half.nil?
        end

        # @return [Boolean]
        def one_and_a_half
          return !@modifier_after_one_and_a_half.nil?
        end

        # @return [Integer]
        def min_critical
          if @semi_fixed_val <= 1
            return 3
          else
            return (@semi_fixed_val + @kept_modify + 2).clamp(3, 13)
          end
        end

        # @return [Boolean]
        def infinite_roll?
          return critical < min_critical
        end

        # @return [String]
        def to_s()
          output = "KeyNo.#{@rate}"

          output += "c[#{critical}]" if critical < 13
          output += "m[#{Format.modifier(first_modify)}]" if first_modify != 0
          output += "m[~#{Format.modifier(first_modify_ssp)}]" if first_modify_ssp != 0
          output += "m[#{first_to}]" if first_to != 0
          output += "r[#{rateup}]" if rateup != 0
          output += "gf" if @greatest_fortune
          output += "sf[#{semi_fixed_val}]" if semi_fixed_val != 0
          output += "tf[#{tmp_fixed_val}]" if tmp_fixed_val != 0
          output += "a[#{Format.modifier(kept_modify)}]" if kept_modify != 0

          if @modifier != 0
            output += Format.modifier(@modifier)
          end
          return output
        end
      end
    end
  end
end
