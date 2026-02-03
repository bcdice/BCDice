# frozen_string_literal: true

module BCDice
  module GameSystem
    class Emoklore < Base
      # ゲームシステムの識別子
      ID = "Emoklore"

      # ゲームシステム名
      NAME = "エモクロアTRPG"

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = "えもくろあTRPG"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・技能値判定（xDM<=y）
          "(個数)DM<=(判定値)"で指定します。
          ダイスの個数は省略可能で、省略した場合1個になります。
          例）2DM<=5 DM<=8

        ・ダイスボーナス付き判定（xDM<=yDz / xDM<=yDt-z / xDM<=yDxz）
          末尾にDz、Dt-z、Dxzを付けることでダイス数を変更できます。
          Dz: ダイス数にzを加算
          Dt-z: ダイス数からzを減算
          Dxz: ダイス数をz倍
          例）2DM<=5D2 → 4個のダイスで判定値5
              3DM<=5Dt-1 → 2個のダイスで判定値5
              2DM<=5Dx2 → 4個のダイスで判定値5
          ※ダイス数が0以下になる場合は確定失敗

        ・技能値判定（sDAa+z)
          "(技能レベル)DA(能力値)+(ダイスボーナス)"で指定します。
          ダイスボーナスの個数は省略可能で、省略した場合0になります。
          技能レベルは1～3の数値、またはベース技能の場合"b"が入ります。
          ダイスの個数は技能レベルとダイスボーナスの個数により決定し、s+z個のダイスを振ります。（s="b"の場合はs=1）
          判定値はs+aとなります。（s="b"の場合はs=0）
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d*DM<=', '(B|\d*)DA')

      CRITICAL_VALUE = 1
      FUMBLE_VALUE = 10

      # ダイスボット固有コマンドの処理を行う
      # @param [String] command コマンド
      # @return [String] ダイスボット固有コマンドの結果
      # @return [nil] 無効なコマンドだった場合
      def eval_game_system_specific_command(command)
        case command
        when /^-?\d*DM<=-?\d+/
          roll_dm(command)
        when /^(B|\d*)DA\d+(\+)?\d*/
          roll_da(command)
        end
      end

      # 入力の正規化（表記揺れ吸収）
      # @param string [String]
      # @return [String]
      def change_text(string)
        string
          .tr('０-９', '0-9')           # 全角数字→半角
          .tr('Ａ-Ｚａ-ｚ', 'A-Za-z')   # 全角英字→半角
          .tr('＋＊／＜＝－', '+*/<=-')  # 全角記号→半角（ハイフンは末尾に）
          .gsub(/D\*(\d+)$/i, 'DX\1')   # D*2 → DX2
          .gsub(/D\+(\d+)$/i, 'D\1')    # D+2 → D2
      end

      private

      # ダイスロールの共通処理
      # @param [Integer] num_dice
      # @param [Integer] success_threshold
      # @return [Result]
      def dice_roll(num_dice, success_threshold)
        # ダイスを振った結果を配列として取得
        values = @randomizer.roll_barabara(num_dice, 10)
        critical = values.count(CRITICAL_VALUE)
        success = values.count { |num| num <= success_threshold }
        fumble = values.count(FUMBLE_VALUE)

        # 成功値
        success_value = critical + success - fumble
        result = compare_result(success_value)

        result.text = "#{values} ＞ #{success_value} ＞ #{translate('Emoklore.success_count', count: success_value)} #{result.text}"
        return result
      end

      # @param [Integer] success
      # @return [Result]
      def compare_result(success)
        if success < 0
          Result.fumble(translate("fumble"))
        elsif success == 0
          Result.failure(translate("failure"))
        elsif success == 1
          Result.success(translate("success"))
        elsif success == 2
          Result.critical(translate("Emoklore.double"))
        elsif success == 3
          Result.critical(translate("Emoklore.triple"))
        elsif success <= 9
          Result.critical(translate("Emoklore.miracle"))
        else
          Result.critical(translate("Emoklore.catastrophe"))
        end
      end

      # 技能判定
      # @param [String] command コマンド
      # @return [Result, nil] コマンドの結果
      def roll_dm(command)
        m = /^(-?\d+)?DM<=(-?\d+)(D(\d+)|DT(-?\d+)|DX(\d+))?$/.match(command)
        unless m
          return nil
        end

        base_dice = m[1]&.to_i || 1
        success_threshold = m[2].to_i
        modifier_simple_add = m[4]&.to_i  # D数字 の値（加算）
        modifier_add = m[5]&.to_i         # Dt の値（加減算）
        modifier_multiply = m[6]&.to_i    # Dx の値（乗算）
        has_modifier = m[3]

        # ダイス数を計算
        num_dice = calculate_dice_count(base_dice, modifier_simple_add, modifier_add, modifier_multiply)

        # ダイス数が0以下の場合は確定失敗
        if num_dice <= 0
          return Result.fumble("(#{command}) ＞ ダイス数が0以下 ＞ 確定失敗")
        end

        # ダイスロール本体
        result = dice_roll(num_dice, success_threshold)

        # 出力フォーマット
        if has_modifier
          result.text = "(#{command}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        else
          result.text = "(#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        end
        return result
      end

      # ダイス数を計算する
      # @param [Integer] base ベースダイス数
      # @param [Integer, nil] modifier_simple_add 単純加算修正値（D数字）
      # @param [Integer, nil] modifier_add 加減算修正値（Dt）
      # @param [Integer, nil] modifier_multiply 乗算修正値（Dx）
      # @return [Integer] 計算後のダイス数
      def calculate_dice_count(base, modifier_simple_add, modifier_add, modifier_multiply)
        if modifier_simple_add
          base + modifier_simple_add
        elsif modifier_add
          base + modifier_add
        elsif modifier_multiply
          base * modifier_multiply
        else
          base
        end
      end

      # 取得技能判定
      # @param [String] command コマンド
      # @return [Result, nil] コマンドの結果
      def roll_da(command)
        m = /^(B|\d+)?DA(\d+)(\+\d+)?$/.match(command)
        unless m
          return nil
        end

        bonus = m[3].to_i
        num_dice = (m[1] == "B" ? 1 : (m[1]&.to_i || 1)) + bonus
        success_threshold = m[1].to_i + m[2].to_i

        result = dice_roll(num_dice, success_threshold)

        result.text = "(#{command}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        return result
      end
    end
  end
end
