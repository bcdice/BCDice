# frozen_string_literal: true

module BCDice
  module DiceTable
    class SaiFicSkillTable
      class Skill
        def initialize(category_name, skill_name, category_dice, row_dice, s_format)
          @category_name = category_name
          @skill_name = skill_name
          @category_dice = category_dice
          @row_dice = row_dice
          @s_format = s_format
        end

        def to_s(text_format = nil)
          if text_format.nil?
            format(@s_format, category_dice: category_dice, row_dice: row_dice, category_name: category_name, skill_name: skill_name)
          else
            format(text_format, category_dice: category_dice, row_dice: row_dice, category_name: category_name, skill_name: skill_name, text: to_s)
          end
        end

        attr_reader :category_name, :skill_name, :category_dice, :row_dice
      end
    end
  end
end
