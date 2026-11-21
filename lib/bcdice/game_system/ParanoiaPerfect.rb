# frozen_string_literal: true

module BCDice
  module GameSystem
    class ParanoiaPerfect < Base
      # ゲームシステムの識別子
      ID = 'ParanoiaPerfect'

      # ゲームシステム名
      NAME = 'パラノイア・パーフェクト エディション'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はらのいあはあふえくとえていしよん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ※コマンドは入力内容の前方一致で検出しています。
        ・通常の判定　NDx,y
        　x：ノードダイスの数.マイナスも可.
        　y: 反逆スターの数.省略可.省略時0
        　ノードダイスの絶対値 + 1個(コンピュータダイス)のダイスがロールされる.
        例）ND2　ND-3　ND2,1　ND-3,2
      INFO_MESSAGE_TEXT

      register_prefix('ND')

      def eval_game_system_specific_command(command)
        get_node_dice_roll(command)
      end

      private

      def generate_roll_results(traitorous_star, dices)
        computer_dice_message = ''
        results = dices.dup
        last_die = results[-1].to_i
        if last_die >= (6 - traitorous_star)
          results[-1] = "#{last_die}C"
          computer_dice_message = '(Computer)'
        end

        return results, computer_dice_message
      end

      def get_node_dice_roll(command)
        debug("eval_game_system_specific_command Begin")

        m = /^ND((-)?\d+)(,(\d+))?$/i.match(command)
        unless m
          return nil
        end

        debug("command", command)

        parameter_num = m[1].to_i
        traitorous_star = m[4].to_i
        dice_count = parameter_num.abs + 1

        dices = @randomizer.roll_barabara(dice_count, 6)

        success_rate = dices.count { |dice| dice >= 5 }
        success_rate -= dices.count { |dice| dice < 5 } if parameter_num < 0

        debug(dices)

        results, computer_dice_message = generate_roll_results(traitorous_star, dices)

        debug("eval_game_system_specific_command result")

        return "(#{command}) ＞ [#{results.join(', ')}] ＞ 成功度#{success_rate}#{computer_dice_message}"
      end
    end
  end
end
