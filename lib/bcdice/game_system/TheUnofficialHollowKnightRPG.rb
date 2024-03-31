# frozen_string_literal: true

module BCDice
  module GameSystem
    class TheUnofficialHollowKnightRPG < Base
      # ゲームシステムの識別子
      ID = 'TheUnofficialHollowKnightRPG'

      # ゲームシステム名
      NAME = 'TheUnofficialHollowKnightRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:English:TheUnofficialHollowKnightRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・能力値判定　[n]AD[+b][#r][>=t]
        　n: 能力値。小数可。省略不可。
        　b: ボーナス、ペナルティダイス。省略可。
        　r: 追加リロールダイス数。省略可。
        　t: 目標値。>=含めて省略可。
        　成功数を判定。
        　例）1AD, 2.5AD, 1.5AD+1, 2AD(1), 2.5AD+2(2)>=4

        ・イニシアチブ　[grace]INTI
        　grace: キャラクターの優雅の値
        　振り直しを行ったうえでイニシアチブ値を計算。
      INFO_MESSAGE_TEXT

      register_prefix('(\d+\.?\d*)?AD([+-](\d+))?(#(\d*))?(>=(\d+))?', '(\d+\.?\d*)?(INTI|inti)')

      def initialize(command)
        super(command)

        @sort_barabara_dice = false # バラバラロール（Bコマンド）でソート無
      end

      def eval_game_system_specific_command(command)
        ability_roll(command) || initiative_roll(command)
      end

      def number_with_sign_from_int(number)
        if number == 0
          return ""
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      def number_with_reroll_from_int(number)
        if number == 0
          return ""
        elsif number > 0
          return "\##{number}"
        else
          return number.to_s
        end
      end

      # 能力値ロール
      def ability_roll(command)
        m = /^(\d+\.?\d*)?AD([+-](\d+))?(#(\d*))?(>=(\d+))?/.match(command)
        unless m
          return nil
        end

        num_of_die = m[1].to_f
        bonus = m[3].to_i
        reroll = m[5].to_i
        difficulty = m[7].to_i

        if /\.[1-9]+/ =~ num_of_die.to_s
          dice_command = "#{num_of_die}AD#{number_with_sign_from_int(bonus)}#{number_with_reroll_from_int(reroll)}"
          reroll += 1
        else
          dice_command = "#{num_of_die.to_i}AD#{number_with_sign_from_int(bonus)}#{number_with_reroll_from_int(reroll)}"
        end

        if difficulty == 0
          difficulty = 5
        else
          dice_command += ">=#{difficulty}"
        end

        # 振られたダイスを入れる
        values = @randomizer.roll_barabara(num_of_die.to_i + bonus, 6)
        # 成功数
        result = values.count { |num| num >= difficulty }

        # ロールの結果の文字列
        rolled_text = "[" + values.join(",") + "]"

        reroll_values = []

        if reroll == 1
          reroll_values.push(@randomizer.roll_once(6))
        elsif reroll > 1
          reroll_values += @randomizer.roll_barabara(reroll, 6)
        end

        result += reroll_values.count { |num| num >= difficulty }

        # リロールの結果の文字列をロールの結果の文字列に追加する
        if reroll_values.empty?
          rolled_text += " Reroll [" + reroll_values.join(",") + "]"
        end

        # 結果
        return "(#{dice_command}) > #{rolled_text} > #{result}成功"
      end

      # イニシアチブロール
      def initiative_roll(command)
        m = /^(\d+\.?\d*)?(INTI|inti)/.match(command)
        unless m
          return nil
        end

        grace = m[1].to_f
        reroll = 0

        if /\.[1-9]+/ =~ grace.to_s
          reroll += 1
          dice_command = "(#{grace}INTI)"
        else
          dice_command = "(#{grace.to_i}INTI)"
        end

        values = @randomizer.roll_barabara(grace, 6)

        revalue = 0
        if reroll == 1
          revalue = @randomizer.roll_once(6)
        end

        result = 0
        if revalue == 0
          min = 0
        else
          min = values.min
        end

        res_text = "["
        values.each do |value|
          if value == min
            if revalue > min
              res_text += "#{min}<<#{revalue}"
              result += revalue
            else
              res_text += min.to_s
              result += min
            end
            min = 0
          else
            res_text += value.to_s
            result += value
          end

          res_text += ","
        end
        res_text.chop!
        res_text += "]"

        return "#{dice_command} > #{res_text} > #{result}"
      end
    end
  end
end
