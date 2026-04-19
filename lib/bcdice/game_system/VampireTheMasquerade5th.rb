# frozen_string_literal: true

module BCDice
  module GameSystem
    class VampireTheMasquerade5th < Base
      # ゲームシステムの識別子
      ID = 'VampireTheMasquerade5th'

      # ゲームシステム名
      NAME = 'ヴァンパイア：ザ・マスカレード第５版'

      # ゲームシステム名の読みがな
      SORT_KEY = 'うあんはいあさますかれえと5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定コマンド(nVMFx+x または nVMIxHx)
          VMFコマンドはハンガーダイスとダイスプールを個別に指定する。
          VMIコマンドはハンガーダイスをダイスプールの内数として指定する。

            例：難易度2、9ダイスプールでハンガーダイス3個の場合、それぞれ以下のようなコマンドとなる。
            2VMF6+3
            2VMI9H3

          難易度指定：達成数のカウント、判定成功と失敗、クリティカル処理、クリティカル成功、完全失敗のチェックを行う
                     （ハンガーダイスがある場合）凄惨なるクリティカルと獣の過ちチェックを行う
          例) (難易度)VMF(通常ダイス)+(ハンガーダイス)
              (難易度)VMF(通常ダイス)
              (難易度)VMI(通常ダイス)H(ハンガーダイス)
              (難易度)VMI(通常ダイス)

          難易度省略：達成数のカウント、判定失敗、クリティカル処理、完全失敗、（ハンガーダイスがある場合）獣の過ちチェックを行う
                      判定成功、凄惨なるクリティカルのチェックを行わない
                      クリティカル成功、（ハンガーダイスがある場合）獣の過ち、凄惨なるクリティカルのヒントを出力
          例) VMF(通常ダイス)+(ハンガーダイス)
              VMF(通常ダイス)
              VMI(通常ダイス)H(ハンガーダイス)
              VMI(通常ダイス)

          難易度0指定：Critical処理と達成数のカウントを行い、全てのチェックを行わない
          例) 0VMF(通常ダイス)+(ハンガーダイス)
              0VMF(通常ダイス)
              0VMI(通常ダイス)+(ハンガーダイス)
              0VMI(通常ダイス)

      MESSAGETEXT

      DIFFICULTY_INDEX                            = 1
      DICE_POOL_HUNGER_DICE_NO_INCLUDED_INDEX     = 5
      HUNGER_DICE_NO_INCLUDED_INDEX               = 7
      COMMAND_HUNGER_DICE_INCLUDED_INDEX          = 9
      DICE_POOL_HUNGER_DICE_INCLUDED_INDEX        = 10
      HUNGER_DICE_INCLUDED_INDEX                  = 12

      # 難易度に指定可能な特殊値
      NOT_CHECK_SUCCESS = -1 # 判定成功にかかわるチェックを行わない(判定失敗に関わるチェックは行う)

      register_prefix('\d*(VMF|(VMI\d*(H\d?)?))')

      def eval_game_system_specific_command(command)
        m = /\A(\d+)?(((VMF)(\d+)(\+(\d+))?)|((VMI)(\d+)(H(\d+))?))$/.match(command)
        unless m
          return ''
        end

        dice_pool, hunger_dice_pool = get_dice_pools(m)
        if dice_pool < 0
          return "ダイスプール0のときにハンガーダイスは指定できません。"
        end
        if hunger_dice_pool > 5
          return "ハンガーダイス指定は5ダイスが最大です。"
        end

        dice_text, success_dice, ten_dice, = make_dice_roll(dice_pool)
        result_text = "(#{dice_pool}D10"

        if hunger_dice_pool >= 0
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

        return get_roll_result(result_text, success_dice, ten_dice, hunger_ten_dice, hunger_botch_dice, difficulty)
      end

      private

      def get_dice_pools(m)
        hunger_dice_included_command = m[COMMAND_HUNGER_DICE_INCLUDED_INDEX]
        if hunger_dice_included_command && hunger_dice_included_command == "VMI"
          # Hunger Diceを内数処理するの場合
          hunger_dice_pool = m[HUNGER_DICE_INCLUDED_INDEX].nil? ? -1 : m[HUNGER_DICE_INCLUDED_INDEX].to_i
          dice_pool_value = m[DICE_POOL_HUNGER_DICE_INCLUDED_INDEX].to_i
          dice_pool = dice_pool_value - (hunger_dice_pool < 0 ? 0 : hunger_dice_pool)
          if dice_pool_value > 0 && hunger_dice_pool >= dice_pool_value
            # 1 以上のダイスプール、かつ、ハンガーダイスがダイスプール以上のとき、ダイスプールが全てハンガーダイスになる。
            dice_pool = 0
            hunger_dice_pool = dice_pool_value
          end
        else
          # Hunger DiceがPLによる内数指定の場合
          hunger_dice_pool = m[HUNGER_DICE_NO_INCLUDED_INDEX].nil? ? -1 : m[HUNGER_DICE_NO_INCLUDED_INDEX].to_i
          dice_pool = m[DICE_POOL_HUNGER_DICE_NO_INCLUDED_INDEX].to_i
        end
        return dice_pool, hunger_dice_pool
      end

      def get_roll_result(result_text, success_dice, ten_dice, hunger_ten_dice, hunger_botch_dice, difficulty)
        result_text = "#{result_text} 達成数=#{success_dice}"
        is_critical = ten_dice >= 2

        if difficulty > 0
          result_text = "#{result_text} 難易度=#{difficulty}"

          if success_dice >= difficulty
            result_text = "#{result_text} 上回り=#{success_dice - difficulty}"

            if hunger_ten_dice > 0 && is_critical
              return Result.critical("#{result_text}：判定成功! [凄惨なるクリティカル/Messy Critical]")
            elsif is_critical
              return Result.critical("#{result_text}：判定成功! [クリティカル成功/Critical Win]")
            end

            return Result.success("#{result_text}：判定成功!")
          else
            if hunger_botch_dice > 0
              return Result.fumble("#{result_text}：判定失敗! [獣の過ち/Bestial Failure]")
            end
            if success_dice == 0
              return Result.fumble("#{result_text}：判定失敗! [完全失敗/Total Failure]")
            end

            return Result.failure("#{result_text}：判定失敗!")
          end
        elsif difficulty < 0
          if success_dice == 0
            if hunger_botch_dice > 0
              return Result.fumble("#{result_text}：判定失敗! [獣の過ち/Bestial Failure]")
            end

            return Result.fumble("#{result_text}：判定失敗! [完全失敗/Total Failure]")
          else
            if hunger_botch_dice > 0
              result_text = "#{result_text}\n　判定失敗なら [獣の過ち/Bestial Failure]"
            end
            if hunger_ten_dice > 0 && is_critical
              result_text = "#{result_text}\n　判定成功なら [凄惨なるクリティカル/Messy Critical]"
            elsif is_critical
              result_text = "#{result_text}\n　判定成功なら [クリティカル成功/Critical Win]"
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
        botch_dice = dice_list.count(1)

        return dice_text, success_dice, ten_dice, botch_dice
      end
    end
  end
end
