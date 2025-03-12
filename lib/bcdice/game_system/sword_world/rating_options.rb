# frozen_string_literal: true

module BCDice
  module GameSystem
    class SwordWorld < Base
      class RatingOptions
        # @return [Integer, nil]
        attr_accessor :critical

        # @return [Integer, nil]
        attr_accessor :kept_modify

        # @return [Integer, nil]
        attr_accessor :first_to

        # @return [Integer, nil]
        attr_accessor :first_modify

        # @return [Integer, nil]
        attr_accessor :first_modify_ssp

        # @return [Integer, nil]
        attr_accessor :rateup

        # @return [Boolean, nil]
        attr_accessor :greatest_fortune

        # @return [Integer, nil]
        attr_accessor :semi_fixed_val

        # @return [Integer, nil]
        attr_accessor :tmp_fixed_val

        # @return [Integer, nil]
        attr_accessor :modifier

        # @return [Integer, nil]
        attr_accessor :modifier_after_half

        # @return [Integer, nil]
        attr_accessor :modifier_after_one_and_a_half

        def settable_first_roll_adjust_option?
          return first_modify.nil? && first_to.nil? && first_modify_ssp.nil?
        end

        def settable_non_2d_roll_option?
          return greatest_fortune.nil? && semi_fixed_val.nil? && tmp_fixed_val.nil?
        end
      end
    end
  end
end
