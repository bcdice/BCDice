# frozen_string_literal: true

module BCDice
  module GameSystem
    class GoblinSlayer < Base
      # ゲームシステムの識別子
      ID = 'GoblinSlayer'

      # ゲームシステム名
      NAME = 'ゴブリンスレイヤーTRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'こふりんすれいやあTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定　GS(x)@c#f>=y
        　2d6の判定を行い、達成値を出力します。
        　xは基準値、yは目標値、cは大成功の下限、fは大失敗の上限です。いずれも省略可能です。
        　cが未指定の場合には c=12 、fが未指定の場合には f=2 となります。
        　yが設定されている場合、大成功/成功/失敗/大失敗を自動判定します。
        　例）GS>=12　GS>10　GS(10)>14　GS+10>=15　GS10>=15　GS(10)　GS+10　GS10　GS
        　　　GS@10　GS@10#3　GS#3@10

        ・祈念　MCPI(n)$m
        　祈念を行います。
        　nは【幸運】などによるボーナスです。この値は省略可能です。
        　mは因果点の現在値です。
        　因果点の現在値を使用して祈念を行い、成功/失敗を自動判定します。
        　例）MCPI$3　MCPI(1)$4　MCPI+2$5　MCPI2$6

        ・命中判定の効力値によるボーナス　DB(n)
        　ダメージ効力表による威力へのボーナスを自動で求めます。
        　nは命中判定の効力値です。
        　例）DB(15)　DB12

        ※上記コマンドの計算内で割り算を行った場合、小数点以下は切り上げされます。
        　ただしダイス出目を割り算した場合、小数点以下は切り捨てされます。
        　例）入力：GS(8+3/2)　実行結果：(GS10) ＞ 10 + 3[1,2] ＞ 13
        　　　入力：2d6/2    　実行結果：(2D6/2) ＞ 3[1,2]/2 ＞ 1

        ※MCPIでは、シークレットダイスを使用できません。
      MESSAGETEXT

      # 因果点は共有リソースなのでMCPIはシークレットダイスを無効化
      register_prefix('GS', '^MCPI.*$', 'DB')

      def initialize(command)
        super(command)
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        case command
        when /^GS/i
          return getCheckResult(command)
        when /^MCPI/i
          return murmurChantPrayInvoke(command)
        when /^DB/i
          return damageBonus(command)
        else
          return nil
        end
      end

      def getCheckResult(command)
        m = /^GS([-+]?\d+)?(?:(?:([@#])([-+]?\d+))(?:([@#])([-+]?\d+))?)?(?:(>=?)(\d+))?$/i.match(command)
        unless m
          return nil
        end

        basis = m[1].to_i # 基準値
        target = m[7].to_i
        cmp_op = m[6]
        without_compare = cmp_op.nil?

        option1 = m[2]
        option1_value = m[3]
        option2 = m[4]
        option2_param = m[5]

        if option1 && option1 == option2
          return nil
        end

        threshold_critical, threshold_fumble = calc_threshold(option1, option1_value, option2, option2_param)

        dice_list = @randomizer.roll_barabara(2, 6)
        total = dice_list.sum()
        diceText = dice_list.join(",")

        achievement = basis + total # 達成値

        fumble = total <= threshold_fumble
        critical = total >= threshold_critical

        result = " ＞ #{resultStr(achievement, target, cmp_op, fumble, critical)}"
        if without_compare && !fumble && !critical
          result = ""
        end
        basis_str = basis == 0 ? "" : "#{basis} + "

        return "(#{command}) ＞ #{basis_str}#{total}[#{diceText}] ＞ #{achievement}#{result}"
      end

      CRITICAL = 12
      FUMBLE = 2

      def calc_threshold(option1, option1_value, _option2, option2_value)
        critical, fumble = option1 == "@" ? [option1_value, option2_value] : [option2_value, option1_value]

        return [critical&.to_i || CRITICAL, fumble&.to_i || FUMBLE]
      end

      def murmurChantPrayInvoke(command)
        m = /^MCPI(\+?\d+)?\$(\d+)$/i.match(command)
        unless m
          return nil
        end

        luck = m[1].to_i # 幸運
        volition = m[2].to_i # 因果点
        if volition >= 12
          return "因果点が12点以上の場合、因果点は使用できません。"
        end

        dice_list = @randomizer.roll_barabara(2, 6)
        total = dice_list.sum()
        diceText = dice_list.join(",")

        achievement = total + luck

        result = " ＞ #{resultStr(achievement, volition, '>=', false, false)}"
        luck_str = luck == 0 ? "" : "+#{luck}"

        return "祈念(2d6#{luck_str}) ＞ #{total}[#{diceText}]#{luck_str} ＞ #{achievement}#{result}, 因果点：#{volition}点 → #{volition + 1}点"
      end

      def damageBonus(command)
        m = /^DB(\d+)$/i.match(command)
        unless m
          return nil
        end

        num = m[1].to_i
        fmt = "命中判定の効力値によるボーナス ＞ "

        if num < 15
          return fmt + "なし"
        end

        times =
          if num >= 40
            5
          elsif num >= 30
            4
          elsif num >= 25
            3
          elsif num >= 20
            2
          else
            1
          end

        dice_list = @randomizer.roll_barabara(times, 6)
        total = dice_list.sum()
        diceText = dice_list.join(",")

        return fmt + "#{total}[#{diceText}] ＞ #{total}"
      end

      # 判定結果の文字列を返す
      # @param [Integer] achievement 達成値
      # @param [Integer] target 目標値
      # @param [String] cmp_op 達成値と目標値を比較する比較演算子
      # @param [Boolean] fumble ファンブルかどうか
      # @param [Boolean] critical クリティカルかどうか
      # @return [String]
      def resultStr(achievement, target, cmp_op, fumble, critical)
        return '大失敗' if fumble
        return '大成功' if critical
        if cmp_op == ">="
          return achievement >= target ? "成功" : "失敗"
        else
          return achievement > target ? "成功" : "失敗"
        end
      end
    end
  end
end
