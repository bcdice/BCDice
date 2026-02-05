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
        ・技能値判定（xDM<=y / xDM<=yEz）
          "(個数)DM<=(判定値)"で指定します。
          ダイスの個数は省略可能で、省略した場合1個になります。
          個数や判定値には四則演算（+-*/）を使用できます。
          末尾にEzを付けるとダイス数にzを加算します。E-zで減算も可能です。
          例）2DM<=5 DM<=8 2+2DM<=5 → 4個で判定値5
              2DM<=5E2 → 4個で判定値5 / 3DM<=5E-1 → 2個で判定値5
          ※ダイス数が0以下になる場合は確定失敗

        ・技能値判定（sDAa+z)
          "(技能レベル)DA(能力値)+(ダイスボーナス)"で指定します。
          ダイスボーナスの個数は省略可能で、省略した場合0になります。
          技能レベルは1～3の数値、またはベース技能の場合"b"が入ります。
          ダイスの個数は技能レベルとダイスボーナスの個数により決定し、s+z個のダイスを振ります。（s="b"の場合はs=1）
          判定値はs+aとなります。（s="b"の場合はs=0）
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('[-+*/\d()]*DM<=', '(B|\d*)DA')

      CRITICAL_VALUE = 1
      FUMBLE_VALUE = 10

      # ダイスボット固有コマンドの処理を行う
      # @param [String] command コマンド
      # @return [String] ダイスボット固有コマンドの結果
      # @return [nil] 無効なコマンドだった場合
      def eval_game_system_specific_command(command)
        case command
        when %r{^[-+*/\d()]*DM<=[-+*/\d()]+}
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
          .tr('０-９', '0-9') # 全角数字→半角
          .tr('Ａ-Ｚａ-ｚ', 'A-Za-z') # 全角英字→半角
          .tr('＋＊／＜＝－', '+*/<=-') # 全角記号→半角（ハイフンは末尾に）
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
        m = %r{^([-+*/\d()]+)?DM<=([-+*/\d()]+)(E(-?\d+))?$}.match(command)
        unless m
          return nil
        end

        base_dice_str = m[1]
        threshold_str = m[2]
        modifier = m[4]&.to_i

        base_dice = base_dice_str ? Arithmetic.eval(base_dice_str, RoundType::FLOOR) : 1
        success_threshold = Arithmetic.eval(threshold_str, RoundType::FLOOR)
        return nil unless base_dice && success_threshold

        num_dice = modifier ? base_dice + modifier : base_dice

        # ダイス数が0以下の場合は確定失敗
        if num_dice <= 0
          return Result.fumble("(#{command}) ＞ ダイス数が0以下 ＞ 確定失敗")
        end

        # ダイスロール本体
        result = dice_roll(num_dice, success_threshold)

        # 出力フォーマット：算術式やダイスボーナスがある場合は展開形を表示
        has_arithmetic = base_dice_str&.match?(%r{[-+*/()]}) || threshold_str.match?(%r{[-+*/()]})
        if modifier || has_arithmetic
          result.text = "(#{command}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        else
          result.text = "(#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        end
        return result
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

        if num_dice <= 0
          return Result.fumble("(#{command}) ＞ ダイス数が0以下 ＞ 確定失敗")
        end

        result = dice_roll(num_dice, success_threshold)

        result.text = "(#{command}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        return result
      end
    end
  end
end
