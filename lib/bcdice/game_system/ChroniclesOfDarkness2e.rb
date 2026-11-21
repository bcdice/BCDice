# frozen_string_literal: true

module BCDice
  module GameSystem
    class ChroniclesOfDarkness2e < Base
      # ゲームシステムの識別子
      ID = 'ChroniclesOfDarkness2e'

      # ゲームシステム名
      NAME = 'Chronicles of Darkness 2nd Edtion'

      # ゲームシステム名の読みがな
      SORT_KEY = 'くろにくるすおふたあくねす2'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定コマンド(CDx@cWdAs)
            x:ダイスプール(0以下でChance Roll)
            c:振り足し値(省略可、省略時は10)。8-10の値を取る。Chance Rollには適用されない。
            d:武器ダメージ修正(省略可)。判定による成功数が1以上のときにダメージとして修正値を加算。
            s:自動成功数(省略可)。成功数に加算される。

            例1：6ダイスプール、10 again
            CD6
            CD6@10

            例2：9ダイスプール、9の振り足し(9 again)、自動成功1
            CD9@9A1

            例3：0ダイスプール(Chance Roll)、8の振り足し(8 again, 適用されない)、自動成功1、武器修正+2
            CD0@8W2A1

            例4：-1ダイスプール(Chance Roll)
            CD(4-5)

      MESSAGETEXT

      DICE_POOL_INDEX       = 2
      AGAIN_NUMBER_INDEX    = 4
      WEAPON_MODIFIER_INDEX = 6
      AUTO_SUCCESS_INDEX    = 8

      EXCEPTIONAL_SUCCESS_THRESHOLD = 5 # Exceptional Successの閾値

      register_prefix('(CD\d*)')

      def eval_game_system_specific_command(command)
        m = /\A(CD)(-?\d+)(@([8-9]|10))?(W(\d+))?(A(\d+))?$/.match(command)
        unless m
          return ''
        end

        # 引数分解
        dice_pool, again_number, weapon_modifier, auto_success = get_arguments(m)

        # ダイスロール
        success_number, dice_text, dramatic_failure = make_dice_roll(dice_pool, again_number)

        # 結果判定
        get_roll_result(dice_pool, dice_text, success_number, weapon_modifier, auto_success, dramatic_failure)
      end

      private

      def get_roll_result(dice_pool, dice_text, success_number, weapon_modifier, auto_success, dramatic_failure)
        if dice_pool <= 0
          result_text = "Chance Roll(1D10) ＞ "
        else
          result_text = "(#{dice_pool}D10) ＞ "
        end
        result_text = "#{result_text}#{dice_text}success=#{success_number} "

        total_success = success_number + auto_success

        # CofD2e rulebook p21:
        # "A result of 1 on a chance roll causes a dramatic failure, a catastrophe worse than a normal failure."
        # なので、チャンスダイスで"1"が出ていたら自動成功の有無に関わらず Dramatic Failure 発生。
        if dramatic_failure
          Result.fumble("#{result_text}Dramatic Failure!")
        elsif total_success > 0
          if auto_success > 0
            # 成功数の合算が発生するときだけトータル成功数を表示
            result_text = "#{result_text}auto_success=#{auto_success} total_success=#{total_success} "
          end
          if weapon_modifier != 0
            # 成功数が1でもあれば、武器修正とダメージを表示
            result_text = "#{result_text}weapon_modifier=#{weapon_modifier} damage=#{total_success + weapon_modifier} "
          end
          # M:tAw2e rulebook p213:
          # "Several powers and Merits allow exceptional success with three or more successes instead of five."
          # とあり、判定の基本は同じであるM:tAw2eで長所等で Exceptional Success に修正が入るため、CofDの自動成功でも同様と判断した。
          # また、p214に下記のような文言があり、
          # "Note that you count the total number of successes rolled when working out if you scored an exceptional success
          #  — don’t subtract the other party’s successes from yours."
          # 合計数で Exceptional Success を判定すること、相手の成功数を差し引いた値で判定するわけではないことが記されている。
          # 将来、Contested Action の実装として、相手の成功数と自分の成功数の差分で判定を行うなら留意されたし。
          if total_success >= EXCEPTIONAL_SUCCESS_THRESHOLD
            # 5成功以上は Exceptional Success
            Result.critical("#{result_text}Exceptional Success!")
          else
            Result.success("#{result_text}Success!")
          end
        else
          Result.failure("#{result_text}Failure!")
        end
      end

      def get_arguments(m)
        dice_pool = m[DICE_POOL_INDEX].to_i # 0以下のダイスプールはチャンスダイス対応
        again_number = m[AGAIN_NUMBER_INDEX].nil? ? 10 : m[AGAIN_NUMBER_INDEX].to_i # 未指定は10
        weapon_modifier = m[WEAPON_MODIFIER_INDEX].nil? ? 0 : m[WEAPON_MODIFIER_INDEX].to_i
        auto_success = m[AUTO_SUCCESS_INDEX].nil? ? 0 : m[AUTO_SUCCESS_INDEX].to_i

        return dice_pool, again_number, weapon_modifier, auto_success
      end

      def make_dice_roll(dice_pool, again_number)
        if dice_pool <= 0
          # ダイスプールが0以下になるなら、チャンスロール判定
          roll_dice_pool(1, again_number, true)
        else
          roll_dice_pool(dice_pool, again_number, false)
        end
      end

      # make_dice_rollの内部処理
      def roll_dice_pool(dice_pool, again_number, chance_roll)
        success_number = 0
        again_dice = 0
        dice_text = ""

        loop do
          dice_list = @randomizer.roll_barabara(dice_pool, 10)
          dice_text = "#{dice_text}[#{dice_list.join(',')}] "

          if chance_roll # チャンスロール
            if dice_list.count(1) > 0
              return 0, dice_text, true # Dramatic Failure発生
            elsif dice_list.count(10) > 0 # チャンスダイスは10のみ成功
              success_number = 1
            else
              success_number = 0
            end
          else
            success_number += dice_list.count { |x| x >= 8 }
            again_dice = dice_list.count { |x| x >= again_number }
          end

          # CofD2e rulebook p69:
          # "The chance die only counts as a success if you roll a 10, which you do not reroll."
          # のため、chance dieではagain処理を行わない
          if again_dice > 0
            dice_pool = again_dice # 振り足しが存在するなら再判定
          else
            break # 振り足しが存在しないなら抜ける
          end
        end

        return success_number, dice_text, false
      end
    end
  end
end
