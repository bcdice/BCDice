module BCDice
  module DiceTable
    class SaiFicSkillTable
      def initialize(items, peekaboo_style: false)
        @items = items
        @peekaboo_style = peekaboo_style
      end

      def roll(randomizer)
        category_dice = randomizer.roll_once(6)
        cindex = category_dice - 1
        category, skill_list = @items[cindex]

        skill_dice = randomizer.roll_sum(2, 6)
        sindex = skill_dice - 2
        skill = skill_list[sindex]

        return "ランダム指定特技表(#{category_dice},#{skill_dice}) ＞ #{result(category, skill, skill_dice)}"
      end

      private

      def result(category, skill, skill_dice)
        if @peekaboo_style
          "《#{skill}／#{category}#{skill_dice}》"
        else
          "#{category}《#{skill}》"
        end
      end
    end
  end
end
