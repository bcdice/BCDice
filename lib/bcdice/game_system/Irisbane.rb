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
        例） ATTACK2,3,5
        例） ATK10,2,4
        例） AT8,3,2

        上記 x y z にはそれぞれ四則演算を指定可能。
        例） ATTACK2+7,3*2,5-1

        □攻撃判定のダメージ増減（ ATTACKx,y,z[+a]  ATTACKx,y,z[-a]）
        末尾に [+a] または [-a] と指定すると、最終的なダメージを増減できる。
        a: 増減量
        例） ATTACK2,3,5[+10]
        例） ATK10,2,4[-8]
        例） AT8,3,2[-8+5]

        ■表
        CAge 年齢（p27）
      HELP

      ATTACK_ROLL_REG = %r{^AT(TACK|K)?([+\-*/()\d]+),([+\-*/()\d]+),([+\-*/()\d]+)(\[([+\-])([+\-*/()\d]+)\])?}i.freeze
      register_prefix('AT(TACK|K)?')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[2], m[3], m[4], m[6], m[7])
        else
          roll_tables(command, TABLES)
        end
      end

      private

      def roll_attack(power_expression, dice_count_expression, border_expression, modification_operator, modification_expression)
        power = Arithmetic.eval(power_expression, RoundType::CEIL)
        dice_count = Arithmetic.eval(dice_count_expression, RoundType::CEIL)
        border = Arithmetic.eval(border_expression, RoundType::CEIL)
        modification_value = modification_expression.nil? ? nil : Arithmetic.eval(modification_expression, RoundType::CEIL)
        return if power.nil? || dice_count.nil? || border.nil?
        return if modification_operator && modification_value.nil?

        power = 0 if power < 0
        border = border.clamp(1, 6)

        command = make_command_text(power, dice_count, border, modification_operator, modification_value)

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

        if success_dice_count > 0
          if modification_operator && modification_value
            message_elements << "ダメージ #{damage}#{modification_operator}#{modification_value}"
            damage = parse_operator(modification_operator).call(damage, modification_value)
            damage = 0 if damage < 0
            message_elements << damage.to_s
          else
            message_elements << "ダメージ #{damage}"
          end
        end

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = success_dice_count > 0
        end
      end

      def make_command_text(power, dice_count, border, modification_operator, modification_value)
        text = "(ATTACK#{power},#{dice_count},#{border}"
        text += "[#{modification_operator}#{modification_value}]" if modification_operator
        text += ")"
        text
      end

      def parse_operator(operator)
        case operator
        when '+'
          lambda { |x, y| x + y }
        when '-'
          lambda { |x, y| x - y }
        end
      end

      TABLES = {
        "CAGE" => DiceTable::Table.new(
          "年齢",
          "1D6",
          [
            "【幼年】誕生から一桁代。",
            "【少年】十代真っ盛り。",
            "【青年】二十代から三十代。",
            "【壮年】三十代から五十代。",
            "【老年】六十代からそれ以上。",
            "【晩年】百歳またはそれ以上。",
          ]
        ),
      }.freeze

      register_prefix(TABLES.keys)
    end
  end
end
