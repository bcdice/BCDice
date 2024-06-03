# frozen_string_literal: true

module BCDice
  module GameSystem
    class FinalFantasyXIV < Base
      # ゲームシステムの識別子
      ID = "FinalFantasyXIV"

      # ゲームシステム名
      NAME = "FINAL FANTSY XIV TTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "ふあいなるふあんたしい14TTRPG"

      HELP_MESSAGE = <<~TEXT
        ・アビリティ判定 nAB+m>=x
          d20のアビリティ判定を行う。ダイス数が指定された場合、大きい出目1個を採用する。
          n: ダイス数（省略時 1）
          m: 修正値（省略可）
          x: 目標値（省略可）
          基本効果のみ、ダイレクトヒット、クリティカルを自動判定。
          例）AB, AB+5, AB+5>=14, 2AB+5>=14
        ・行為判定 nDC+m>=x
          アビリティ判定と同様。
          失敗、成功を自動判定。
      TEXT

      register_prefix('\d*AB', '\d*DC')

      def eval_game_system_specific_command(command)
        return abirity_roll(command) || action_roll(command)
      end

      private

      def abirity_roll(command)
        parser = Command::Parser.new("AB", round_type: round_type)
                                .enable_prefix_number()
                                .restrict_cmp_op_to(:>=, nil)
        cmd = parser.parse(command)
        return nil unless cmd

        times = cmd.prefix_number || 1

        dice_list_full = @randomizer.roll_barabara(times, 20).sort
        dice_list_full_str = "[#{dice_list_full.join(',')}]" if times > 1

        dice_list = dice_list_full[-1, 1]
        dice_result = dice_list[0]

        total = dice_result + cmd.modify_number

        result =
          if dice_result == 20
            Result.critical("クリティカル")
          elsif cmd.cmp_op.nil?
            Result.new
          elsif total >= cmd.target_number
            Result.success("ダイレクトヒット")
          else
            Result.failure("基本効果のみ")
          end

        sequence = [
          "(#{cmd.to_s(:after_modify_number)})",
          dice_list_full_str,
          "#{dice_result}[#{dice_list.join(',')}]#{Format.modifier(cmd.modify_number)}",
          total,
          result.text
        ].compact

        result.text = sequence.join(" ＞ ")
        result
      end

      def action_roll(command)
        parser = Command::Parser.new("DC", round_type: round_type)
                                .enable_prefix_number()
                                .restrict_cmp_op_to(:>=, nil)
        cmd = parser.parse(command)
        return nil unless cmd

        times = cmd.prefix_number || 1

        dice_list_full = @randomizer.roll_barabara(times, 20).sort
        dice_list_full_str = "[#{dice_list_full.join(',')}]" if times > 1

        dice_list = dice_list_full[-1, 1]
        dice_result = dice_list[0]

        total = dice_result + cmd.modify_number

        result =
          if cmd.cmp_op.nil?
            Result.new
          elsif total >= cmd.target_number
            Result.success("成功")
          else
            Result.failure("失敗")
          end

        sequence = [
          "(#{cmd.to_s(:after_modify_number)})",
          dice_list_full_str,
          "#{dice_result}[#{dice_list.join(',')}]#{Format.modifier(cmd.modify_number)}",
          total,
          result.text
        ].compact

        result.text = sequence.join(" ＞ ")
        result
      end
    end
  end
end
