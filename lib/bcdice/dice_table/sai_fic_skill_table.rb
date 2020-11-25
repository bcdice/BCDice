module BCDice
  module DiceTable
    class SaiFicSkillTable
      def initialize(items, rtt: nil, rct: nil, rttn: nil, rtt_format: "ランダム指定特技表(%<category_dice>d,%<row_dice>d) ＞ %<text>s", rct_format: "ランダム分野(%<dice>d) ＞ %<category>s", rttn_format: "%<category_name>s分野ランダム指定特技表(%<row_dice>d) ＞ %<text>s")
        @items = items
        @rtt = rtt
        @rct = rct
        @rttn = rttn.to_a
        @rtt_format = rtt_format
        @rct_format = rct_format
        @rttn_format = rttn_format
      end

      RTTN = ["RTT1", "RTT2", "RTT3", "RTT4", "RTT5", "RTT6"].freeze
      attr_reader :rtt_format
      attr_reader :rct_format
      attr_reader :rttn_format
      attr_reader :items

      def roll_command(randomizer, command)
        c = command.upcase
        if ["RTT", @rtt].include?(c)
          roll(randomizer)
        elsif ["RCT", @rct].include?(c)
          cat, dice = roll_category(randomizer)
          format(rct_format, dice: dice, category: cat)
        elsif (index = RTTN.index(c)) || (index = @rttn.index(c))
          roll(randomizer, index + 1)
        end
      end

      def roll(randomizer, category_dice = nil)
        skill = roll_skill(randomizer, category_dice)
        if category_dice
          skill.result_rttn
        else
          skill.result_rtt
        end
      end

      def roll_skill(randomizer, category_dice = nil)
        category_dice ||= randomizer.roll_once(6)
        row_dice = randomizer.roll_sum(2, 6)
        return SaiFicSkill.new(self, category_dice, row_dice)
      end

      def roll_category(randomizer)
        category_dice = randomizer.roll_once(6)
        category = @items[category_dice - 1][0]
        return category, category_dice
      end

      def prefixes
        ([/RTT[1-6]?/i, "RCT", @rtt, @rct] + @rttn).compact
      end
    end
  end
end
