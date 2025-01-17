# frozen_string_literal: true

module BCDice
  module GameSystem
    class NRR < Base
      # ゲームシステムの識別子
      ID = 'NRR'

      # ゲームシステム名
      NAME = 'nRR'

      # ゲームシステム名の読みがな
      SORT_KEY = 'えぬああるあある'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ▪️判定
        ・ノーマルダイス　NR8
        ・有利ダイス　NR10
        ・不利ダイス　NR6
        ・Exダイス　NR12

        ダイスの個数を指定しての判定ができます。
        例：有利ダイス2個で判定　2NR10

        ▪️判定結果とシンボル
        ⭕：成功
        ❌：失敗
        ✨：クリティカル（大成功）
        💀：ファンブル（大失敗）
        🌈：ミラクル（奇跡）
      INFO_MESSAGETEXT

      register_prefix('\d*NR(6|8|10|12)')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        roll_nr(command)
      end

      private

      def roll_nr(command)
        m = /^(\d+)?NR(6|8|10|12)$/.match(command)
        return nil unless m

        times = m[1]&.to_i || 1
        table = case m[2]
                when "6"
                  DISADVANTAGE
                when "8"
                  NORMAL
                when "10"
                  ADVANTAGE
                else
                  EXTRA
                end

        values = @randomizer.roll_barabara(times, table.size)
        result = Result.new
        text =
          if times == 1
            level = table[values[0] - 1]
            result.condition = SUCCESSES.include?(level)
            result.fumble = level == :fumble
            result.critical = CRITICALS.include?(level)

            "#{ICON[level]} #{RESULT_LABEL[level]}"
          else
            levels = values.map { |v| table[v - 1] }
            values_count = levels
                           .group_by(&:itself)
                           .transform_values(&:length)

            values_count_strs = LEVELS.map do |l|
              count = values_count.fetch(l, 0)
              next nil if count == 0

              "#{ICON[l]} #{count}"
            end

            values_count_strs.compact.join(", ")
          end

        times_str = times == 1 ? nil : times
        result.text = "(#{times_str}NR#{m[2]}) ＞ #{values.join(',')} ＞ #{text}"

        result
      end

      LEVELS = [:fumble, :failure, :success, :critical, :miracle].freeze
      SUCCESSES = [:success, :critical, :miracle].freeze
      CRITICALS = [:critical, :miracle].freeze

      DISADVANTAGE = [:fumble, :failure, :failure, :failure, :success, :success].freeze
      NORMAL = [:fumble, :failure, :failure, :failure, :success, :success, :success, :critical].freeze
      ADVANTAGE = [:fumble, :failure, :failure, :success, :success, :success, :success, :success, :critical, :critical].freeze
      EXTRA = [:fumble, :fumble, :failure, :failure, :success, :success, :critical, :critical, :critical, :critical, :miracle, :miracle].freeze

      ICON = {
        fumble: "💀",
        failure: "❌",
        success: "⭕️",
        critical: "✨",
        miracle: "🌈",
      }.freeze

      RESULT_LABEL = {
        fumble: "ファンブル（大失敗）",
        failure: "失敗",
        success: "成功",
        critical: "クリティカル（大成功）",
        miracle: "ミラクル（奇跡）",
      }.freeze
    end
  end
end
