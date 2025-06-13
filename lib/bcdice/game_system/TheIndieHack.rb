# frozen_string_literal: true

module BCDice
  module GameSystem
    class TheIndieHack < Base
      # ゲームシステムの識別子
      ID = 'TheIndieHack'

      # ゲームシステム名
      NAME = 'The Indie Hack'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しいんていはつく'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　cIH+a        c:CL  a:能力値

        例)IH: ライトダイスとダークダイスを1個ずつ振って、その結果を表示
      INFO_MESSAGETEXT

      register_prefix('([+-]?\d)?IH')

      def eval_game_system_specific_command(command)
        resolute_action(command)
      end

      private

      # ダイス判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /([+-]?\d)?IH([+-]\d)?/.match(command)
        return nil unless m

        cl = m[1].to_i
        abilities = m[2].to_i

        dices = @randomizer.roll_barabara(2, 6)
        dice_text = dices.join(",")
        dices[0] += cl
        dices[1] += abilities
        dice_text2 = dices.join(",")
        diff = dices[1] - dices[0]
        side = diff < 0 ? "ライト" : "ダーク"
        side = "両" if diff == 0
        if dice_text == dice_text2
          output = "(IH) ＞ #{dice_text} ＞ #{side}#{get_success_level(diff)}"
        else
          output = "(#{m[1]}IH#{m[2]}) ＞ [#{dice_text}] ＞ #{dice_text2} ＞ #{side}#{get_success_level(diff)}"
        end
        if diff > 0
          return Result.success(output)
        elsif diff < 0
          return Result.failure(output)
        else
          return Result.new.tap do |result|
            result.text = output
          end
        end
      end

      def get_success_level(die_difference)
        case die_difference.abs
        when 0
          return "陣営がそれぞれ確定描写を1つ追加します"
        when 1
          return "陣営が確定描写を1つ追加しますが、味方によって追加されたネガティブな確定描写を1つ受けます"
        when 2
          return "陣営が確定描写を1つ追加します"
        when 3
          return "陣営が確定描写を1つ追加し、さらに場面描写を1つ追加します"
        when 4
          return "陣営が確定描写を1つ追加し、さらにその陣営の味方ひとりも確定描写を1つ追加します"
        else
          return "陣営が確定描写を2つ追加します"
        end
      end
    end
  end
end
