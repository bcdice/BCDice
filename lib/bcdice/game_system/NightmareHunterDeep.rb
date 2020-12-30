# frozen_string_literal: true

require "bcdice/command_parser"
require "bcdice/format"

module BCDice
  module GameSystem
    class NightmareHunterDeep < Base
      # ゲームシステムの識別子
      ID = 'NightmareHunterDeep'

      # ゲームシステム名
      NAME = 'ナイトメアハンター=ディープ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ないとめあはんたあていいふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        判定（xD6+y>=a, xD6+y, xD6)
          出目6の個数をカウントして、その4倍を合計値に加算します。
          また、宿命を獲得したか表示します。

          Lv目標値 (xD6+y>=LVn, xD6+y>=NLn)
            レベルで目標値を指定することができます。
            LVn -> n*5+1, NLn -> n*5+5 に変換されます。
          目標値'?' (xD6+y>=?)
            目標値を '?' にすると何Lv成功か、何NL成功かを表示します。

        ※判定コマンドは xD6 から始まる必要があります。また xD6 が複数あると反応しません。
      INFO_MESSAGE_TEXT

      register_prefix('\d+D6')

      def initialize(command)
        super(command)

        @sort_add_dice = true
      end

      def eval_game_system_specific_command(command)
        command = command
                  .sub(/Lv(\d+)/i) { (Regexp.last_match(1).to_i * 5 - 1).to_s }
                  .sub(/NL(\d+)/i) { (Regexp.last_match(1).to_i * 5 + 5).to_s }

        parser = Command::Parser.new(/\d+D6/, round_type: round_type)
                                .restrict_cmp_op_to(nil, :>=)
                                .enable_question_target()
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        times = cmd.command.to_i

        dice_list = @randomizer.roll_barabara(times, 6).sort
        dice_total = dice_list.sum()
        total = dice_total + cmd.modify_number

        suffix, revision = dice_revision(dice_list)
        total += revision

        target = cmd.question_target? ? "?" : cmd.target_number
        result = result_text(total, cmd.cmp_op, target)

        sequence = [
          "(#{cmd})",
          interim_expr(cmd, dice_total, dice_list),
          expr_with_revision(dice_total + cmd.modify_number, suffix),
          total,
          result,
          fate(dice_list),
        ].compact

        return sequence.join(" ＞ ")
      end

      def result_text(total, cmp_op, target)
        return nil unless cmp_op == :>=

        if target != "?"
          return total >= target ? "成功" : "失敗"
        end

        success_lv = (total + 1) / 5
        success_nl = (total - 5) / 5

        return success_lv > 0 ? "Lv#{success_lv}/NL#{success_nl}成功" : "失敗"
      end

      # ナイトメアハンターディープ用宿命表示
      def fate(dice_list)
        dice_list.count(1) > 0 ? "宿命獲得" : nil
      end

      def interim_expr(cmd, dice_total, dice_list)
        if dice_list.size > 1 || cmd.modify_number != 0
          modifier = Format.modifier(cmd.modify_number)
          "#{dice_total}[#{dice_list.join(',')}]#{modifier}"
        end
      end

      def expr_with_revision(total, suffix)
        suffix ? "#{total}#{suffix}" : nil
      end

      def dice_revision(dice_list)
        count6 = dice_list.count(6)
        if count6 > 0
          return "+#{count6}*4", count6 * 4
        else
          return nil, 0
        end
      end
    end
  end
end
