# frozen_string_literal: true

module BCDice
  module GameSystem
    class Irisbane < Base
      # ゲームシステムの識別子
      ID = 'Irisbane'

      # ゲームシステム名
      NAME = '瞳逸らさぬイリスベイン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひとみそらさぬいりすへいん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■攻撃判定（ ATTACKx,y,z ）
        x: 攻撃力
        y: 判定数
        z: 目標値
        （※ ATTACK は ATK または AT と簡略化可能）
        例） ATTACK2,3,5, ATK10,2,4, AT8,3,2

        上記 x y z にはそれぞれ四則演算を指定可能。
        例） ATTACK2+7,3*2,5-1
      HELP

      ATTACK_ROLL_REG = %r{^AT(TACK|K)?([+\-*/()\d]+),([+\-*/()\d]+),([+\-*/()\d]+)}i.freeze
      register_prefix('AT(TACK|K)?')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[2], m[3], m[4])
        end
      end

      private

      def roll_attack(power_expression, dice_count_expression, border_expression)
        power = Arithmetic.eval(power_expression, RoundType::CEIL)
        dice_count = Arithmetic.eval(dice_count_expression, RoundType::CEIL)
        border = Arithmetic.eval(border_expression, RoundType::CEIL)
        return if power.nil? || dice_count.nil? || border.nil?

        power = power.clamp(0..)
        border = border.clamp(1, 6)

        command = make_command_text(power, dice_count, border)

        if dice_count <= 0
          return "#{command} ＞ 判定数が 0 です"
        end

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        success_dice_count = dices.count { |dice| dice <= border }
        damage = success_dice_count * power

        message_elements = []
        message_elements << command
        message_elements << dices.join(',')
        message_elements << "成功ダイス数 #{success_dice_count}"
        message_elements << "× 攻撃力 #{power}" if success_dice_count > 0
        message_elements << "ダメージ #{damage}" if success_dice_count > 0

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = success_dice_count > 0
        end
      end

      def make_command_text(power, dice_count, border)
        "(ATTACK#{power},#{dice_count},#{border})"
      end
    end
  end
end
