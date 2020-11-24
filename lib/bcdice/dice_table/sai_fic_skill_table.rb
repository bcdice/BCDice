module BCDice
  module DiceTable
    class SaiFicSkillTable
      def initialize(items, peekaboo_style: false, rtt: /^RTT$/i, rttn: /^RTT([1-6])$/i, rct: /^RCT$/i)
        @items = items
        @peekaboo_style = peekaboo_style
        @rtt = rtt
        @rttn = rttn
        @rct = rct
      end

      def roll_command(randomizer, command)
        if @rtt =~ command
          roll(randomizer)
        elsif @rttn =~ command
          roll(randomizer, Regexp.last_match(1).to_i)
        elsif @rct =~ command
          cat,dice = roll_category(randomizer)
          "ランダム分野(#{dice})＞ #{cat}"
        end
      end

      def roll(randomizer, category_dice = nil)
        skill = get_skill(randomizer, category_dice)
        if category_dice
          skill.result_rttn
        else
          skill.result_rtt
        end
      end

      def get_skill(randomizer, category_dice = nil)
        category_dice ||= randomizer.roll_once(6)
        row_dice = randomizer.roll_sum(2, 6)
        return SaiFicSkill.new(@items,category_dice, row_dice)
      end

      # ランダム分野
      #
      # @param randomizer [Randomizer] 乱数生成器
      ##### @return [RollResult]
      def roll_category(randomizer)
        category_dice = randomizer.roll_once(6)
        category = @items[category_dice - 1][0]
        return category, category_dice
      end

      def prefixes
        [@rtt,@rttn,@rct]
      end
    end
  end
end
