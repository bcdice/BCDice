# frozen_string_literal: true

require 'bcdice/base'

module BCDice
  module GameSystem
    class ConvictorDrive < Base
      # ゲームシステムの識別子
      ID = 'ConvictorDrive'

      # ゲームシステム名
      NAME = 'コンヴィクター・ドライブ'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'こんういくたあとらいふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        xCD@z>=y x個の10面ダイスで目標値y、クリティカルラインzの判定を行う
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix("[-+*0-9\(\)]*CD")

      def initialize(command)
        super(command)

        @sides_implicit_d = 10
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command Begin")

        parser = Command::Parser.new('CD', round_type: round_type)
                                .has_prefix_number
                                .enable_critical
                                .restrict_cmp_op_to(:>=)
        cmd = parser.parse(command)

        unless cmd
          return nil
        end

        dice_list = @randomizer.roll_barabara(cmd.prefix_number, 10)
        critical = (cmd.critical || 10).clamp(cmd.target_number, 10)
        succeed_num = dice_list.count { |x| x >= cmd.target_number }
        critical_num = dice_list.count { |x| x >= critical }

        text = [
          cmd.to_s,
          dice_list.join(','),
          critical_num > 0 ? "クリティカル数#{critical_num}" : nil,
          "成功数#{succeed_num + critical_num}",
        ].compact.join(" ＞ ")

        return Result.new.tap do |r|
          r.success = succeed_num > 0
          r.critical = critical_num > 0
          r.text = text
        end
      end
    end
  end
end
