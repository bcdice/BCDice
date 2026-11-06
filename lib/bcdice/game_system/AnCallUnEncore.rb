# frozen_string_literal: true

module BCDice
  module GameSystem
    class AnCallUnEncore < Base
      # ゲームシステムの識別子
      ID = "AnCallUnEncore"

      # ゲームシステム名
      NAME = "An Call Un Encore TRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "あんこおるあんあんこおるTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (ACE<=判定値)
          d100を振り、判定値以下なら成功。
          出目が1〜10かつ判定値以下なら会心。
          出目が95〜100なら、判定値にかかわらず状況悪。

        ■ 有利 (ACE<=判定値A)
          d100を2回振り、低い方を採用する。
          2つとも会心なら、会心(効果2倍)。

        ■ 不利 (ACE<=判定値D)
          d100を2回振り、高い方を採用する。
          2つとも状況悪なら、状況悪(ペナルティ)。
      TEXT

      # 出目の境界
      CRITICAL_MAX = 10
      FUMBLE_MIN = 95

      register_prefix('ACE<=\d+(?:A|_?D)?')

      # BCDiceは「70D」のような入力を「70D6」に自動で読み替えるため、
      # 末尾のDを読み替えられない形(_D)にしてから処理する
      def change_text(string)
        string.sub(/\A(ACE<=\d+)D\z/i, '\1_D')
      end

      def eval_game_system_specific_command(command)
        m = /^ACE<=(\d+)(A|_?D)?$/i.match(command)
        return nil unless m

        target = m[1].to_i
        mode = m[2]&.upcase&.delete('_')

        return roll_check(target, mode)
      end

      private

      # 判定を行う
      #
      # @param target [Integer] 判定値
      # @param mode [String, nil] "A"(有利) / "D"(不利) / nil(通常)
      # @return [Result]
      def roll_check(target, mode)
        times = mode ? 2 : 1
        dice_list = @randomizer.roll_barabara(times, 100)

        value =
          case mode
          when "A" then dice_list.min
          when "D" then dice_list.max
          else dice_list.first
          end

        judge = judge_value(value, target)

        # 2回振ったとき、2つとも会心 / 2つとも状況悪かを調べる
        both = mode && dice_list.all? { |d| judge_value(d, target) == judge }

        header = "(1D100<=#{target}#{mode_label(mode)})"
        detail = mode ? "#{value}[#{dice_list.join(',')}]" : value.to_s

        return build_result(judge, both && mode == "A", both && mode == "D", header, detail)
      end

      # 出目を判定する
      #
      # @return [Symbol] :critical / :success / :failure / :fumble
      def judge_value(value, target)
        return :fumble if value >= FUMBLE_MIN
        return :critical if value <= CRITICAL_MAX && value <= target
        return :success if value <= target

        return :failure
      end

      def mode_label(mode)
        case mode
        when "A" then " 有利"
        when "D" then " 不利"
        else ""
        end
      end

      def build_result(judge, double_critical, double_fumble, header, detail)
        case judge
        when :critical
          label = double_critical ? "会心(効果2倍)" : "会心"
          Result.critical("#{header} ＞ #{detail} ＞ #{label}")
        when :success
          Result.success("#{header} ＞ #{detail} ＞ 成功")
        when :fumble
          label = double_fumble ? "状況悪(ペナルティ)" : "状況悪"
          Result.fumble("#{header} ＞ #{detail} ＞ #{label}")
        else
          Result.failure("#{header} ＞ #{detail} ＞ 失敗")
        end
      end
    end
  end
end
