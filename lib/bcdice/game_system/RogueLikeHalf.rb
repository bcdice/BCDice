# frozen_string_literal: true

module BCDice
  module GameSystem
    class RogueLikeHalf < Base
      # ゲームシステムの識別子
      ID = 'RogueLikeHalf'

      # ゲームシステム名
      NAME = 'ローグライクハーフ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ろおくらいくはあふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　RH+x>=t        x:技量点 t:達成値(威力)

        例)RH+1>=5: ダイスを1個振って、技量点1,達成値5の結果を表示(クリティカル・ファンブルも表示)

        ■D33　D33+x        x:修正値

        例)D33: 3面ダイスを2個振って、その結果を表示。
      INFO_MESSAGETEXT

      register_prefix('RH', 'D33')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) ||
          resolute_d33(command)
      end

      private

      def with_symbol(number)
        if number == 0
          return "+0"
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      # 判定ロール
      # @param [String] command
      # @return [Result]
      def get_result_of_action(total, die, target)
        if die == 6
          return Result.critical("クリティカル")
        elsif die == 1
          return Result.fumble("ファンブル")
        elsif total >= target
          return Result.success("成功")
        else
          return Result.failure("失敗")
        end
      end

      def resolute_action(command)
        m = /RH([+-]\d)*(>=(\d+))?/.match(command)
        return nil unless m

        modify = m[1] ? Arithmetic.eval(m[1], @round_type) : 0
        target = m[3].to_i
        target = 4 if target == 0

        die = @randomizer.roll_once(6)
        die_text = die.to_s
        total = die + modify

        result = get_result_of_action(total, die, target)

        command_text = "(RH#{with_symbol(modify)}>=#{target})"
        sequence = [
          command_text,
          "[#{die_text}]#{with_symbol(modify)}",
          total,
          result.text,
        ].compact

        result.text = sequence.join(" ＞ ")

        return result
      end

      # D33ロール
      # @param [String] command
      # @return [Result]
      def resolute_d33(command)
        m = /D33([+-]\d+)*/.match(command)
        return nil unless m

        modify = m[1] ? Arithmetic.eval(m[1], @round_type) : 0

        dice = @randomizer.roll_barabara(2, 3)
        dice_text = dice.join("")
        dice_total = dice[0] * 3 + dice[1] + modify
        dice_total = 12 if dice_total > 12
        dice_total = 4 if dice_total < 4
        p = dice_total.divmod(3)
        if p[1] == 0
          p[0] = p[0] - 1
          p[1] = 3
        end
        total = p[0] * 10 + p[1]

        sequence = [
          "(#{command})",
          dice_text,
        ].compact

        if modify != 0
          sequence = [
            "(#{command})",
            "#{dice_text}#{with_symbol(modify)}",
            total,
          ].compact
        end

        return Result.new(sequence.join(" ＞ "))
      end
    end
  end
end
