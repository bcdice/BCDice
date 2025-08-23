# frozen_string_literal: true

require "bcdice/game_system/Revulture"

module BCDice
  module GameSystem
    class Revulture_Korean < Revulture
      # ゲームシステムの識別子
      ID = 'Revulture:Korean'

      # ゲームシステム名
      NAME = '광쇄의 리벌처'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:광쇄의 리벌처'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■공격 판정（ xAT, xATK, xATTACK ）
        x: 주사위 수（덧셈 + 과 나눗셈 / 사용 가능）
        예시） 3AT, 4ATK, 5+6ATTACK, 15/2AT

        □공격 판정 목표값 포함（ xAT<=y, xATK<=y, xATTACK<=y ）
        x: 주사위 수（덧셈 + 과 나눗셈 / 사용 가능）
        y: 목표값（ 1 이상 6 이하. 덧셈 + 사용 가능）
        예시） 3AT<=4, 3AT<=2+1

        □공격 판정　목표값＆추가 대미지 포함（ xAT<=y[>=a:+b], xATK<=y[>=a:+b], xATTACK<=y[z] ）
        x: 주사위 수（덧셈 + 과 나눗셈 / 사용 가능）
        y: 목표값（ 1 이상 6 이하. 덧셈 + 사용 가능）
        z: 추가 대미지 규칙（자세한 내용은 후술）（※여러 개를 동시에 지정 가능）

        ▽추가 대미지 규칙 [a:+b]
        a: 히트 수가 a 라면
        　=a　（히트 수가 a와 동일）
        　>=a　（히트 수가 a 이상）
        b: 대미지를 b 점 추가

        예시） 3AT<=4[>=2:+3] #ルールブックp056「グレングラントAR」
        예시） 2AT<=4[=1:+5][>=2:+8] #ルールブックp067「ファーボル・ドラゴンブレス」
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
        dice_count = Arithmetic.eval(dice_count_expression, RoundType::FLOOR)
        border = Arithmetic.eval(border_expression, RoundType::FLOOR).clamp(1, 6) if border_expression

        command = make_command_text(dice_count, border, additional_damage_rules)

        if dice_count <= 0
          return "#{command} ＞ 주사위가 0개 입니다."
        elsif border.nil? && additional_damage_rules
          return "#{command} ＞ 목표값이 지정되지 않아 추가 대미지를 계산할 수 없습니다."
        end

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        critical_hit_count = dices.count(1)
        hit_count = dices.count { |dice| dice <= border } + critical_hit_count if border
        damage = calc_damage(hit_count, additional_damage_rules)

        message_elements = []
        message_elements << command
        message_elements << dices.join(',')
        message_elements << "크리티컬 #{critical_hit_count}" if critical_hit_count > 0
        message_elements << "히트 수 #{hit_count}" if hit_count
        message_elements << "대미지 #{damage}" if damage

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
