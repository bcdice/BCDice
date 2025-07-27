# frozen_string_literal: true

module BCDice
  module GameSystem
    class Emoklore_Korean < Emoklore
      # ゲームシステムの識別子
      ID = "Emoklore:Korean"

      # ゲームシステム名
      NAME = "에모크로아TRPG"

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = "国際化:Korean:에모크로아TRPG"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・기능치 판정（xDM<=y）
          "(개수)DM<=(판정치)"로 판정합니다.
          주사위의 개수는 생략 가능하며, 생략 시 1개로 설정됩니다.
          ex）2DM<=5 DM<=8

        ・기능치 판정（sDAa+z)
          "(기능 레벨)DA(능력치)+(주사위 보너스)"로 판정합니다.
          주사위 보너스의 개수는 생략 가능하며, 생략 시 0개로 설정됩니다.
          기능 레벨에는 1~3의 수치를 입력합니다. 기본 기능으로 판정하려면 기능 레벨에"b"를 입력하세요.
          주사위 개수는 기능 레벨과 주사위 보너스 개수에 따라 결정되며, s+z개의 주사위를 굴립니다. (s="b"인 경우 s=1)  
          판정치는 s+a 입니다.（s="b"인 경우에는 s=0）
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d*DM<=', '(B|\d*)DA')

      CRITICAL_VALUE = 1
      FUMBLE_VALUE = 10

      # i18n/Emoklore/ko_kr.yml 
      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      # ダイスボット固有コマンドの処理を行う
      # @param [String] command コマンド
      # @return [String] ダイスボット固有コマンドの結果
      # @return [nil] 無効なコマンドだった場合
      def eval_game_system_specific_command(command)
        case command
        when /^\d*DM<=\d/
          roll_dm(command)
        when /^(B|\d*)DA\d+(\+)?\d*/
          roll_da(command)
        end
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
        result = dice_roll(num_dice, success_threshold)

        result.text = "(#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
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

        result = dice_roll(num_dice, success_threshold)

        result.text = "(#{command}) ＞ (#{num_dice}DM<=#{success_threshold}) ＞ #{result.text}"
        return result
      end
    end
  end
end
