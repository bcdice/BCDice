# frozen_string_literal: true

module BCDice
  module GameSystem
    class HunterTheReckoning5th < Base
      # ゲームシステムの識別子
      ID = 'HunterTheReckoning5th'

      # ゲームシステム名
      NAME = 'Hunter: The Reckoning 5th Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はんあたされこにんく5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定コマンド(nHRFx+x)
          注意：難易度は必要成功数を表す

          難易度指定：成功数のカウント、判定成功と失敗、Critical処理、Critical Win、Total Failureのチェックを行う
                     （Desperationダイスがある場合）OverreachとDespairの発生チェックを行う
          例) (難易度)HRF(通常ダイス)+(Desperationダイス)
              (難易度)HRF(通常ダイス)

          難易度省略：成功数のカウント、判定失敗、Critical処理、Total Failure、（Desperationダイスがある場合）Despairチェックを行う
                      判定成功、Overreachのチェックを行わない
                      Critical Win、（Desperationダイスがある場合）Despair、Overreachのヒントを出力
          例) HRF(通常ダイス)+(Desperationダイス)
              HRF(通常ダイス)

          難易度0指定：全てのチェックを行わない
          例) 0HRF(通常ダイス)+(Desperationダイス)
              0HRF(通常ダイス)

      MESSAGETEXT

      DIFFICULTY_INDEX   = 1
      DICE_POOL_INDEX    = 3
      DESPERATION_DICE_INDEX = 5

      # 難易度に指定可能な特殊値
      NOT_CHECK_SUCCESS = -1 # 判定成功にかかわるチェックを行わない(判定失敗に関わるチェックは行う)

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d*HRF')

      def eval_game_system_specific_command(command)
        m = /\A(\d+)?(HRF)(\d+)(\+(\d+))?$/.match(command)
        unless m
          return ''
        end

        dice_pool = m[DICE_POOL_INDEX].to_i
        dice_text, success_dice, ten_dice, = make_dice_roll(dice_pool)
        result_text = "(#{dice_pool}D10"

        desperaton_dice_pool = m[DESPERATION_DICE_INDEX]&.to_i
        if desperaton_dice_pool
          if desperaton_dice_pool > 5
            return "Desperationダイス指定は5ダイスが最大です。"
          end

          desperaton_dice_text, desperaton_success_dice, desperaton_ten_dice, desperaton_botch_dice = make_dice_roll(desperaton_dice_pool)

          ten_dice += desperaton_ten_dice
          success_dice += desperaton_success_dice

          result_text = "#{result_text}+#{desperaton_dice_pool}D10) ＞ [#{dice_text}]+[#{desperaton_dice_text}] "
        else
          desperaton_ten_dice = 0
          desperaton_botch_dice = 0
          result_text = "#{result_text}) ＞ [#{dice_text}] "
        end

        success_dice += get_critical_success(ten_dice)

        difficulty = m[DIFFICULTY_INDEX] ? m[DIFFICULTY_INDEX].to_i : NOT_CHECK_SUCCESS

        return get_roll_result(result_text, success_dice, ten_dice, desperaton_ten_dice, desperaton_botch_dice, difficulty)
      end

      private

      def get_roll_result(result_text, success_dice, ten_dice, _desperaton_ten_dice, desperaton_botch_dice, difficulty)
        result_text = "#{result_text} 成功数=#{success_dice}"
        is_critical = ten_dice >= 2
        desperation_result = ""

        if difficulty > 0
          result_text = "#{result_text} 難易度=#{difficulty}"

          if success_dice >= difficulty
            result_text = "#{result_text} 差分=#{success_dice - difficulty}"

            if desperaton_botch_dice > 0
              desperation_result = " [Overreach or Despair?]"
            end

            if is_critical
              return Result.critical("#{result_text}：判定成功! [Critical Win]#{desperation_result}")
            else
              return Result.success("#{result_text}：判定成功!#{desperation_result}")
            end

          else
            if desperaton_botch_dice > 0
              return Result.fumble("#{result_text}：判定失敗! [Despair]")
            end
            if success_dice == 0
              return Result.fumble("#{result_text}：判定失敗! [Total Failure]")
            end

            return Result.failure("#{result_text}：判定失敗!")
          end
        elsif difficulty < 0
          if success_dice == 0
            if desperaton_botch_dice > 0
              return Result.fumble("#{result_text}：判定失敗! [Despair]")
            end

            return Result.fumble("#{result_text}：判定失敗! [Total Failure]")
          else
            if desperaton_botch_dice > 0
              result_text = "#{result_text}\n　判定失敗なら [Despair]"
              desperation_result = " [Overreach or Despair?]"
            end

            if is_critical
              result_text = "#{result_text}\n　判定成功なら [Critical Win]"
            elsif desperaton_botch_dice > 0
              result_text = "#{result_text}\n　判定成功なら"
            end

            return "#{result_text}#{desperation_result}"
          end
        end

        # 難易度0指定(=全ての判定チェックを行わない)
        return result_text.to_s
      end

      def get_critical_success(ten_dice)
        # 10の目が2個毎に追加2成功
        return ((ten_dice / 2) * 2)
      end

      def make_dice_roll(dice_pool)
        dice_list = @randomizer.roll_barabara(dice_pool, 10)

        dice_text = dice_list.join(',')
        success_dice = dice_list.count { |x| x >= 6 }
        ten_dice = dice_list.count(10)
        botch_dice = dice_list.count(1)

        return dice_text, success_dice, ten_dice, botch_dice
      end
    end
  end
end
