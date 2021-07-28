# frozen_string_literal: true

module BCDice
  module GameSystem
    class ToshiakiHolyGrailWar < Base
      # ゲームシステムの識別子
      ID = 'ToshiakiHolyGrailWar'
      # ゲームシステム名
      NAME = 'としあきの聖杯戦争TRPG'
      # ゲームシステム名の読みがな
      SORT_KEY = 'としあきのせいはいせんそうTRPG'
      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ■ 判定 (Fx+y-z@a>=t)
          補正値ペナルティを自動計算してダイスの面数を決定しダイスロールを実行します。
          ダイス面数は2以上、10以下の範囲に制限されます。
          x: ステータス
          y: 補正値 (任意)
          z: マイナス補正値 (任意)
          a: ダイス面数の増量 (任意)
          t: 目標値 (任意)
          例)
            F8+11, F8+11-5, F8+11-5@1, F8+11+9-3-2@-1, F8+11-5>=50, F8
      INFO_MESSAGE_TEXT

      register_prefix('F')

      def eval_game_system_specific_command(command)
        roll_f(command)
      end

      private

      def roll_f(command)
        parser = Command::Parser.new(/F(\d+)(\+\d+)*(-\d+)*/, round_type: RoundType::CEIL)
                                .disable_modifier
                                .enable_critical
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        m = cmd.command.match(/^F(\d+)((?:\+\d+)+)?((?:-\d+)+)?$/)
        unless m
          return nil
        end

        status = m[1].to_i
        positive_modifier = m[2] ? Arithmetic.eval(m[2], RoundType::CEIL) : 0
        negative_modifier = m[3] ? Arithmetic.eval(m[3], RoundType::CEIL) : 0
        side_bonus = cmd.critical || 0

        times = [status + positive_modifier + negative_modifier, 0].max
        sides = (6 - positive_modifier_penalty(positive_modifier) + negative_modifier_bonus(negative_modifier) + side_bonus).clamp(2, 10)

        list = @randomizer.roll_barabara(times, sides)
        total = list.sum()
        result =
          if cmd.cmp_op.nil?
            Result.new
          elsif total.send(cmd.cmp_op, cmd.target_number)
            Result.success("成功")
          else
            Result.failure("失敗")
          end

        sequence = [
          cmd,
          "(#{times}D#{sides}#{cmd.cmp_op}#{cmd.target_number})",
          "#{total}[#{list.join(',')}]",
          total,
          result.text,
        ].compact

        result.text = sequence.join(" ＞ ")
        return result
      end

      def positive_modifier_penalty(modifier)
        if modifier <= 10
          0
        else
          modifier / 10
        end
      end

      def negative_modifier_bonus(modifier)
        modifier <= -5 ? 1 : 0
      end
    end
  end
end
