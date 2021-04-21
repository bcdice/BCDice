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

      def roll_attack(dice_count_expression, border_expression, additional_damage_rules)
        dice_count = Arithmetic.eval(dice_count_expression, round_type: RoundType::FLOOR)

        border = border_expression.nil? ? nil : Arithmetic.eval(border_expression, round_type: RoundType::FLOOR).clamp(1, 6)

        dices = dice_count > 0 ? @randomizer.roll_barabara(dice_count, 6).sort : []
        critical_hit_count = dices.count { |dice| dice == 1 }
        hit_count = dices.empty? || border.nil? ? nil : dices.count { |dice| dice <= border.to_i } + critical_hit_count
        damage = dices.empty? || additional_damage_rules.nil? ? nil : hit_count.to_i

        if !damage.nil? && !additional_damage_rules.nil?
          self.class.parse_additional_damage_rules(additional_damage_rules).each do |rule|
            if rule[:condition].call(hit_count)
              damage += rule[:additinal_damage]
            end
          end
        end

        message_elements = []
        message_elements << self.class.make_command_text(dice_count, border, additional_damage_rules)
        message_elements << dices.join(',') unless dices.empty?
        message_elements << 'ダイス数が 0 です' if dices.empty?
        message_elements << "クリティカル #{critical_hit_count}" if critical_hit_count > 0
        message_elements << "ヒット数 #{hit_count}" unless hit_count.nil?
        message_elements << "ダメージ #{damage}" unless damage.nil?

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.success = !hit_count.nil? && hit_count > 0
          r.failure = !hit_count.nil? && hit_count == 0
          r.critical = critical_hit_count > 0
        end
      end

      def self.make_command_text(dice_count, border, additional_damage_rules)
        elements = []
        elements << "#{dice_count}attack"
        elements << "<=#{border}" unless border.nil?
        elements << additional_damage_rules unless additional_damage_rules.nil?

        "(#{elements.join('')})"
      end

      def self.parse_additional_damage_rules(source)
        source.scan(/\[(>?=)(\d+):\+(\d+)\]/).map do |matched|
          {
            condition: make_additional_damage_condition(matched[0], matched[1].to_i),
            additinal_damage: matched[2].to_i,
          }
        end
      end

      def self.make_additional_damage_condition(comparer, comparing_target)
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
