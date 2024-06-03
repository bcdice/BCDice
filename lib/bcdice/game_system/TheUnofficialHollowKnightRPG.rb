# frozen_string_literal: true

module BCDice
  module GameSystem
    class TheUnofficialHollowKnightRPG < Base
      # ゲームシステムの識別子
      ID = 'TheUnofficialHollowKnightRPG'

      # ゲームシステム名
      NAME = 'The Unofficial Hollow Knight RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しあんおふいしやるほろうないとRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・能力値判定　[n]AD[+b][#r][>=t]
        　n: 能力値。小数可。省略不可。
        　b: ボーナス、ペナルティダイス。省略可。
        　r: 追加リロールダイス数。省略可。
        　t: 目標値。>=含めて省略可。
        　成功数を判定。
        　例）1AD, 2.5AD, 1.5AD+1, 2AD#1, 2.5AD+2#2>=4

        ・イニシアチブ　[n]INTI[+b][#r]
        　n: イニシアチブに使う能力値。省略不可。
          b: ボーナス、ペナルティダイス。省略可。
          r: 追加リロールダイス数。省略可。
        　振り直しを行ったうえでイニシアチブ値を計算。
        　例）1INTI, 2.5INTI, 1.5INTI+1, 2INTI#1, 2.5INTI+2#2
      INFO_MESSAGE_TEXT

      register_prefix('(\d+\.?\d*)?AD([+-](\d+))?(#(\d+))?(>=(\d+))?', '(\d+\.?\d*)?(INTI|inti)([+-](\d+))?(#(\d+))?')

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
          return "+#{number.abs}"
        elsif number < 0
          return "-#{number.abs}"
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
        failed_roll = num_of_die.to_i - result

        # ロールの結果の文字列
        rolled_text = "[" + values.join(",") + "]"

        reroll_values = []

        if reroll == 1
          reroll_values.push(@randomizer.roll_once(6))
        elsif reroll > 1
          reroll_values += @randomizer.roll_barabara(reroll, 6)
        end

        reroll_result = reroll_values.count { |num| num >= difficulty }
        if failed_roll < reroll_result
          reroll_result = failed_roll
        end
        result += reroll_result

        # リロールの結果の文字列をロールの結果の文字列に追加する
        unless reroll_values.empty?
          rolled_text += " Reroll [" + reroll_values.join(",") + "]"
        end

        # 結果
        return "(#{dice_command}) > #{rolled_text} > #{result}成功"
      end

      # イニシアチブロール
      def initiative_roll(command)
        m = /^(\d+\.?\d*)?(INTI|inti)([+-](\d+))?(#(\d+))?/.match(command)
        unless m
          return nil
        end

        grace = m[1].to_f
        bonus = m[3].to_i
        reroll = m[6].to_i

        if /\.[1-9]+/ =~ grace.to_s
          dice_command = "(#{grace}INTI#{number_with_sign_from_int(bonus)}#{number_with_reroll_from_int(reroll)})"
          reroll += 1
        else
          dice_command = "(#{grace.to_i}INTI#{number_with_sign_from_int(bonus)}#{number_with_reroll_from_int(reroll)})"
        end

        values = @randomizer.roll_barabara(grace + bonus, 6)

        revalue = []
        unless reroll == 0
          revalue = @randomizer.roll_barabara(reroll, 6)
        end
        revalue = revalue.sort

        result = 0

        res_text = "["
        values.each do |value|
          if revalue.empty? # リロールがなければ
            res_text += value.to_s
            result += value
          else # リロールがあったら
            is_min = false
            index = -1
            revalue.each do |re|
              index += 1
              next unless re > value # リロールしたダイス最小値か

              res_text += "#{value}<<#{re}"
              result += re
              revalue.delete_at(index)
              is_min = true
              break
            end
            unless is_min # 最小値でなかったら
              res_text += value.to_s
              result += value
            end
          end

          res_text += ","
        end
        res_text = res_text.chop
        res_text += "]"

        return "#{dice_command} > #{res_text} > #{result}"
      end
    end
  end
end
