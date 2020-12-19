# frozen_string_literal: true

module BCDice
  module DiceTable
    class SaiFicSkillTable
      class Category
        def initialize(name, skills, dice, s_format)
          @name = name
          @skills = skills.map.with_index(2) { |s, index| SaiFicSkillTable::Skill.new(name, s, dice, index, s_format) }
          @dice = dice
        end

        def roll(randomizer)
          skills[randomizer.roll_sum(2, 6) - 2]
        end

        def to_s
          @name
        end

        attr_reader :name, :dice, :skills
      end
    end
  end
end
