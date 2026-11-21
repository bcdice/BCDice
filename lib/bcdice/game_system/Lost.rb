# frozen_string_literal: true

module BCDice
  module GameSystem
    class Lost < Base
      # ゲームシステムの識別子
      ID = 'Lost'

      # ゲームシステム名
      NAME = '10_st'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ろすと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■ exp10_deX
        　特殊な10面ダイスをロールして、1の出目の数をカウントします。「a11_0ut」と「s10_th」を判定します。
        　X: ダイス数（省略時 1）

        ■ g01_denX
        　特殊な20面ダイスをロールして、「0_lation」かの判定をします。
        　X: ダイス数（省略時 1）
      INFO_MESSAGETEXT

      register_prefix('exp10_de', 'g01_den')

      def eval_game_system_specific_command(command)
        roll_explode(command) || roll_golden(command)
      end

      private

      def roll_explode(command)
        m = /^exp10_de([+\-\d]+)?$/i.match(command)
        unless m
          return nil
        end

        times = m[1] ? Arithmetic.eval(m[1], round_type: round_type) : 1
        if times.nil? || times <= 0
          return nil
        end

        values = @randomizer.roll_barabara(times, 10).map do |v|
          v <= 5 ? 1 : 0
        end

        is_allout = values.all? { |v| v == 1 }
        is_sloth = values.all? { |v| v == 0 }

        times_str = times > 1 ? times.to_i : ""

        if is_allout
          Result.success("(exp10_de#{times_str}) ＞ [#{values.join(',')}] ＞ a11_0ut")
        elsif is_sloth
          Result.failure("(exp10_de#{times_str}) ＞ [#{values.join(',')}] ＞ s10_th")
        else
          Result.new("(exp10_de#{times_str}) ＞ [#{values.join(',')}] ＞ #{values.count(1)}")
        end
      end

      def roll_golden(command)
        m = /^g01_den([+\-\d]+)?$/i.match(command)
        unless m
          return nil
        end

        times = m[1] ? Arithmetic.eval(m[1], round_type: round_type) : 1
        if times.nil? || times <= 0
          return nil
        end

        values = @randomizer.roll_barabara(times, 20).map do |v|
          v == 1 ? 1 : 0
        end

        is_olation = values.all? { |v| v == 0 }
        times_str = times > 1 ? times.to_i : ""

        if is_olation
          Result.failure("(g01_den#{times_str}) ＞ [#{values.join(',')}] ＞ 0_lation")
        else
          Result.new("(g01_den#{times_str}) ＞ [#{values.join(',')}]")
        end
      end
    end
  end
end
