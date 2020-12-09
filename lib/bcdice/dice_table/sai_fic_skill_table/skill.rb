# frozen_string_literal: true

module BCDice
  module DiceTable
    class SaiFicSkillTable
      class Skill
        def initialize(category_name, skill_name, category_dice, row_dice, s_format)
          @category_name = category_name
          @name = skill_name
          @category_dice = category_dice
          @row_dice = row_dice
          @s_format = s_format
        end

        def to_s
          format(@s_format, category_dice: @category_dice, row_dice: @row_dice, category_name: @category_name, skill_name: @name)
        end

        attr_reader :category_name, :name, :category_dice, :row_dice
      end
    end
  end
end
