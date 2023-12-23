# frozen_string_literal: true

module BCDice
  module GameSystem
    class Liminal < Base
      # ゲームシステムの識別子
      ID = 'Liminal'

      # ゲームシステム名
      NAME = 'リミナル'

      # ゲームシステム名の読みがな
      SORT_KEY = 'りみなる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■技能判定　LMx+b>=t+m   x:技能レベル b:ボーナス t:難易度 m:敵の技能レベル(対抗判定)

        例)LM2>=8:  技能レベル2,難易度8で技能判定し、その結果を表示。(クリティカル成功も表示)
           LM3+2>=9:技能レベル3,ボーナス+2,難易度9で技能判定し、その結果を表示。( 〃 )
           LM0>=8:  技能なし,難易度8で技能判定する。(難易度+2は自動的に足されます)

        ■イニシアティヴ判定　LIx+b>=t+m   x:認識力レベル b:ボーナス t:難易度 m:敵の認識力レベル
        例)LI2>=8+2:  認識力レベル2,難易度8,敵認識力レベル2で技能判定し、その結果を表示。
           LI0>=8+2:  認識力なし,難易度8,敵認識力レベル2で技能判定する。(難易度加算なし)
      INFO_MESSAGETEXT

      register_prefix('L[MI]\d[+\d]*>=[+\d]+')

      def eval_game_system_specific_command(command)
        resolute_action(command) || resolute_initiative(command)
      end

      private

      # 技能判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /LM(\d)([+\d]*)>=([+\d]+)/.match(command)
        return nil unless m

        skill_level = m[1].to_i
        bonus = ArithmeticEvaluator.eval(m[2])
        difficulty = ArithmeticEvaluator.eval(m[3])

        dice = @randomizer.roll_barabara(2, 6)
        dice_total = dice.sum
        total = dice_total + skill_level + bonus
        difficulty += 2 if skill_level == 0

        return Result.new.tap do |result|
          result.condition = (total >= difficulty)
          result.critical = (total >= difficulty + 5)
          if dice_total == 2
            result.fumble = true
            result.critical = false
            result.condition = false
          end

          sequence = [
            "(LM#{skill_level}#{with_symbol(bonus)}>=#{difficulty})",
            "#{dice_total}[#{dice.join(',')}]#{with_symbol(skill_level + bonus)}",
            total.to_s,
            if result.fumble?
              "1ゾロ"
            elsif result.critical?
              "クリティカル"
            else
              result.success? ? "成功" : "失敗"
            end
          ].compact

          result.text = sequence.join(" ＞ ")
        end
      end

      def with_symbol(number)
        if number == 0
          return "+0"
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      # イニシアティヴ判定
      # @param [String] command
      # @return [Result]
      def resolute_initiative(command)
        m = /LI(\d)([+\d]*)>=([+\d]+)/.match(command)
        return nil unless m

        skill_level = m[1].to_i
        bonus = ArithmeticEvaluator.eval(m[2])
        difficulty = ArithmeticEvaluator.eval(m[3])

        dice = @randomizer.roll_barabara(2, 6)
        dice_total = dice.sum
        total = dice_total + skill_level + bonus

        return Result.new.tap do |result|
          result.condition = (total >= difficulty)
          result.critical = (total >= difficulty + 5)
          if dice_total == 2
            result.fumble = true
            result.critical = false
            result.condition = false
          end

          sequence = [
            "(LI#{skill_level}#{with_symbol(bonus)}>=#{difficulty})",
            "#{dice_total}[#{dice.join(',')}]#{with_symbol(skill_level + bonus)}",
            total.to_s,
            if result.fumble?
              "1ゾロ"
            elsif result.critical?
              "クリティカル"
            else
              result.success? ? "成功" : "失敗"
            end
          ].compact

          result.text = sequence.join(" ＞ ")
        end
      end
    end
  end
end
