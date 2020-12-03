# frozen_string_literal: true

module BCDice
  module DiceTable
    class SaiFicSkillTable
      DEFAULT_RTT = "特技表(%<category_dice>d,%<row_dice>d) ＞ %<text>s"
      DEFAULT_RCT = "特技分野表(%<category_dice>d) ＞ %<category_name>s"
      DEFAULT_RTTN = "%<category_name>s分野特技表(%<row_dice>d) ＞ %<text>s"
      DEFAULT_S = "《%<skill_name>s/%<category_name>s%<row_dice>d》"

      def initialize(items, rtt: nil, rct: nil, rttn: nil, rtt_format: DEFAULT_RTT, rct_format: DEFAULT_RCT, rttn_format: DEFAULT_RTTN, s_format: DEFAULT_S)
        @categories = items.map.with_index do |(name, skills), index|
          SaiFicSkillTable::Category.new(name, skills, index + 1, s_format)
        end
        @rtt = rtt
        @rct = rct
        @rttn = rttn.to_a
        @rtt_format = rtt_format
        @rct_format = rct_format
        @rttn_format = rttn_format
      end

      RTTN = ["RTT1", "RTT2", "RTT3", "RTT4", "RTT5", "RTT6"].freeze
      attr_reader :items

      def roll_command(randomizer, command)
        c = command.upcase
        if ["RTT", @rtt].include?(c)
          roll_skill(randomizer).to_s(@rtt_format)
        elsif ["RCT", @rct].include?(c)
          cat = roll_category(randomizer)
          format(@rct_format, category_dice: cat.dice, category_name: cat.name)
        elsif (index = RTTN.index(c)) || (index = @rttn.index(c))
          roll_skill(randomizer, index + 1).to_s(@rttn_format)
        end
      end

      def roll_skill(randomizer, category_dice = nil)
        cat = category_dice ? @categories[category_dice - 1] : roll_category(randomizer)
        return cat.roll(randomizer)
      end

      def roll_category(randomizer)
        @categories[randomizer.roll_once(6) - 1]
      end

      def prefixes
        ([/RTT[1-6]?/i, "RCT", @rtt, @rct] + @rttn).compact
      end
    end
  end
end
