# frozen_string_literal: true

module BCDice
  module GameSystem
    class YearZeroEngine < Base
      # ゲームシステムの識別子
      ID = 'YearZeroEngine'

      # ゲームシステム名
      NAME = 'YearZeroEngine'

      # ゲームシステム名の読みがな
      SORT_KEY = 'いやあせろえんしん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・ダイスプール判定コマンド(nYZEx+x+x+m)
          (難易度)YZE(能力ダイス数)+(技能ダイス数)+(アイテムダイス数)+(修正値)  # (6のみを数える)
          (難易度)YZE(能力ダイス数)+(技能ダイス数)+(アイテムダイス数)-(修正値)  # (6のみを数える)

        ・ダイスプール判定コマンド(nMYZx+x+x)
          (難易度)MYZ(能力ダイス数)+(技能ダイス数)+(アイテムダイス数)  # (1と6を数え、プッシュ可能数を表示)
          (難易度)MYZ(能力ダイス数)-(技能ダイス数)+(アイテムダイス数)  # (1と6を数え、プッシュ可能数を表示、技能のマイナス指定)

          ※ 難易度と技能、アイテムダイス数は省略可能

        ・ステップダイス判定コマンド(nYZSx+x+m+f)
          (難易度)YZS(能力ダイス面数)+(技能ダイス面数)+(修正値)   # (1,6を数え、プッシュ可能数を表示)
          (難易度)YZS(能力ダイス面数)+(技能ダイス面数)-(修正値)   # (1,6を数え、プッシュ可能数を表示)
          (難易度)YZS(能力ダイス面数)+(技能ダイス面数)+(修正値)A  # (1,6を数え、プッシュ可能数を表示、有利)
          (難易度)YZS(能力ダイス面数)+(技能ダイス面数)-(修正値)A  # (1,6を数え、プッシュ可能数を表示、有利)
          (難易度)YZS(能力ダイス面数)+(技能ダイス面数)+(修正値)D  # (1,6を数え、プッシュ可能数を表示、不利)
          (難易度)YZS(能力ダイス面数)+(技能ダイス面数)-(修正値)D  # (1,6を数え、プッシュ可能数を表示、不利)
      INFO_MESSAGE_TEXT

      DIFFICULTY_INDEX      =  1 # 難易度のインデックス
      COMMAND_TYPE_INDEX    =  2 # コマンドタイプのインデックス
      ABILITY_INDEX         =  3 # 能力値ダイスのインデックス
      SKILL_SIGNED_INDEX    =  5 # 技能値ダイス符号のインデックス
      SKILL_INDEX           =  6 # 技能値ダイスのインデックス
      GEAR_INDEX            =  8 # アイテムダイスのインデックス
      MODIFIER_SIGNED_INDEX = 10 # 修正値の符号のインデックス
      MODIFIER_INDEX        = 11 # 修正値のインデックス

      register_prefix('(\d+)?(YZE|MYZ|YZS)')

      def dice_info_init()
        @total_success_dice = 0
        @total_botch_dice = 0
        @base_botch_dice = 0
        @skill_botch_dice = 0
        @gear_botch_dice = 0
        @push_dice = 0
        @difficulty = 0
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) ||
          resolute_push_action(command) ||
          resolute_step_action(command)
      end

      def resolute_action(command)
        m = /\A(\d+)?(YZE)(\d+)((\+)(\d+))?(\+(\d+))?((\+|-)(\d+))?/.match(command)
        unless m
          return nil
        end

        dice_info_init

        @difficulty = m[DIFFICULTY_INDEX].to_i
        attribute = m[ABILITY_INDEX].to_i
        skill = m[SKILL_INDEX].to_i
        gear = m[GEAR_INDEX].to_i
        modifier = m[MODIFIER_INDEX].to_i
        if m[MODIFIER_SIGNED_INDEX] == '-'
          if skill >= modifier
            skill -= modifier
          else
            modifier -= skill
            skill = 0
            if gear >= modifier
              gear -= modifier
            else
              modifier -= gear
              gear = 0
              if attribute >= modifier
                attribute -= modifier
              else
                attribute = 0
              end
            end
          end
        else
          skill += modifier
        end

        @total_success_dice = 0

        dice_pool = attribute
        ability_dice_text, success_dice, botch_dice = make_dice_roll(dice_pool)

        @total_success_dice += success_dice
        @total_botch_dice += botch_dice
        @base_botch_dice += botch_dice # 能力ダメージ
        @push_dice += (dice_pool - (success_dice + botch_dice))

        dice_count_text = "(#{dice_pool}D6)"
        dice_text = ability_dice_text

        if m[SKILL_INDEX]
          dice_pool = skill
          skill_dice_text, success_dice, botch_dice = make_dice_roll(dice_pool)

          @total_success_dice += success_dice
          @total_botch_dice += botch_dice
          @skill_botch_dice += botch_dice # 技能ダイスの1はpushで振り直し可能（例えマイナス技能でも）
          @push_dice += (dice_pool - success_dice) # 技能ダイスのみ1を含むので、ここでは1を計算に入れない

          dice_count_text += "+(#{dice_pool}D6)"
          dice_text += "+#{skill_dice_text}"
        end

        if m[GEAR_INDEX]
          dice_pool = gear
          gear_dice_text, success_dice, botch_dice = make_dice_roll(dice_pool)

          @total_success_dice += success_dice
          @total_botch_dice += botch_dice
          @gear_botch_dice += botch_dice # ギアダメージ
          @push_dice += (dice_pool - (success_dice + botch_dice))

          dice_count_text += "+(#{dice_pool}D6)"
          dice_text += "+#{gear_dice_text}"
        end

        return make_result_with_yze(dice_count_text, dice_text)
      end

      def resolute_push_action(command)
        m = /\A(\d+)?(MYZ)(\d+)((\+|-)(\d+))?(\+(\d+))?/.match(command)
        unless m
          return nil
        end

        dice_info_init

        @difficulty = m[DIFFICULTY_INDEX].to_i

        @total_success_dice = 0

        dice_pool = m[ABILITY_INDEX].to_i
        ability_dice_text, success_dice, botch_dice = make_dice_roll(dice_pool)

        @total_success_dice += success_dice
        @total_botch_dice += botch_dice
        @base_botch_dice += botch_dice # 能力ダメージ
        @push_dice += (dice_pool - (success_dice + botch_dice))

        dice_count_text = "(#{dice_pool}D6)"
        dice_text = ability_dice_text

        if m[SKILL_INDEX]
          dice_pool = m[SKILL_INDEX].to_i
          skill_dice_text, success_dice, botch_dice = make_dice_roll(dice_pool)

          skill_unsigned = m[SKILL_SIGNED_INDEX]
          if skill_unsigned == '-'
            @total_success_dice -= success_dice # マイナス技能の成功は通常の成功と相殺される
          else
            @total_success_dice += success_dice
          end

          @total_botch_dice += botch_dice
          @skill_botch_dice += botch_dice # 技能ダイスの1はpushで振り直し可能（例えマイナス技能でも）
          @push_dice += (dice_pool - success_dice) # 技能ダイスのみ1を含むので、ここでは1を計算に入れない

          dice_count_text += "#{skill_unsigned}(#{dice_pool}D6)"
          dice_text += "#{skill_unsigned}#{skill_dice_text}"
        end

        if m[GEAR_INDEX]
          dice_pool = m[GEAR_INDEX].to_i
          gear_dice_text, success_dice, botch_dice = make_dice_roll(dice_pool)

          @total_success_dice += success_dice
          @total_botch_dice += botch_dice
          @gear_botch_dice += botch_dice # ギアダメージ
          @push_dice += (dice_pool - (success_dice + botch_dice))

          dice_count_text += "+(#{dice_pool}D6)"
          dice_text += "+#{gear_dice_text}"
        end

        return make_result_with_myz(dice_count_text, dice_text)
      end

      def make_result_with_yze(dice_count_text, dice_text)
        result_text = "#{dice_count_text} ＞ #{dice_text} 成功数:#{@total_success_dice}"
        if @difficulty > 0
          if @total_success_dice >= @difficulty
            return Result.success("#{result_text} 難易度=#{@difficulty}:判定成功！")
          else
            return Result.failure("#{result_text} 難易度=#{@difficulty}:判定失敗！")
          end
        end
        return result_text
      end

      def make_result_with_myz(dice_count_text, dice_text)
        result_text = "#{dice_count_text} ＞ #{dice_text} 成功数:#{@total_success_dice}"
        atter_text = "\n出目1：[能力：#{@base_botch_dice},技能：#{@skill_botch_dice},アイテム：#{@gear_botch_dice}) プッシュ可能=#{@push_dice}ダイス"

        if @difficulty > 0
          if @total_success_dice >= @difficulty
            return Result.success("#{result_text} 難易度=#{@difficulty}:判定成功！#{atter_text}")
          else
            return Result.failure("#{result_text} 難易度=#{@difficulty}:判定失敗！#{atter_text}")
          end
        end

        return "#{result_text}#{atter_text}"
      end

      def make_dice_roll(dice_pool)
        dice_list = @randomizer.roll_barabara(dice_pool, 6)
        success_dice = dice_list.count(6)
        botch_dice = dice_list.count(1)

        return "[#{dice_list.join(',')}]", success_dice, botch_dice
      end

      def make_dice_a_roll(count, type)
        dice_list = @randomizer.roll_barabara(count, type)
        botch_dice = dice_list.count(1)
        success_dice = dice_list.count { |val| val >= 6 }
        success_level = success_dice + dice_list.count { |val| val >= 10 }

        @total_success_dice += success_level
        @total_botch_dice += botch_dice
        @push_dice += (count - (success_dice + botch_dice))

        return "[#{dice_list.join(',')}]", botch_dice
      end

      def get_rolling_dice(dice_type1, dice_type2, dice_upgrade)
        dice_type1 = 4 if dice_type1 < 4
        dice_type2 = 4 if dice_type2 < 4

        while dice_upgrade > 0
          if dice_type1 >= dice_type2
            dice_type2 += 2 if dice_type2 < 12
          else
            dice_type1 += 2 if dice_type1 < 12
          end
          dice_upgrade -= 1
        end

        while dice_upgrade < 0
          if dice_type1 <= dice_type2
            dice_type2 -= 2 if dice_type2 > 4
          else
            dice_type1 -= 2 if dice_type1 > 4
          end
          dice_upgrade += 1
        end

        if dice_type1 == 4 && dice_type2 == 4
          dice_type1 = 6
        end

        return dice_type1, dice_type2
      end

      def resolute_step_action(command)
        m = /\A(\d+)?(YZS)(\d+)((\+)(\d+))?((\+|-)(\d+))?(A|D)?/.match(command)
        unless m
          return nil
        end

        dice_info_init

        @difficulty = m[DIFFICULTY_INDEX].to_i
        attribute = m[ABILITY_INDEX].to_i
        skill = m[SKILL_INDEX].to_i
        modifier = m[7].to_i
        advantage = m[10]

        dice_count_text = ""
        dice_text = ""

        dice_type1, dice_type2 = get_rolling_dice(attribute, skill, modifier)

        if dice_type1 <= dice_type2
          if advantage
            if advantage == "A" && (dice_type1 > 4)
              ability_dice_text, botch_dice = make_dice_a_roll(2, dice_type1)

              @base_botch_dice += botch_dice # 能力ダメージ
              dice_count_text = "(2D#{dice_type1})"
              dice_text = ability_dice_text
            end
          else
            if dice_type1 > 4
              ability_dice_text, botch_dice = make_dice_a_roll(1, dice_type1)

              @base_botch_dice += botch_dice # 能力ダメージ
              dice_count_text = "(1D#{dice_type1})"
              dice_text = ability_dice_text
            end
          end
          if dice_type2 > 4
            skill_dice_text, botch_dice = make_dice_a_roll(1, dice_type2)

            @skill_botch_dice += botch_dice
            dice_count_text += "+" unless dice_count_text == ""
            dice_text += "+" unless dice_text == ""
            dice_count_text += "(1D#{dice_type2})"
            dice_text += skill_dice_text
          end
        else
          if dice_type1 > 4
            ability_dice_text, botch_dice = make_dice_a_roll(1, dice_type1)

            @base_botch_dice += botch_dice # 能力ダメージ
            dice_count_text = "(1D#{dice_type1})"
            dice_text = ability_dice_text
          end
          if advantage
            if advantage == "A" && (dice_type2 > 4)
              skill_dice_text, botch_dice = make_dice_a_roll(2, dice_type2)

              @skill_botch_dice += botch_dice
              dice_count_text += "+(2D#{dice_type2})"
              dice_text += "+#{skill_dice_text}"
            end
          else
            if dice_type2 > 4
              skill_dice_text, botch_dice = make_dice_a_roll(1, dice_type2)

              @skill_botch_dice += botch_dice
              dice_count_text += "+(1D#{dice_type2})"
              dice_text += "+#{skill_dice_text}"
            end
          end
        end

        return make_result_with_myz(dice_count_text, dice_text)
      end
    end
  end
end
