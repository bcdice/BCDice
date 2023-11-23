# frozen_string_literal: true

module BCDice
  module GameSystem
    class WerewolfTheApocalypse5th < Base
      # ゲームシステムの識別子
      ID = 'WerewolfTheApocalypse5th'

      # ゲームシステム名
      NAME = 'Werewolf: The Apocalypse 5th Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わあうふるしあほかりふす5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定コマンド(nWAFx+x または nWAIxRx)
          WAFコマンドはRageダイスとダイスプールを個別に指定する。
          WAIコマンドはRageダイスをダイスプールの内数として指定する。

            例：難易度2、9ダイスプールでRageダイス3個の場合、それぞれ以下のようなコマンドとなる。
            2WAF6+3
            2WAI9R3

          難易度指定：成功数のカウント、判定成功と失敗、（Rageダイスがある場合）Brutal outcome、Critical処理、Total Failure、Critical Winのチェックを行う
          例) (難易度)WAF(通常ダイス)+(Rageダイス)
              (難易度)WAF(通常ダイス)
              (難易度)WAI(通常ダイス)R(Rageダイス)
              (難易度)WAI(通常ダイス)

          難易度省略：成功数のカウント、判定失敗、（Rageダイスがある場合）Brutal outcome、Critical処理、Total Failureのチェックを行う
                      判定成功チェックを行わない
                      Critical Winのヒントを出力
          例) WAF(通常ダイス)+(Rageダイス)
              WAF(通常ダイス)
              WAI(通常ダイス)R(Rageダイス)
              WAI(通常ダイス)

          難易度0指定：Critical処理と成功数のカウントを行い、全てのチェックを行わない
          例) 0WAF(通常ダイス)+(Rageダイス)
              0WAF(通常ダイス)
              0WAI(通常ダイス)+(Rageダイス)
              0WAI(通常ダイス)

      MESSAGETEXT

      DIFFICULTY_INDEX                          = 1
      DICE_POOL_RAGE_DICE_NO_INCLUDED_INDEX     = 5
      RAGE_DICE_NO_INCLUDED_INDEX               = 7
      COMMAND_RAGE_DICE_INCLUDED_INDEX          = 9
      DICE_POOL_RAGE_DICE_INCLUDED_INDEX        = 10
      RAGE_DICE_INCLUDED_INDEX                  = 12

      # 難易度に指定可能な特殊値
      NOT_CHECK_SUCCESS = -1 # 判定成功にかかわるチェックを行わない(判定失敗に関わるチェックは行う)

      register_prefix('\d*(WAF|(WAI\d*(R\d?)?))')

      def eval_game_system_specific_command(command)
        m = /\A(\d+)?(((WAF)(\d+)(\+(\d+))?)|((WAI)(\d+)(R(\d+))?))$/.match(command)
        unless m
          return ''
        end

        dice_pool, rage_dice_pool = get_dice_pools(m)
        if dice_pool < 0
          return "ダイスプールより多いRageダイス指定はできません。"
        end
        if rage_dice_pool && rage_dice_pool > 5
          return "5を超えるRageダイス指定はできません。"
        end

        dice_text, success_dice, ten_dice, = make_dice_roll(dice_pool)
        result_text = "(#{dice_pool}D10"

        if rage_dice_pool
          rage_dice_text, rage_success_dice, rage_ten_dice, brutal_result_dice = make_dice_roll(rage_dice_pool)

          brutal_outcome = brutal_result_dice / 2
          ten_dice += rage_ten_dice
          success_dice += rage_success_dice

          result_text = "#{result_text}+#{rage_dice_pool}D10) ＞ [#{dice_text}]+[#{rage_dice_text}] "
        else
          rage_ten_dice = 0
          brutal_outcome = 0
          result_text = "#{result_text}) ＞ [#{dice_text}] "
        end

        success_dice += get_critical_success(ten_dice)

        difficulty = m[DIFFICULTY_INDEX] ? m[DIFFICULTY_INDEX].to_i : NOT_CHECK_SUCCESS

        return get_roll_result(result_text, success_dice, ten_dice, rage_ten_dice, brutal_outcome, difficulty)
      end

      private

      def get_dice_pools(m)
        rage_dice_included_command = m[COMMAND_RAGE_DICE_INCLUDED_INDEX]
        if rage_dice_included_command && rage_dice_included_command == "WAI"
          # Rage Diceを内数処理するの場合
          rage_dice_pool = m[RAGE_DICE_INCLUDED_INDEX]&.to_i
          dice_pool = m[DICE_POOL_RAGE_DICE_INCLUDED_INDEX].to_i - (rage_dice_pool || 0)
        else
          # Rage DiceがPLによる内数指定の場合
          rage_dice_pool = m[RAGE_DICE_NO_INCLUDED_INDEX]&.to_i
          dice_pool = m[DICE_POOL_RAGE_DICE_NO_INCLUDED_INDEX].to_i
        end
        return dice_pool, rage_dice_pool
      end

      def get_roll_result(result_text, success_dice, ten_dice, _rage_ten_dice, brutal_outcome, difficulty)
        is_critical = ten_dice >= 2

        if brutal_outcome > 0 && difficulty != 0
          success_dice += 4
          result_text = "#{result_text} [Brutal outcome] 自動失敗、または 成功数=#{success_dice}"
        else
          result_text = "#{result_text} 成功数=#{success_dice}"
        end

        if difficulty > 0
          result_text = "#{result_text} 難易度=#{difficulty}"
          if success_dice >= difficulty
            result_text = "#{result_text} 差分=#{success_dice - difficulty}"

            if is_critical
              result_data = Result.critical("#{result_text}：判定成功! [Critical Win]")
              return brutal_outcome > 0 ? result_data.text : result_data
            end
            result_data = Result.success("#{result_text}：判定成功!")
            return brutal_outcome > 0 ? result_data.text : result_data
          else
            if success_dice == 0
              return Result.fumble("#{result_text}：判定失敗! [Total Failure]")
            else
              return Result.failure("#{result_text}：判定失敗!")
            end
          end
        elsif difficulty < 0
          if success_dice == 0
            return Result.fumble("#{result_text}：判定失敗! [Total Failure]")
          else
            if is_critical
              result_text = "#{result_text}\n　判定成功なら [Critical Win]"
            end
            return result_text.to_s
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
        brutal_result_dice = dice_list.count(1) + dice_list.count(2)

        return dice_text, success_dice, ten_dice, brutal_result_dice
      end
    end
  end
end
