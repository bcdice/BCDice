# frozen_string_literal: true

module BCDice
  module GameSystem
    class RuneQuestRoleplayingInGlorantha < Base
      # ゲームシステムの識別子
      ID = 'RuneQuestRoleplayingInGlorantha'

      # ゲームシステム名
      NAME = 'RuneQuest：Roleplaying in Glorantha'

      # ゲームシステム名の読みがな
      SORT_KEY = 'るうんくえすと4'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定コマンド クリティカル、スペシャル、ファンブルを含めた判定を行う。
        RQG<=成功率

        例1：RQG<=80 （技能値80で判定）
        例2：RQG<=80+20 （技能値100で判定）

        ・抵抗判定コマンド（能動-受動） クリティカル、スペシャル、ファンブルを含めた判定を行う。
        RES(能動能力-受動能力)m増強値
        増強値は省略可能。

        例1：RES(9-11)    (能動能力9 vs 受動能力11で判定)
        例2：RES(9-11)m20 (能動能力9 vs 受動能力11、+20%の増強が能動側に入る判定)
        例3：RES(9)m50    (能動能力と受動能力の差が9で、+50%の増強が能動側に入る判定)

        ・抵抗判定コマンド(能動側のみ) クリティカル、スペシャル、ファンブルは含めず判定を行う。
        RSA(能動能力)m増強値
        増強値は省略可能。

        例1：RSA(9)       (能動能力9で判定)
        例2：RSA(9)m20    (能動能力9で判定、+20%の増強が能動側に入る判定)

      MESSAGETEXT

      register_prefix('RQG', 'RES', 'RSA')

      def eval_game_system_specific_command(command)
        case command
        when /RQG/i
          return do_ability_roll(command)
        when /RES/i
          return do_resistance_roll(command)
        when /RSA/i
          return do_resistance_active_characteristic_roll(command)
        end
        return nil
      end

      private

      # 技能などの一般判定
      def do_ability_roll(command)
        m = %r{\A(RQG)(<=([+-/*\d]+))?$}.match(command)
        unless m
          return nil
        end

        roll_value = @randomizer.roll_once(100)
        unless m[3]
          # RQGのみ指定された場合は1d100を振ったのと同じ挙動
          return "(1D100) ＞ #{roll_value}"
        end

        ability_value = Arithmetic.eval(m[3], RoundType::ROUND)
        result_prefix_str = "(1D100<=#{ability_value}) ＞"

        if ability_value == 0
          # 0%は判定なしで失敗
          return Result.failure("#{result_prefix_str} 失敗")
        end

        result_str = "#{result_prefix_str} #{roll_value} ＞"

        # 判定
        get_roll_result(result_str, ability_value, roll_value)
      end

      # 抵抗判定
      def do_resistance_roll(command)
        m = %r{\A(RES)([+-/*\d]+)(M([+-/*\d]+))?$}.match(command)
        unless m
          return nil
        end

        unless m[2]
          return nil
        end

        difference_value = Arithmetic.eval(m[2], RoundType::ROUND)
        difference_value = -10 if difference_value < -10

        resistance_velue = 50 + (difference_value * 5)
        resistance_velue += Arithmetic.eval(m[4], RoundType::ROUND) if m[4]

        roll_value = @randomizer.roll_once(100)
        result_str = "(1D100<=#{resistance_velue}) ＞ #{roll_value} ＞"

        # 判定
        get_roll_result(result_str, resistance_velue, roll_value)
      end

      # 能動側のみの対抗判定
      def do_resistance_active_characteristic_roll(command)
        m = %r{\A(RSA)(\d+)(M([+-/*\d]+))?$}.match(command)
        unless m
          return nil
        end

        unless m[2]
          return nil
        end

        active_ability_value = m[2].to_i
        if active_ability_value == 0
          return "0は指定できません。"
        end

        modifiy_value = m[4] ? Arithmetic.eval(m[4], RoundType::ROUND) : 0
        roll_value = @randomizer.roll_once(100)
        active_value = active_ability_value * 5 + modifiy_value
        result_prefix_str = "(1D100<=#{active_value}) ＞ #{roll_value} ＞"

        note_str = "クリティカル/スペシャル、ファンブルは未処理。必要なら確認すること。"

        if roll_value >= 96
          # 96-99は無条件で失敗
          Result.failure("#{result_prefix_str} 失敗\n#{note_str}")
        elsif roll_value <= 5 || roll_value <= modifiy_value
          # 02-05あるいは修正値以下は無条件で成功
          Result.success("#{result_prefix_str} 成功\n#{note_str}")
        else
          # 上記全てが当てはまらない時に突破可能な能力値を算出
          "#{result_prefix_str} 相手側能力値#{active_ability_value + (50 + modifiy_value - roll_value) / 5}まで成功\n#{note_str}"
        end
      end

      # 判定結果の取得
      def get_roll_result(result_str, success_value, roll_value)
        critical_value = (success_value.to_f / 20).round
        special_value = (success_value.to_f / 5).round
        funmble_value = ((100 - success_value.to_f) / 20).round

        if (roll_value == 1) || (roll_value <= critical_value)
          # クリティカル(01は必ずクリティカル)
          Result.critical("#{result_str} クリティカル/スペシャル")
        elsif (roll_value == 100) || (roll_value >= (100 - funmble_value + 1))
          # ファンブル(00は必ずファンブル)
          Result.fumble("#{result_str} ファンブル")
        elsif roll_value <= special_value
          # スペシャル
          Result.success("#{result_str} スペシャル")
        elsif (roll_value <= 95) && ((roll_value <= 5) || (roll_value <= success_value))
          # 成功(02-05は必ず成功で、96-99は必ず失敗)
          Result.success("#{result_str} 成功")
        else
          # 失敗
          Result.failure("#{result_str} 失敗")
        end
      end
    end
  end
end
