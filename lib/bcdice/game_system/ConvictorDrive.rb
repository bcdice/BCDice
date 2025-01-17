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
        xCD@z>=y: x個の10面ダイスで目標値y（省略時5）、クリティカルラインz（省略時10）の判定を行う。
        SLT: 技能レベル表を振る
        DCT: 遅延イベント表を振る
      MESSAGETEXT

      TABLES = {
        "SLT" => DiceTable::Table.new(
          "技能ランク表",
          "2D10",
          [
            "ランク外",
            "E-",
            "E",
            "E+",
            "D-",
            "D",
            "D+",
            "C-",
            "C",
            "C+",
            "B-",
            "B",
            "B+",
            "A-",
            "A",
            "A+",
            "S-",
            "S",
            "S+",
          ]
        ),
        "DCT" => DiceTable::Table.new(
          "遅延イベント表",
          "1D10",
          [
            "状況遅延Ⅰ（全員の初期リソースを-1する）",
            "状況遅延Ⅱ（全員の初期リソースを-1する）",
            "状況遅延Ⅲ（全員の初期リソースを-2する）",
            "武装を許すⅠ（ボスの攻撃ダイスを+1dする）",
            "武装を許すⅡ（脅威度4以下のエネミーの攻撃ダイスを2体まで+1dする）",
            "武装を許すⅢ（脅威度3以下のエネミーの攻撃ダイスを1体+2dする）",
            "緊急出撃Ⅰ（ランダムなPCのHPを-1する）",
            "緊急出撃Ⅱ（ランダムなPCのHPを-1する）",
            "緊急出撃Ⅲ（ランダムなPC2人のHPを-1する）",
            "絶望（ダイスを二度振り、二つ適用する）",
          ]
        ),
      }.freeze

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix("[-+*0-9\(\)]*CD", TABLES.keys)

      def initialize(command)
        super(command)

        @sides_implicit_d = 10
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command Begin")

        return roll_command(command) || roll_tables(command, TABLES)
      end

      def roll_command(command)
        parser = Command::Parser.new('CD', round_type: round_type)
                                .has_prefix_number
                                .enable_critical
                                .restrict_cmp_op_to(:>=, nil)
        cmd = parser.parse(command)

        unless cmd
          return nil
        end

        dice_list = @randomizer.roll_barabara(cmd.prefix_number, 10)
        target_num = cmd.target_number || 5
        critical = cmd.critical&.clamp(target_num, 10) || 10
        succeed_num = dice_list.count { |x| x >= target_num }
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
