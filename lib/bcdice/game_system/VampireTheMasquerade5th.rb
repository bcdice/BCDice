# frozen_string_literal: true

module BCDice
  module GameSystem
    class VampireTheMasquerade5th < Base
      # ゲームシステムの識別子
      ID = 'VampireTheMasquerade5th'

      # ゲームシステム名
      NAME = 'Vampire: The Masquerade 5th Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'うあんはいあさますかれえと5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定コマンド(nVMFx+x)
          注意：難易度は必要成功数を表す

          難易度指定：判定成功と失敗、Critical判定、
                     （Hungerダイスがある場合）Messy CriticalとBestial Failureチェックを行う
          例) (難易度)VMF(ダイスプール)+(Hungerダイス)
              (難易度)VMF(ダイスプール)

          難易度省略：判定失敗、Critical、（Hungerダイスがある場合）Bestial Failureチェックを行う
                      判定成功、Messy Criticalのチェックを行わない
          例) VMF(ダイスプール)+(Hungerダイス)
              VMF(ダイスプール)

          難易度0指定：全てのチェックを行わない
          例) 0VMF(ダイスプール)+(Hungerダイス)
              0VMF(ダイスプール)

      MESSAGETEXT

      DIFFICULTY_INDEX   = 1
      DICE_POOL_INDEX    = 3
      HUNGER_DICE_INDEX  = 5

      # 難易度に指定可能な特殊値
      NOT_CHECK_SUCCESS = -1 # 判定成功にかかわるチェックを行わない(判定失敗に関わるチェックは行う)

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix(['\d*VMF.*'])

      def eval_game_system_specific_command(command)
        m = /\A(\d+)?(VMF)(\d+)(\+(\d+))?/.match(command)
        unless m
          return ''
        end

        dice_pool = m[DICE_POOL_INDEX].to_i
        dice_text, success_dice, ten_dice, = make_dice_roll(dice_pool)
        result_text = "(#{dice_pool}D10"

        hunger_dice_pool = m[HUNGER_DICE_INDEX]&.to_i
        if hunger_dice_pool
          hunger_dice_text, hunger_success_dice, hunger_ten_dice, hunger_botch_dice = make_dice_roll(hunger_dice_pool)

          ten_dice += hunger_ten_dice
          success_dice += hunger_success_dice

          result_text = "#{result_text}+#{hunger_dice_pool}D10) ＞ [#{dice_text}]+[#{hunger_dice_text}] "
        else
          hunger_ten_dice = 0
          hunger_botch_dice = 0
          result_text = "#{result_text}) ＞ [#{dice_text}] "
        end

        success_dice += get_critical_success(ten_dice)

        difficulty = m[DIFFICULTY_INDEX] ? m[DIFFICULTY_INDEX].to_i : NOT_CHECK_SUCCESS

        result_text = "#{result_text} 成功数=#{success_dice}"

        if difficulty > 0
          if success_dice >= difficulty
            judgment_result = get_success_result(ten_dice >= 2, hunger_ten_dice)
          else
            judgment_result = get_fail_result(hunger_botch_dice)
          end
          result_text = "#{result_text} 難易度=#{difficulty}#{judgment_result}"
        elsif difficulty < 0
          if success_dice == 0
            judgment_result = get_fail_result(hunger_botch_dice)
          else
            judgment_result = ""
          end
          result_text = "#{result_text}#{judgment_result}"
        end

        return result_text
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

      def get_success_result(is_critical, hunger_ten_dice)
        judgment_result = "：判定成功!"
        if hunger_ten_dice > 0 && is_critical
          return "#{judgment_result} [Messy Critical]"
        elsif is_critical
          return "#{judgment_result} [Critical Win]"
        end

        return judgment_result
      end

      def get_fail_result(hunger_botch_dice)
        judgment_result = "：判定失敗!"
        if hunger_botch_dice > 0
          return "#{judgment_result} [Bestial Failure]"
        end

        return judgment_result
      end
    end
  end
end
