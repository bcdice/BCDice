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
        y: 目標値（ 1 以上 6 以下。加算 + を使用可能）
        例） 3AT<=4, 3AT<=2+1

        □アタック判定　目標値＆追加ダメージつき（ xAT<=y[>=a:+b], xATK<=y[>=a:+b], xATTACK<=y[z] ）
        x: ダイス数（加算 + と除算 / を使用可能）
        y: 目標値（ 1 以上 6 以下。加算 + を使用可能）
        z: 追加ダメージの規則（詳細は後述）（※複数同時に指定可能）

        ▽追加ダメージの規則 [a:+b]
        a: ヒット数が a なら
        　=a　（ヒット数が a に等しい）
        　>=a　（ヒット数が a 以上）
        b: ダメージを b 点追加

        例） 3AT<=4[>=2:+3] #ルールブックp056「グレングラントAR」
        例） 2AT<=4[=1:+5][>=2:+8] #ルールブックp067「ファーボル・ドラゴンブレス」
      HELP

      ATTACK_ROLL_REG = %r{^(\d+([+/]\d+)*)?AT(TACK|K)?(<=([1-6](\+\d)*))?((\[>?=\d+:\+\d+\])+)?}i.freeze
      register_prefix('\d+([+\/]\d+)*AT')

      def eval_game_system_specific_command(command)
        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[1], m[5], m[7])
        end
      end

      private

      def roll_attack(dice_count_expression, border_expression, additional_damage_rules)
        dice_count = Arithmetic.eval(dice_count_expression, round_type: RoundType::FLOOR)
        border = Arithmetic.eval(border_expression, round_type: RoundType::FLOOR).clamp(1, 6) if border_expression

        command = make_command_text(dice_count, border, additional_damage_rules)

        if dice_count <= 0
          return "#{command} ＞ ダイス数が 0 です"
        elsif border.nil? && additional_damage_rules
          return "#{command} ＞ 目標値が指定されていないため、追加ダメージを算出できません"
        end

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        critical_hit_count = dices.count(1)
        hit_count = dices.count { |dice| dice <= border } + critical_hit_count if border
        damage = calc_damage(hit_count, additional_damage_rules)

        message_elements = []
        message_elements << command
        message_elements << dices.join(',')
        message_elements << "クリティカル #{critical_hit_count}" if critical_hit_count > 0
        message_elements << "ヒット数 #{hit_count}" if hit_count
        message_elements << "ダメージ #{damage}" if damage

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = hit_count > 0 if hit_count
          r.critical = critical_hit_count > 0
        end
      end

      def make_command_text(dice_count, border, additional_damage_rules)
        command = "#{dice_count}attack"
        command += "<=#{border}" if border
        command += additional_damage_rules if additional_damage_rules

        "(#{command})"
      end

      def calc_damage(hit_count, additional_damage_rules)
        return nil unless additional_damage_rules

        damage = hit_count
        parse_additional_damage_rules(additional_damage_rules).each do |rule|
          if rule[:condition].call(hit_count)
            damage += rule[:additinal_damage]
          end
        end

        damage
      end

      def parse_additional_damage_rules(source)
        source.scan(/\[(>?=)(\d+):\+(\d+)\]/).map do |matched|
          {
            condition: make_additional_damage_condition(matched[0], matched[1].to_i),
            additinal_damage: matched[2].to_i,
          }
        end
      end

      def make_additional_damage_condition(comparer, comparing_target)
        case comparer
        when '='
          lambda { |hit_count| hit_count == comparing_target }
        when '>='
          lambda { |hit_count| hit_count >= comparing_target }
        end
      end
    end
  end
end
