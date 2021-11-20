# frozen_string_literal: true

module BCDice
  module GameSystem
    class SwordWorld < Base
      class RatingParsed
        # @return [Integer]
        attr_accessor :rate

        # @return [Integer, nil]
        attr_writer :critical

        # @return [Integer, nil]
        attr_writer :kept_modify

        # @return [Integer, nil]
        attr_writer :first_to

        # @return [Integer, nil]
        attr_writer :first_modify

        # @return [Integer, nil]
        attr_writer :rateup

        # @return [Boolean]
        attr_accessor :greatest_fortune

        # @return [Integer, nil]
        attr_writer :semi_fixed_val
        
        # @return [Integer, nil]
        attr_writer :tmp_fixed_val

        # @return [Integer]
        attr_accessor :modifier

        # @return [Integer, nil]
        attr_writer :modifier_after_half

        def initialize
          @critical = nil
          @kept_modify = nil
          @first_to = nil
          @first_modify = nil
          @greatest_fortune = false
          @rateup = nil
          @semi_fixed_val = nil
          @tmp_fixed_val = nil
        end

        # @return [Boolean]
        def half
          return !@modifier_after_half.nil?
        end

        # @return [Integer]
        def critical
          crit = @critical || (half ? 13 : 10)
          crit = 3 if crit < 3
          if !@semi_fixed_val.nil?
            crit = @semi_fixed_val + 2 if crit < @semi_fixed_val + 2
          end
          return crit
        end

        # @return [Integer]
        def first_modify
          return @first_modify || 0
        end

        # @return [Integer]
        def first_to
          return @first_to || 0
        end

        # @return [Integer]
        def rateup
          return @rateup || 0
        end
        
        # @return [Integer]
        def semi_fixed_val
          sf = @semi_fixed_val || 0
          sf = 6 if sf > 6
          return sf
        end
        
        # @return [Integer]
        def tmp_fixed_val
          tf = @tmp_fixed_val || 0
          tf = 6 if tf > 6
          return tf
        end

        # @return [Integer]
        def kept_modify
          return @kept_modify || 0
        end

        # @return [Integer]
        def modifier_after_half
          return @modifier_after_half || 0
        end

        # @return [String]
        def to_s()
          output = "KeyNo.#{@rate}"

          output += "c[#{critical}]" if critical < 13
          output += "m[#{Format.modifier(first_modify)}]" if first_modify != 0
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
