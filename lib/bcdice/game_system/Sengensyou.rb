# frozen_string_literal: true

module BCDice
  module GameSystem
    class Sengensyou < Base
      # ゲームシステムの識別子
      ID = 'Sengensyou'

      # ゲームシステム名
      NAME = '千幻抄'

      # ゲームシステム名の読みがな
      SORT_KEY = 'せんけんしよう'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・SGS　命中判定
      INFO_MESSAGE_TEXT

      register_prefix('SGS')

      def eval_game_system_specific_command(command)
        # 命中判定
        parser = Command::Parser.new('SGS', round_type: @round_type)
        command = parser.parse(command)

        unless command
          return nil
        end

        dice_list = @randomizer.roll_barabara(3, 6)
        dice_total = dice_list.sum()
        is_critical = dice_total >= 16
        is_fumble = dice_total <= 5
        additional_text =
          if is_critical
            "クリティカル"
          elsif is_fumble
            "ファンブル"
          end
        modify_text = "#{dice_total}#{Format.modifier(command.modify_number)}" if command.modify_number != 0
        sequence = [
          "(3D6#{Format.modifier(command.modify_number)})",
          "#{dice_total}[#{dice_list.join(',')}]",
          modify_text,
          (dice_total + command.modify_number).to_s,
          additional_text,
        ].compact

        result = Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          r.critical = is_critical
          r.fumble = is_fumble
        end
        return result
      end
    end
  end
end
