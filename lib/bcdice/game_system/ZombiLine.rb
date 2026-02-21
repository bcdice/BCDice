# frozen_string_literal: true

module BCDice
  module GameSystem
    class ZombiLine < Base
      # ゲームシステムの識別子
      ID = "ZombiLine"

      # ゲームシステム名
      NAME = "ゾンビライン"

      # ゲームシステム名の読みがな
      SORT_KEY = "そんひらいん"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (xZL<=y)
        　x：ダイス数(省略時は1)
        　y：成功率

        ■ 各種表
        　ストレス症状表 SST
        　食材表 IT
      TEXT

      def initialize(command)
        super(command)
        @sides_implicit_d = 10
      end

      def eval_game_system_specific_command(command)
        return check_action(command) || roll_tables(command, self.class::TABLES)
      end

      def check_action(command)
        parser = Command::Parser.new("ZL", round_type: @round_type)
                                .enable_prefix_number
                                .disable_modifier
                                .restrict_cmp_op_to(:<=)
        parsed = parser.parse(command)
        return nil unless parsed

        dice_count = parsed.prefix_number || 1
        target_num = parsed.target_number

        debug(dice_count)

        dice_list = @randomizer.roll_barabara(dice_count, 100).sort
        is_success = dice_list.any? { |i| i <= target_num }
        is_critical = dice_list.any? { |i| i <= 5 }
        is_fumble = dice_list.any? { |i| i >= 96 && i > target_num }

        if is_critical && is_fumble
          is_critical = false
          is_fumble = false
        end

        success_message =
          if is_success && is_critical
            translate("ZombiLine.success_critical")
          elsif is_success && is_fumble
            translate("ZombiLine.success_fumble")
          elsif is_success
            translate("ZombiLine.success")
          elsif is_fumble
            translate("ZombiLine.failure_fumble")
          else
            translate("ZombiLine.failure")
          end

        sequence = [
          "(#{parsed})",
          "[#{dice_list.join(',')}]",
          success_message
        ]

        Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          r.condition = is_success
          r.critical = is_critical
          r.fumble = is_fumble
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            'SST' => DiceTable::Table.from_i18n("ZombiLine.SST", locale),
            'IT' => DiceTable::RangeTable.new(
              I18n.t("ZombiLine.IT.name", locale: locale),
              '1d100',
              [
                [1..50, I18n.t("ZombiLine.IT.items.raw", locale: locale)],
                [51..80, I18n.t("ZombiLine.IT.items.suspicious", locale: locale)],
                [81..100, I18n.t("ZombiLine.IT.items.dangerous", locale: locale)]
              ]
            )
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      register_prefix('\d*ZL', TABLES.keys)
    end
  end
end
