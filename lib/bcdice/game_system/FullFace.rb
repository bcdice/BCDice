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
        ■判定　x+bFF<=a[,t][&d]   x:ヒート(省略時は3) b:判定修正 a:能力値 t:難易度(省略可) d:基本ダメージ(省略可)

        例)FF<=2:     能力値2で判定し、その結果(成功数,1の目の数,6の目の数,バースト)を表示。
           6FF<=3:    ヒート6,能力値3で戦闘判定し、その結果( 〃 )を表示。
           8+2FF<=3:  ヒート8,判定修正+2,能力値3で戦闘判定し、その結果( 〃 )を表示。
           FF<=2,1:   能力値2,難易度1で判定し、その結果(成功数,1の目の数,6の目の数,成功・失敗,バースト)を表示。
           6FF<=3,2&1:ヒート6,能力値3,難易度2,基本ダメージ1で戦闘判定し、その結果(成功数,1の目の数,6の目の数,ダメージ,バースト)を表示。

      INFO_MESSAGETEXT

      register_prefix('([+\d]+)*FF')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        resolute_action(command)
      end

      private

      # 戦闘判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /^(\d*)([+\d]+)*FF<=(\d)(,(\d))?(&(\d))?$/.match(command)
        return nil unless m

        heat_level = m[1].to_i
        heat_level = 3 if heat_level == 0
        modify = Arithmetic.eval("0#{m[2]}", @round_type)
        status_no = m[3].to_i
        target_no = m[5].to_i
        damage_no = m[7].to_i

        dice_array = []

        dice = @randomizer.roll_barabara(heat_level, 6).sort
        ones = dice.count(1)
        sixs = dice.count(6)
        success_num = dice.count { |val| val <= status_no }
        dice_array.push(dice.join(","))

        if modify > 0
          dice = @randomizer.roll_barabara(modify, 6).sort
          ones += dice.count(1)
          success_num += dice.count { |val| val <= status_no }
          dice_array.push(dice.join(","))
        end
        ones_total = ones

        while ones > 0
          dice = @randomizer.roll_barabara(ones, 6).sort
          ones = dice.count(1)
          ones_total += ones
          success_num += dice.count { |val| val <= status_no }
          dice_array.push(dice.join(","))
        end

        return Result.new.tap do |result|
          command_out = "(#{heat_level}#{Format.modifier(modify)}FF<=#{status_no}"
          if sixs >= 2
            result.fumble = true
            result.condition = false
          else
            result.condition = (success_num > 0)
            result.critical = (ones_total > 0)
          end
          result_txt = []
          result_txt.push("成功度(#{success_num})")
          result_txt.push("1の目(#{ones_total})") if ones_total > 0
          result_txt.push("6の目(#{sixs})") if sixs > 0
          if target_no > 0
            command_out += ",#{target_no}"
            if success_num >= target_no
              result_txt.push("成功")
              result.condition = true
            else
              result_txt.push("失敗")
              result.condition = false
            end
          end
          if damage_no > 0
            command_out += "&#{damage_no}"
            damage = damage_no + ones_total
            result_txt.push("ダメージ(#{damage})")
          end
          result_txt.push("バースト") if result.fumble?
          command_out += ")"

          sequence = [
            command_out,
            dice_array.join('+').to_s,
            result_txt.join(',').to_s,
          ].compact

          result.text = sequence.join(" ＞ ")
        end
      end
    end
  end
end
