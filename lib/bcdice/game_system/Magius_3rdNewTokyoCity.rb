# frozen_string_literal: true

require 'bcdice/game_system/Magius'

module BCDice
  module GameSystem
    class Magius_3rdNewTokyoCity < Magius
      # ゲームシステムの識別子
      ID = 'Magius_3rdNewTokyoCity'

      # ゲームシステム名
      NAME = 'MAGIUS:新世紀エヴァンゲリオンRPG 決戦！第3新東京市'

      # ゲームシステム名の読みがな
      SORT_KEY = 'まきうすしんせいきえうあんけりおんRPGけつせんたい3しんとうきようし'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■能力値判定　MA+x>=t        x:修正値 t:目標値
        例)MA>=7: ダイスを2個振って、その結果(成功,失敗,絶対成功,絶対失敗)を表示

        ■技能値判定　MS+x>=t        x:修正値 t:目標値
        例)MS>=7: ダイスを3個振って、そのうち上位2つを採用し、結果(成功,失敗,絶対成功,絶対失敗)を表示

      INFO_MESSAGETEXT

      register_prefix('M[AS]')

      private

      # 能力値判定の結果取得
      # @param [Integer] total, dice_add, target
      # @return [Result]
      def get_result_of_ability_action(total, dice_add, target)
        if dice_add == 12
          return Result.critical("絶対成功")
        elsif dice_add == 2
          return Result.fumble("絶対失敗")
        elsif total >= target
          return Result.success("成功")
        else
          return Result.failure("失敗")
        end
      end

      # 技能値判定の結果取得
      # @param [Integer] total, dice_add, target
      # @return [Result]
      def get_result_of_skill_action(total, dice_add, target)
        if dice_add == 12
          return Result.critical("絶対成功")
        elsif dice_add == 2
          return Result.fumble("絶対失敗")
        elsif total >= target
          return Result.success("成功")
        else
          return Result.failure("失敗")
        end
      end
    end
  end
end
