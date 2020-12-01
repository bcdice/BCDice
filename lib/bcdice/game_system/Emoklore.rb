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
          ”(技能レベル)DA(能力値)+(ボーナスダイス)"で指定します。
          ボーナスダイスの個数は省略可能で、省略した場合0になります。
          技能レベルは1～3の数値、またはベース技能の場合bが入ります。
          ダイスの個数は技能レベルとボーナスダイスの個数により決定し、s+z個のダイスを振ります。（s=bの場合はs=1）
          判定値はs+aとなります。（s=bの場合はs=0）
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d*DM<=.*', '\d*DA\d+.*')

      CRITICAL_VALUE = 1
      FUMBLE_VALUE = 10

      # ダイスボット固有コマンドの処理を行う
      # @param [String] command コマンド
      # @return [String] ダイスボット固有コマンドの結果
      # @return [nil] 無効なコマンドだった場合
      def eval_game_system_specific_command(command)
        case command
        when /^\d*DM<=\d/
          getCheckResult(command)
        when /^\d*DA\d+(\+)?\d*/
          getCheckResultCustom(command)
        end
      end

      # 判定ダイスロール
      def execRoll(num_dice, success_threshold)
        # ダイスを振った結果を配列として取得
        values = Array.new(num_dice.to_i) { @randomizer.roll_once(10) }

        # クリティカルが出た数
        values_critical = values.count { |num| num <= CRITICAL_VALUE }
        delete_num = 1
        values_tmp = values.clone
        while delete_num <= CRITICAL_VALUE
          values_tmp.delete(delete_num)
          delete_num += 1
        end

        # 成功が出た数
        values_success = values_tmp.count { |num| num <= success_threshold }

        # ファンブルが出た数
        values_fumble = values_tmp.count { |num| num >= FUMBLE_VALUE }

        # 出た目に従って成功値計算
        success_value = 2 * values_critical + values_success - values_fumble
        return_str = ""
        if success_value < 0
          return_str = "ファンブル!"
        elsif success_value == 0
          return_str = "失敗!"
        elsif success_value == 1
          return_str = "成功!"
        elsif success_value == 2
          return_str = "ダブル!"
        elsif success_value == 3
          return_str = "トリプル!"
        elsif success_value >= 4 && success_value <= 9
          return_str = "ミラクル!"
        elsif success_value >= 10
          return_str = "カタストロフ!"
        end

        # ダイスを振った結果を返す
        return "#{values} ＞ #{success_value} ＞ #{return_str}"
      end

      # 技能判定
      # @param [String] command コマンド
      # @return [String] コマンドの結果
      def getCheckResult(command)
        num_dice = 1

        # コマンド解析
        m = /(\d*)DM<=(\d+)/i.match(command)

        unless m
          return nil
        end

        # ダイスの数は省略可能（省略した場合は1個）
        unless m[1].to_s == "" || m[1].to_s.nil?
          if m[1].to_i <= 0
            return nil
          end

          num_dice = m[1].to_i
        end

        # 判定値
        success_threshold = m[2].to_i

        # ダイスロール本体
        ret_str = execRoll(num_dice, success_threshold)

        # 結果を返す
        return "(#{num_dice}DM<=#{success_threshold}) ＞ " + ret_str
      end

      # 取得技能判定
      # @param [String] command コマンド
      # @return [String] コマンドの結果
      def getCheckResultCustom(command)
        skil_level = 0
        num_dice = 1

        # コマンド解析
        if (m = /(\d*)DA(\d+)(\+)?(\d*)/i.match(command))
          # ダイスの数は省略可能（省略した場合は1個）
          unless m[1].to_s == "" || m[1].to_i <= 0
            skil_level = m[1].to_i
            num_dice = m[1].to_i
          end

          # 判定値を計算
          success_threshold = m[2].to_i + skil_level.to_i

          # ボーナスダイス加算
          unless m[4].to_s == "" || m[4].to_i <= 0
            num_dice = num_dice.to_i + m[4].to_i
          end

          # ダイスロール本体
          ret_str = execRoll(num_dice, success_threshold)

          # 結果を返す
          return "(#{m[1]}DA#{m[2]}#{m[3]}#{m[4]}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ " + ret_str
        end
        return nil
      end
    end
  end
end
