# frozen_string_literal: true

module BCDice
  module GameSystem
    class Revulture < Base
      # ゲームシステムの識別子
      ID = 'Revulture'

      # ゲームシステム名
      NAME = '光砕のリヴァルチャー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'こうさいのりうあるちやあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■アタック判定（ xAT, xATK, xATTACK ）
        x: ダイス数
        例） 3AT, 4ATK, 5ATTACK
      HELP

      ATTACK_ROLL_REG = /^(\d+)?AT(TACK|K)?/i.freeze
      register_prefix('\d+AT')

      def eval_game_system_specific_command(command)
        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[1].to_i)
        end
      end

      def roll_attack(dice_count)
        raise if dice_count < 1

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        Result.new("(#{dice_count}attack) ＞ #{dices.join(',')}")
      end
    end
  end
end
