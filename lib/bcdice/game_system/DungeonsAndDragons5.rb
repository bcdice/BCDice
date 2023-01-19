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
        ・命中判定　[x]AC(敵AC)
        　x：有利(+)・不利(-)。省略可。
        　ファンブル／失敗／成功／クリティカル を自動判定。
        　例）AC10 +AC18 -AC16
      INFO_MESSAGE_TEXT

      register_prefix('[+-]?AC\d+')

      def initialize(command)
        super(command)

        @sort_barabara_dice = false # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        attack_roll(command)
      end

      def attack_roll(command)
        m = /^([-+]?)AC(\d+)(\s|$)/.match(command)
        unless m
          return nil
        end

        advantage = m[1]
        difficulty = m[2]&.to_i

        usedie = 0
        output = ["(#{advantage}AC#{difficulty})"]

        if advantage.empty?
          usedie = @randomizer.roll_once(20)
        else
          dices = @randomizer.roll_barabara(2, 20)
          output.push(dices.join(","))
          if advantage == "+"
            usedie = dices.max
          else
            usedie = dices.min
          end
        end
        output.push(usedie)

        result = Result.new
        if usedie == 20
          result.critical = true
          result.success = true
          output.push("クリティカル")
        elsif usedie == 1
          result.fumble = true
          output.push("ファンブル")
        elsif usedie >= difficulty
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
