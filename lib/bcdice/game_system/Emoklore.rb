# frozen_string_literal: true

module BCDice
  module GameSystem
    class Emoklore < Base
      # ゲームシステムの識別子
      ID = "Emoklore"

      # ゲームシステム名
      NAME = "エモクロア"

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = "えもくろあ"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・技能値判定（xDM<=y）
          "(個数)DM<=(判定値)"で指定します。
          ダイスの個数は省略可能で、省略した場合1個になります。
          例）2DM<=5 DM<=8
        ・技能値判定（sDAa+z)
          "(技能レベル)DA(能力値)+(ボーナスダイス)"で指定します。
          ボーナスダイスの個数は省略可能で、省略した場合0になります。
          技能レベルは1～3の数値、またはベース技能の場合"b"が入ります。
          ダイスの個数は技能レベルとボーナスダイスの個数により決定し、s+z個のダイスを振ります。（s="b"の場合はs=1）
          判定値はs+aとなります。（s="b"の場合はs=0）
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d*DM<=\d+', '\d*DA\d+')

      CRITICAL_VALUE = 1
      FUMBLE_VALUE = 10

      # ダイスボット固有コマンドの処理を行う
      # @param [String] command コマンド
      # @return [String] ダイスボット固有コマンドの結果
      # @return [nil] 無効なコマンドだった場合
      def eval_game_system_specific_command(command)
        case command
        when /^\d*DM<=\d/
          roll_dm(command)
        when /^\d*DA\d+(\+)?\d*/
          roll_da(command)
        end
      end

      private

      # ダイスロールの共通処理
      # @param [Integer] num_dice
      # @param [Integer] success_threshold
      # @return [String]
      def dice_roll(num_dice, success_threshold)
        # ダイスを振った結果を配列として取得
        values = @randomizer.roll_barabara(num_dice, 10)
        values_without_critical = values.reject { |num| num <= CRITICAL_VALUE }

        critical = values.size - values_without_critical.size
        success = values_without_critical.count { |num| num <= success_threshold }
        fumble = values_without_critical.count { |num| num >= FUMBLE_VALUE }

        # 成功値
        success_value = 2 * critical + success - fumble

        "#{values} ＞ #{success_value} ＞ #{result_text(success_value)}"
      end

      # @param [Integer] success
      # @return [String]
      def result_text(success)
        if success < 0
          "ファンブル!"
        elsif success == 0
          "失敗!"
        elsif success == 1
          "成功!"
        elsif success == 2
          "ダブル!"
        elsif success == 3
          "トリプル!"
        elsif success <= 9
          "ミラクル!"
        else
          "カタストロフ!"
        end
      end

      # 技能判定
      # @param [String] command コマンド
      # @return [String, nil] コマンドの結果
      def roll_dm(command)
        m = /^(\d+)?DM<=(\d+)$/.match(command)
        unless m
          return nil
        end

        num_dice = m[1]&.to_i || 1
        success_threshold = m[2].to_i
        if num_dice <= 0
          return nil
        end

        # ダイスロール本体
        ret_str = dice_roll(num_dice, success_threshold)

        return "(#{num_dice}DM<=#{success_threshold}) ＞ #{ret_str}"
      end

      # 取得技能判定
      # @param [String] command コマンド
      # @return [String, nil] コマンドの結果
      def roll_da(command)
        m = /^(\d+)?DA(\d+)(\+\d+)?$/.match(command)
        unless m
          return nil
        end

        skil_level = m[1].to_i # 未指定は0
        bonus = m[3].to_i
        num_dice = (m[1]&.to_i || 1) + bonus
        success_threshold = m[2].to_i + skil_level

        ret_str = dice_roll(num_dice, success_threshold)
        "(#{command}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ #{ret_str}"
      end
    end
  end
end
