# frozen_string_literal: true

require "bcdice/dice_table/sai_fic_skill_table/category.rb"
require "bcdice/dice_table/sai_fic_skill_table/skill.rb"

module BCDice
  module DiceTable
    class SaiFicSkillTable
      DEFAULT_RTT = "ランダム特技(%<category_dice>d,%<row_dice>d) ＞ %<text>s"
      DEFAULT_RCT = "ランダム分野(%<category_dice>d) ＞ %<category_name>s"
      DEFAULT_RTTN = "%<category_name>s分野ランダム特技(%<row_dice>d) ＞ %<text>s"
      DEFAULT_S = "《%<skill_name>s／%<category_name>s%<row_dice>d》"

      def initialize(items, rtt: nil, rct: nil, rttn: nil, rtt_format: DEFAULT_RTT, rct_format: DEFAULT_RCT, rttn_format: DEFAULT_RTTN, s_format: DEFAULT_S)
        @categories = items.map.with_index(1) do |(name, skills), index|
          SaiFicSkillTable::Category.new(name, skills, index, s_format)
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
        c = command
        if ["RTT", @rtt].include?(c)
          format_skill(@rtt_format, roll_category(randomizer).roll(randomizer))
        elsif ["RCT", @rct].include?(c)
          cat = roll_category(randomizer)
          format(@rct_format, category_dice: cat.dice, category_name: cat.name)
        elsif (index = RTTN.index(c)) || (index = @rttn.index(c))
          format_skill(@rttn_format, @categories[index].roll(randomizer))
        end
      end

      def roll_category(randomizer)
        @categories[randomizer.roll_once(6) - 1]
      end

      def prefixes
        ([/RTT[1-6]?/i, "RCT", @rtt, @rct] + @rttn).compact
      end

      private

      def format_skill(format_string, skill)
        format(format_string, category_dice: skill.category_dice, row_dice: skill.row_dice, category_name: skill.category_name, skill_name: skill.skill_name, text: skill.to_s)
      end
    end
  end
end
