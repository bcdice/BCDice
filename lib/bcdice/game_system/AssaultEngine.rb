# frozen_string_literal: true

module BCDice
  module GameSystem
    class AssaultEngine < Base
      # ゲームシステムの識別子
      ID = 'AssaultEngine'

      # ゲームシステム名
      NAME = 'アサルトエンジン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あさるとえんしん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定 AEt (t目標値)
            例: AE45 （目標値45）
        ・リロール nAEt (nロール前の値、t目標値)
            例: 76AE45 (目標値45で、76を振り直す)

        ・スワップ（t目標値） エネミーブックP11
            例: AES45 （目標値45、スワップ表示あり）
      MESSAGETEXT

      register_prefix('\d*AE')

      def initialize(command)
        super(command)
        @round_type = RoundType::FLOOR # 端数切り捨て
      end

      def eval_game_system_specific_command(command)
        cmd = Command::Parser.new(/AES?/, round_type: round_type).enable_prefix_number
                             .has_suffix_number.parse(command)
        return nil unless cmd

        target = cmd.suffix_number
        target = 99 if target >= 100

        if cmd.command.include?("AES") # SWAP初回
          total = @randomizer.roll_once(100) % 100 # 0-99
          swap = (total % 10) * 10 + (total / 10)
          r1 = judge(target, total)
          r2 = judge(target, swap)
          text = "(AES#{format00(target)}) ＞ #{r1.text} / スワップ#{r2.text}"
          return_result(r1, r2, text)
        elsif cmd.prefix_number.nil? # 初回ロール
          total = @randomizer.roll_once(100) % 100 # 0-99
          judge(target, total).tap do |r|
            r.text = "(AE#{format00(target)}) ＞ #{r.text}"
          end
        else # リロール
          now = cmd.prefix_number
          die = @randomizer.roll_once(10) % 10 # 0-9
          new1 = judge(target, (now / 10 * 10) + die)    # 1の位を振り直す
          new2 = judge(target, now % 10 + die * 10)      # 10の位を振り直す

          text = "(#{format00(now)}AE#{format00(target)}) ＞ #{die} ＞ #{new1.text} / #{new2.text}"
          return_result(new1, new2, text)
        end
      end

      def format00(dice)
        format("%02d", dice)
      end

      def return_result(result1, result2, text)
        if result1.critical? || result2.critical?
          Result.critical(text)
        elsif result1.success? || result2.success?
          Result.success(text)
        elsif result1.fumble? && result2.fumble?
          Result.fumble(text)
        else
          Result.failure(text)
        end
      end

      def judge(target, total)
        double = (total / 10) == (total % 10)
        total_text = format00(total)
        if total <= target
          double ? Result.critical("(#{total_text})クリティカル") : Result.success("(#{total_text})成功")
        else
          double ? Result.fumble("(#{total_text})ファンブル") : Result.failure("(#{total_text})失敗")
        end
      end
    end
  end
end
