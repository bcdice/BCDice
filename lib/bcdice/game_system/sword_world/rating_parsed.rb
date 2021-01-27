# frozen_string_literal: true

module BCDice
  module GameSystem
    class SwordWorld < Base
      class RatingParsed
        # @return [Boolean]
        attr_accessor :half

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

        # @return [Boolean, nil]
        attr_accessor :greatest_fortune

        # @return [Integer]
        attr_accessor :modifier

        # @return [Integer]
        attr_accessor :modifier_after_half

        def initialize
          @half = false
          @critical = nil
          @kept_modify = nil
          @first_to = nil
          @first_modify = nil
          @greatest_fortune = nil
          @rateup = nil
        end

        # @return [String]
        def to_s()
          h = @half ? "H" : nil
          r = "K#{@rate}"
          c = @critical ? "@#{@critical}" : nil
          ft = @first_to ? "$#{@first_to}" : nil
          fm = @first_modify ? "$#{Format.modifier(@first_modify)}" : nil
          km = @kept_modify ? "##{@kept_modify}" : nil
          gf = @greatest_fortune ? "GF" : nil
          ru = @rateup ? "r#{@rateup}" : nil
          m = Format.modifier(@modifier)
          mah = @half ? Format.modifier(@modifier_after_half) : nil

          [r, m, c, ft, fm, km, gf, ru, h, mah].join()
        end
      end
    end
  end
end
