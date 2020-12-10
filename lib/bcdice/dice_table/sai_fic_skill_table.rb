# frozen_string_literal: true

require "bcdice/dice_table/sai_fic_skill_table/category"
require "bcdice/dice_table/sai_fic_skill_table/skill"

module BCDice
  module DiceTable
    class SaiFicSkillTable
      # @param key    [String]
      # @param locale [Symbol]
      # @param rtt    [String] RTTに相当するコマンド
      # @param rct    [String] RCTに相当するコマンド
      # @param rttn   [Array]  RTT1～6に相当するコマンドの配列
      # @return [SaiFicSkillTable]
      def self.from_i18n(key, locale, rtt: nil, rct: nil, rttn: nil)
        table = I18n.t(key, locale: locale, raise: true)
        items = table[:items]
        table = table.filter { |k, _v| [:rtt_format, :rttn_format, :rct_format, :s_format].include?(k) }
        new(items, **table, rtt: rtt, rct: rct, rttn: rttn)
      end

      DEFAULT_RTT = "ランダム特技表(%<category_dice>d,%<row_dice>d) ＞ %<text>s"
      DEFAULT_RCT = "ランダム分野表(%<category_dice>d) ＞ %<category_name>s"
      DEFAULT_RTTN = "%<category_name>s分野ランダム特技表(%<row_dice>d) ＞ %<text>s"
      DEFAULT_S = "《%<skill_name>s／%<category_name>s%<row_dice>d》"

      # サイコロ・フィクション用ダイステーブルを初期化する。
      # 既存の実装の互換性維持とルールブックの記載に準拠するために、コマンドと書式文字列を指定できる。
      # @param items [Array] 特技リスト
      # @param rtt          [String] RTTに相当するコマンド
      # @param rct          [String] RCTに相当するコマンド
      # @param rttn         [Array]  RTT1～6に相当するコマンドの配列
      # @param rtt_format   [String] RTTコマンドの出力用の書式文字列
      # @param rct_format   [String] RCTコマンドの出力用の書式文字列
      # @param rttn_format  [String] RTTNコマンドの出力用の書式文字列
      # @param s_format     [String] Skill#to_s出力用の書式文字列
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
      attr_reader :categories

      # コマンドを解釈し、結果を取得する
      # return [String]
      def roll_command(randomizer, command)
        c = command
        if ["RTT", @rtt].include?(c)
          format_skill(@rtt_format, roll_skill(randomizer))
        elsif ["RCT", @rct].include?(c)
          cat = roll_category(randomizer)
          format(@rct_format, category_dice: cat.dice, category_name: cat.name)
        elsif (index = RTTN.index(c)) || (index = @rttn.index(c))
          format_skill(@rttn_format, @categories[index].roll(randomizer))
        end
      end

      # 1D6を振り、ランダムで分野を決定する
      # @return [SaiFicSkillTable::Category]
      def roll_category(randomizer)
        @categories[randomizer.roll_once(6) - 1]
      end

      # 1D6と2D6を振り、ランダムで特技を決定する
      # @return [SaiFicSkillTable::Skill]
      def roll_skill(randomizer)
        roll_category(randomizer).roll(randomizer)
      end

      def prefixes
        ([/RTT[1-6]?/i, "RCT", @rtt, @rct] + @rttn).compact
      end

      private

      def format_skill(format_string, skill)
        format(format_string, category_dice: skill.category_dice, row_dice: skill.row_dice, category_name: skill.category_name, skill_name: skill.name, text: skill.to_s)
      end
    end
  end
end
