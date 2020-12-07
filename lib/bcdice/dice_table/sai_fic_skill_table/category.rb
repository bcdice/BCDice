# frozen_string_literal: true

module BCDice
  module DiceTable
    class SaiFicSkillTable
      class Category
        def initialize(name, skills, dice, s_format)
          @name = name
          @skills = skills
          @dice = dice
          @s_format = s_format
        end

        def roll(randomizer)
          skill_dice = randomizer.roll_sum(2, 6)
          skill = @skills[skill_dice - 2]
          SaiFicSkillTable::Skill.new(@name, skill, @dice, skill_dice, @s_format)
        end

        def to_s
          @name
        end

        attr_reader :name, :dice, :skills
      end
    end
  end
end
