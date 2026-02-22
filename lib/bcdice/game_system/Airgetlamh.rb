# frozen_string_literal: true

module BCDice
  module GameSystem
    class Airgetlamh < Base
      # ゲームシステムの識別子
      ID = 'Airgetlamh'

      # ゲームシステム名
      NAME = '朱の孤塔のエアゲトラム'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あけのことうのえあけとらむ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        【Reg2.0『THE ANSWERER』～】
        ・調査判定（成功数を表示）：[n]AA[m]
        ・命中判定（ダメージ表示）：[n]AA[m]*p[+t][Cx]
        【～Reg1.1『昇華』】
        ・調査判定（成功数を表示）：[n]AL[m]
        ・命中判定（ダメージ表示）：[n]AL[m]*p
        ----------------------------------------
        []内のコマンドは省略可能。

        「n」でダイス数（攻撃回数）を指定。省略時は「2」。
        「m」で目標値を指定。省略時は「6」。
        「p」で威力を指定。「*」は「x」で代用可。
        「+t」でクリティカルトリガーを指定。省略可。
        「Cx」でクリティカル値を指定。省略時は「1」、最大値は「3」、「0」でクリティカル無し。

        攻撃力指定で命中判定となり、成功数ではなく、ダメージを結果表示します。
        クリティカルヒットの分だけ、自動で振り足し処理を行います。
        （ALコマンドではクリティカル処理を行いません）

        【書式例】
        ・AL → 2d10で目標値6の調査判定。
        ・5AA7*12 → 5d10で目標値7、威力12の命中判定。
        ・AA7x28+5 → 2d10で目標値7、威力28、クリティカルトリガー5の命中判定。
        ・9aa5*10C2 → 9d10で目標値5、威力10、クリティカル値2の命中判定。
        ・15AAx4c0 → 15d10で目標値6、威力4、クリティカル無しの命中判定。
      MESSAGETEXT

      register_prefix(
        '\d*A[AL]'
      )

      def initialize(command)
        super(command)
        @sort_add_dice = true # ダイスのソート有
      end

      def eval_game_system_specific_command(command)
        check_roll(command)
      end

      private

      def parse_check_roll(command)
        m = /(\d+)?A(A|L)(\d+)?(?:[X*](\d+)(?:\+(\d+))?)?(?:C(\d+))?$/i.match(command)
        unless m
          return nil
        end

        dice_count = m[1]&.to_i || 2
        target = m[3]&.to_i || 6
        damage = m[4].to_i
        critical_trigger = m[5].to_i
        critical_number = m[6]&.to_i || 1

        if m[2] == "L"
          critical_trigger = 0
          critical_number = 0
        elsif critical_number > 4
          critical_number = 3
        end

        return {
          dice_count: dice_count,
          target: target,
          damage: damage,
          critical_trigger: critical_trigger,
          critical_number: critical_number,
        }
      end

      def check_roll(command)
        parsed = parse_check_roll(command)
        unless parsed
          return nil
        end

        dice_count = parsed[:dice_count]
        target = parsed[:target]
        damage = parsed[:damage]
        critical_trigger = parsed[:critical_trigger]
        critical_number = parsed[:critical_number]

        total_success_count = 0
        total_critical_count = 0
        text = ""

        roll_count = dice_count

        while roll_count > 0
          dice_array = @randomizer.roll_barabara(roll_count, 10).sort
          dice_text = dice_array.join(",")

          success_count = dice_array.count { |i| i <= target }
          critical_count = dice_array.count { |i| i <= critical_number }

          total_success_count += success_count
          total_critical_count += critical_count

          text += "+" unless text.empty?
          text += "#{success_count}[#{dice_text}]"

          roll_count = critical_count
        end

        result = ""
        is_damage = (damage != 0)

        if is_damage
          total_damage = total_success_count * damage + total_critical_count * critical_trigger

          result += "(#{dice_count}D10\<\=#{target}) ＞ #{text} ＞ Hits：#{total_success_count}*#{damage}"
          result += " + Trigger：#{total_critical_count}*#{critical_trigger}" if critical_trigger > 0
          result += " ＞ #{total_damage}ダメージ"
        else
          result += "(#{dice_count}D10\<\=#{target}) ＞ #{text} ＞ 成功数：#{total_success_count}"
        end

        result += " / #{total_critical_count}クリティカル" if total_critical_count > 0

        return result
      end
    end
  end
end
