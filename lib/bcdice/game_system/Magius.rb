# frozen_string_literal: true

module BCDice
  module GameSystem
    class Magius < Base
      # ゲームシステムの識別子
      ID = 'Magius'

      # ゲームシステム名
      NAME = 'MAGIUS'

      # ゲームシステム名の読みがな
      SORT_KEY = 'まきうす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■能力値判定　MA+x>=t        x:修正値 t:目標値
        例)MA>=7: ダイスを2個振って、その結果を表示

        ■技能値判定　MS+x>=t        x:修正値 t:目標値
        例)MS>=7: ダイスを3個振って、そのうち上位2つを採用し、結果を表示

      INFO_MESSAGETEXT

      register_prefix('M[AS]')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        resolute_ability_action(command) ||
          resolute_skill_action(command)
      end

      private

      def with_symbol(number)
        if number == 0
          return ""
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      # 能力値判定
      # @param [String] command
      # @return [Result]
      def get_result_of_ability_action(total, _dice_add, target)
        if total >= target
          return Result.success("成功")
        else
          return Result.failure("失敗")
        end
      end

      def resolute_ability_action(command)
        m = /MA([+-]\d+)*>=(\d+)/.match(command)
        return nil unless m

        modify = m[1] ? Arithmetic.eval(m[1], @round_type) : 0
        target = m[2].to_i

        dices = @randomizer.roll_barabara(2, 6).sort
        dice_text = dices.join(",")
        dice_add = dices.sum
        total = dice_add + modify

        result = get_result_of_ability_action(total, dice_add, target)

        sequence = [
          "(#{command})",
          "[#{dice_text}]#{with_symbol(modify)}",
          total,
          result.text,
        ].compact

        result.text = sequence.join(" ＞ ")

        return result
      end

      # 技能値値判定
      # @param [String] command
      # @return [Result]
      def get_result_of_skill_action(total, _dice_add, target)
        if total >= target
          return Result.success("成功")
        else
          return Result.failure("失敗")
        end
      end

      def resolute_skill_action(command)
        m = /MS([+-]\d+)*>=(\d+)/.match(command)
        return nil unless m

        modify = m[1] ? Arithmetic.eval(m[1], @round_type) : 0
        target = m[2].to_i

        dices = @randomizer.roll_barabara(3, 6).sort
        dice_text = dices.join(",")
        dice_add = dices[1].to_i + dices[2].to_i
        total = dice_add + modify

        result = get_result_of_skill_action(total, dice_add, target)

        sequence = [
          "(#{command})",
          "[#{dice_text}]#{with_symbol(modify)}",
          total,
          result.text,
        ].compact

        result.text = sequence.join(" ＞ ")

        return result
      end
    end
  end
end
