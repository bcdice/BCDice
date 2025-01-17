# frozen_string_literal: true

require 'bcdice/command/parser'

module BCDice
  module GameSystem
    class Siren < Base
      # ゲームシステムの識別子
      ID = "Siren"

      # ゲームシステム名
      NAME = "終末アイドル育成TRPG セイレーン"

      # ゲームシステム名の読みがな
      SORT_KEY = "せいれえん"

      HELP_MESSAGE = <<~TEXT
        ・判定: SL+a<=b±c
          a=達成値への修正(0の場合は省略)
          b=能力値
          c=判定への修正(0の場合は省略、複数可)
        例)判定修正-10の装備を装着しながら【技術：60】〈兵器：2〉で判定する場合。
        SL+2<=60+40-10

        ・育成: TR$a<=b
          a=育成した回数
          b=ヘルス
        例）ヘルスの現在値が60で2回目の【身体】の育成を行う場合。
        TR$2<=60
      TEXT

      def eval_game_system_specific_command(command)
        case command
        when /^SL/ then check_action(command)
        when /^TR/ then check_training(command)
        else return nil
        end
      end

      def check_action(command)
        parser = Command::Parser.new('SL', round_type: @round_type).restrict_cmp_op_to(:<=)
        parsed = parser.parse(command)
        return nil if parsed.nil?

        target = parsed.target_number

        dice = @randomizer.roll_once(100)

        if dice > target
          return Result.failure("(1D100<=#{target}) ＞ #{dice} ＞ 失敗")
        end

        dig10 = dice / 10
        dig1 = dice % 10
        if dig10 == 0
          dig10 = 10
        end
        if dig1 == 0
          dig1 = 10
        end
        achievement_value = dig10 + dig1 + parsed.modify_number
        return Result.success("(1D100<=#{target}) ＞ #{dice} ＞ 成功(達成値：#{achievement_value})")
      end

      def check_training(command)
        parser = Command::Parser.new('TR', round_type: @round_type).restrict_cmp_op_to(:<=).enable_dollar.disable_modifier
        parsed = parser.parse(command)
        return nil if parsed.nil?

        count = parsed.dollar
        return nil if count.nil?

        target = parsed.target_number

        dice = @randomizer.roll_once(100)

        dig10 = dice / 10
        dig1 = dice % 10
        if dig10 == 0
          dig10 = 10
        end
        if dig1 == 0
          dig1 = 10
        end
        achievement_value = dig10 + dig1

        if dice > target
          return Result.failure("(1D100<=#{target}) ＞ #{dice} ＞ 失敗(能力値減少：10 / ヘルス減少：#{achievement_value})")
        end

        return Result.success("(1D100<=#{target}) ＞ #{dice} ＞ 成功(能力値上昇：#{count * 5 + achievement_value} / ヘルス減少：#{achievement_value})")
      end

      register_prefix('SL', 'TR')
    end
  end
end
