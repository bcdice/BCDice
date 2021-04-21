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
        x: ダイス数（加算 + と除算 / を使用可能）
        例） 3AT, 4ATK, 5+6ATTACK, 15/2AT

        □アタック判定　目標値つき（ xAT<=y, xATK<=y, xATTACK<=y ）
        x: ダイス数（加算 + と除算 / を使用可能）
        y: 目標値（ 1 以上 6 以下）
        例） 3AT<=4
      HELP

      ATTACK_ROLL_REG = %r{^(\d+([+/]\d+)*)?AT(TACK|K)?(<=([1-6]))?}i.freeze
      register_prefix('\d+([+\/]\d+)*AT')

      def eval_game_system_specific_command(command)
        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[1], m[5])
        end
      end

      def roll_attack(dice_count_expression, border)
        dice_count = Arithmetic.eval(dice_count_expression, round_type: RoundType::FLOOR)
        raise if dice_count < 1

        dices = @randomizer.roll_barabara(dice_count, 6).sort
        hit_count = border.nil? ? nil : dices.count { |dice| dice <= border.to_i }

        if border.nil?
          Result.new("(#{dice_count}attack) ＞ #{dices.join(',')}")
        else
          Result.new("(#{dice_count}attack<=#{border}) ＞ #{dices.join(',')} ＞ ヒット数 #{hit_count}").tap do |r|
            r.success = hit_count > 0
            r.failure = !r.success?
          end
        end
      end
    end
  end
end
