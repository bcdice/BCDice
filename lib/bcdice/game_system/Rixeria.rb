# frozen_string_literal: true

module BCDice
  module GameSystem
    class Rixeria < Base
      ID = "Rixeria"

      NAME = "六理世界TRPG"

      SORT_KEY = "ろくりせかいTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 技能判定 (RIn[+m][>t])
          n：判定ダイス数
          m：技能レベルなどを合算した修正値
          t：目標値

          nD6を振り、その最高値に修正値を加えて達成値を算出する。
          判定ダイスは最低1D6。
          目標値を指定した場合、達成値が目標値を上回れば成功。
          達成値と目標値が同値以下なら失敗。
          6が2個以上ならクリティカル。
          全ての出目が1ならファンブル。

          例：
          RI4+3
          RI4+3>8
          RI2-1>6
          RI3

        ■ 戦闘技能判定 (RIBn[+m][>t])
          通常の技能判定に加え、失策を判定する。
          1が2個以上なら失策。
          ファンブル時は失策しない。
          クリティカルと失策の条件を同時に満たした場合、
          クリティカルを優先し、失策は発生しない。

          例：
          RIB4+3
          RIB4+3>8

        ■ 深理解放済み戦闘技能判定 (RIDn[+m][>t])
          深理を1つ以上解放しているキャラクター用。
          失策条件が「1が3個以上」に変更される。

          例：
          RID4+3
          RID4+3>8

        ■ 幸運判定 (LUn)
          n：幸運値（1～100）

          1D100を振り、出目が幸運値以下なら成功。
          幸運値を上回った場合は失敗。
          クリティカル・ファンブル・失策は発生しない。

          例：
          LU70
      TEXT

      register_prefix('RI','LU')

      def eval_game_system_specific_command(command)
        roll_ri(command)|| roll_lu(command)
      end

      private

      def roll_ri(command)
        m = /^RI([BD])?(\d+)([+-]\d+)?(?:>(\d+))?$/.match(command)
        return nil unless m

        mode = m[1]
        battle = !mode.nil?
        deep = mode == "D"

        dice_count = [m[2].to_i, 1].max
        modifier = m[3]&.to_i || 0
        target = m[4]&.to_i

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        highest = dice_list.max
        total = highest + modifier

        output = [
          "(#{command})",
          "[#{dice_list.join(',')}]",
          "最高値#{highest}#{format_modifier(modifier)}",
          "達成値#{total}",
        ]

        output << "目標値#{target}" unless target.nil?

        result = Result.new

        mishap_threshold = deep ? 3 : 2
        fumble = dice_list.all?(1)
        critical = dice_list.count(6) >= 2
        mishap = battle &&
                 !fumble &&
                 !critical &&
                 dice_list.count(1) >= mishap_threshold

        if fumble
          result.fumble = true
          result.failure = true unless target.nil?
          output << "ファンブル"
        elsif critical
          result.critical = true
          result.success = true unless target.nil?
          output << "クリティカル"
        else
          unless target.nil?
            if total > target
              result.success = true
              output << "成功"
            else
              result.failure = true
              output << "失敗"
            end
          end

          output << "失策" if mishap
        end

        result.text = output.join(" ＞ ")
        result
      end

        def roll_lu(command)
          m = /^LU(\d+)$/.match(command)
          return nil unless m

          luck = m[1].to_i
          return nil unless (1..100).cover?(luck)

          dice = @randomizer.roll_once(100)

          result = Result.new

          if dice <= luck
            result.success = true
            judgement = "成功"
          else
            result.failure = true
            judgement = "失敗"
          end

        result.text = "(#{command}) ＞ #{dice} ＞ #{judgement}"
        result
      end

      def format_modifier(modifier)
        return "" if modifier.zero?

        modifier.positive? ? "+#{modifier}" : modifier.to_s
      end
    end
  end
end