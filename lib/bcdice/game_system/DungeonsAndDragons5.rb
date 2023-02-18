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
        ・攻撃ロール　AT[x][>=t][y]
        　x：+-修正。省略可。
        　y:有利(A), 不利(D)。省略可。
        　t:敵のアーマークラス。>=を含めて省略可。
        　ファンブル／失敗／成功／クリティカル を自動判定。
        　例）AT AT>=10 AT+5>=18 AT-3>=16 ATA AT>=10A AT+3>=18A AT-3>=16 ATD AT>=10D AT+5>=18D AT-5>=16D

        ・能力値判定　AR[x][>=t][y]
        　攻撃ロールと同様。失敗／成功を自動判定。
        　例）AR AR>=10 AR+5>=18 AR-3>=16 ARA AR>=10A AR+3>=18A AR-3>=16 ARD AR>=10D AR+5>=18D AR-5>=16D

      INFO_MESSAGE_TEXT

      register_prefix('AT([+-]\d+)?(>=\d+)?[AD]?', 'AR([+-]\d+)?(>=\d+)?[AD]?')

      def initialize(command)
        super(command)

        @sort_barabara_dice = false # バラバラロール（Bコマンド）でソート無
      end

      def eval_game_system_specific_command(command)
        attack_roll(command) || ability_roll(command)
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
        m = /^AT([-+]\d+)?(>=(\d+))?([AD]?)/.match(command)
        unless m
          return nil
        end

        modify = m[1].to_i
        difficulty = m[3].to_i
        advantage = m[4]

        usedie = 0
        roll_die = ""

        dice_command = "AT#{number_with_sign_from_int(modify)}"
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end
        unless advantage.empty?
          dice_command += advantage.to_s
        end

        output = ["(#{dice_command})"]

        if advantage.empty?
          usedie = @randomizer.roll_once(20)
          roll_die = usedie
        else
          dice = @randomizer.roll_barabara(2, 20)
          roll_die = "[" + dice.join(",") + "]"
          if advantage == "A"
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
        elsif difficulty > 0
          if usedie + modify >= difficulty
            result.success = true
            output.push("成功")
          else
            output.push("失敗")
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")
          if result
            if difficulty > 0 || result.critical? || result.fumble?
              r.condition = result.success?
            end
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end

      def ability_roll(command)
        m = /^AR([-+]\d+)?(>=(\d+))?([AD]?)/.match(command)
        unless m
          return nil
        end

        modify = m[1].to_i
        difficulty = m[3].to_i
        advantage = m[4]

        usedie = 0
        roll_die = ""

        dice_command = "AR#{number_with_sign_from_int(modify)}"
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end
        unless advantage.empty?
          dice_command += advantage.to_s
        end

        output = ["(#{dice_command})"]

        if advantage.empty?
          usedie = @randomizer.roll_once(20)
          roll_die = usedie
        else
          dice = @randomizer.roll_barabara(2, 20)
          roll_die = "[" + dice.join(",") + "]"
          if advantage == "A"
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
        if difficulty > 0
          if usedie + modify >= difficulty
            result.success = true
            output.push("成功")
          else
            output.push("失敗")
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")
          if result
            if difficulty > 0
              r.condition = result.success?
            end
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end
    end
  end
end
