# frozen_string_literal: true

module BCDice
  module GameSystem
    class FullFace < Base
      # ゲームシステムの識別子
      ID = 'FullFace'

      # ゲームシステム名
      NAME = 'フルフェイス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふるふえいす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　x+bFF<=t   x:ヒート(省略時は3) b:判定修正 t:能力値

        例)FF<=2:   能力値2で判定し、その結果(成功数,1の目の数,バースト)を表示。
           6FF<=3:  ヒート6,能力値3で戦闘判定し、その結果( 〃 )を表示。
           8+2FF<=3:ヒート8,判定修正+2,能力値3で戦闘判定し、その結果( 〃 )を表示。
      INFO_MESSAGETEXT

      register_prefix('([+\d]+)*FF')

      def eval_game_system_specific_command(command)
        resolute_action(command)
      end

      private

      # 技能判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /(\d*)([+]\d+)*FF<=(\d)/.match(command)
        return nil unless m

        heat_level = m[1].to_i
        heat_level = 3 if heat_level == 0
        modify = Arithmetic.eval("0#{m[2]}", @round_type) || 0
        status_no = m[3].to_i

        dice_array = []
        is_critical = false

        dice = @randomizer.roll_barabara(heat_level, 6)
        ones = dice.count { |val| val == 1 }
        sixs = dice.count { |val| val == 6 }
        success_num = dice.count { |val| val <= status_no }
        dice_array.push(dice.join(","))

        if modify > 0
          dice = @randomizer.roll_barabara(modify, 6)
          ones += dice.count { |val| val == 1 }
          success_num += dice.count { |val| val <= status_no }
          dice_array.push(dice.join(","))
        end
        ones_total = ones

        while ones > 0
          is_critical = true
          dice = @randomizer.roll_barabara(ones, 6)
          ones = dice.count { |val| val == 1 }
          ones_total += ones
          success_num += dice.count { |val| val <= status_no }
          dice_array.push(dice.join(","))
        end

        return Result.new.tap do |result|
          result.condition = (success_num > 0)
          result.critical = is_critical
          if sixs >= 2
            result.fumble = true
            result.critical = false
            result.condition = false
          end

          sequence = [
            "(#{heat_level}#{Format.modifier(modify)}FF<=#{status_no})",
            dice_array.join('+').to_s,
            if result.fumble?
              "バースト"
            elsif result.critical?
              "成功度(#{success_num}),1の目(#{ones_total})"
            else
              "成功度(#{success_num})"
            end
          ].compact

          result.text = sequence.join(" ＞ ")
        end
      end
    end
  end
end
