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
        ・判定コマンド(nYZEx+x+x)
          (難易度)YZE(能力ダイス数)+(技能ダイス数)+(アイテムダイス数)  # (6のみを数える)

        ・判定コマンド(nMYZx+x+x)
          (難易度)MYZ(能力ダイス数)+(技能ダイス数)+(アイテムダイス数)  # (1と6を数え、プッシュ可能数を表示)
          (難易度)MYZ(能力ダイス数)-(技能ダイス数)+(アイテムダイス数)  # (1と6を数え、プッシュ可能数を表示、技能のマイナス指定)

          ※ 難易度と技能、アイテムダイス数は省略可能
      INFO_MESSAGE_TEXT

      DIFFICULTY_INDEX   =  1 # 難易度のインデックス
      COMMAND_TYPE_INDEX =  2 # コマンドタイプのインデックス
      ABILITY_INDEX      =  3 # 能力値ダイスのインデックス
      SKILL_INDEX        =  5 # 技能値ダイスのインデックス
      GEAR_INDEX         =  7 # アイテムダイスのインデックス

      register_prefix('(\d+)?(YZE|MYZ)')

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
        m = /\A(\d+)?(YZE|MYZ)(\d+)(\+(\d+))?(\+(\d+))?/.match(command)
        unless m
          return ''
        end

        dice_info_init

        @difficulty = m[DIFFICULTY_INDEX].to_i

        command_type = m[COMMAND_TYPE_INDEX]

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

          @total_success_dice += success_dice
          @total_botch_dice += botch_dice
          @skill_botch_dice += botch_dice # 技能ダイスの1はpushで振り直し可能
          @push_dice += (dice_pool - success_dice) # 技能ダイスのみ1を含む

          dice_count_text += "+(#{dice_pool}D6)"
          dice_text += "+#{skill_dice_text}"
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

        return make_result_text(command_type, dice_count_text, dice_text)
      end

      def make_result_text(command_type, dice_count_text, dice_text)
        if command_type == 'YZE'
          return make_result_with_yze(dice_count_text, dice_text)
        elsif command_type == 'MYZ'
          return make_result_with_myz(dice_count_text, dice_text)
        end

        return 'Error' # 到達しないはず
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
    end
  end
end
