# frozen_string_literal: true

module BCDice
  module GameSystem
    class DungeonsAndDragons5 < Base
      # ゲームシステムの識別子
      ID = 'DungeonsAndDragons5'

      # ゲームシステム名
      NAME = 'ダンジョンズ＆ドラゴンズ第5版'

      # ゲームシステム名の読みがな
      SORT_KEY = 'たんしよんすあんととらこんす5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・命中判定　[x]AC[PN](敵AC)
        　x：+-修正。省略可。
        　P:有利, N:不利。省略可。
        　ファンブル／失敗／成功／クリティカル を自動判定。
        　例）AC10 +5AC18 -3AC16 ACP10 +5ACP18 -3ACP16 ACN10 +5ACN18 -3ACN16
      INFO_MESSAGE_TEXT

      register_prefix('([+-]?\d+)?AC[PN]?\d+')

      def initialize(command)
        super(command)

        @sort_barabara_dice = false # バラバラロール（Bコマンド）でソート無
      end

      def eval_game_system_specific_command(command)
        attack_roll(command)
      end

      def number_with_sign_from_int(number)
        if number == 0
          return ""
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      def attack_roll(command)
        m = /^([-+]?\d+)?AC([PN]?)(\d+)(\s|$)/.match(command)
        unless m
          return nil
        end

        modify = m[1].to_i
        advantage = m[2]
        difficulty = m[3].to_i

        usedie = 0
        roll_die = ""
        output = ["(#{number_with_sign_from_int(modify)}AC#{advantage}#{difficulty})"]

        if advantage.empty?
          usedie = @randomizer.roll_once(20)
          roll_die = usedie
        else
          dice = @randomizer.roll_barabara(2, 20)
          roll_die = "[" + dice.join(",") + "]"
          if advantage == "P"
            usedie = dice.max
          else
            usedie = dice.min
          end
        end
        if modify != 0
          output.push("#{roll_die}#{number_with_sign_from_int(modify)}")
          output.push((usedie + modify).to_s)
        else
          unless advantage.empty?
            output.push(roll_die)
          end
          output.push(usedie.to_s)
        end

        result = Result.new
        if usedie == 20
          result.critical = true
          result.success = true
          output.push("クリティカル")
        elsif usedie == 1
          result.fumble = true
          output.push("ファンブル")
        elsif usedie + modify >= difficulty
          result.success = true
          output.push("成功")
        else
          output.push("失敗")
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")
          if result
            r.condition = result.success?
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end
    end
  end
end
