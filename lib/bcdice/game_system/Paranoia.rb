# frozen_string_literal: true

module BCDice
  module GameSystem
    class Paranoia < Base
      # ゲームシステムの識別子
      ID = 'Paranoia'

      # ゲームシステム名
      NAME = 'パラノイア'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はらのいあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ※「パラノイア」は完璧なゲームであるため特殊なダイスコマンドを必要としません。
        ※このダイスボットは部屋のシステム名表示用となります。
      MESSAGETEXT

      register_prefix(['geta'])

      def initialize
        super()
        @enabled_upcase_input = false
      end

      def eval_game_system_specific_command(command)
        debug('eval_game_system_specific_command command', command)

        result = ''

        case command
        when /geta/i
          result = getaRoll()
        end

        return nil if result.empty?

        return "#{command} ＞ #{result}"
      end

      def getaRoll()
        result = ""

        dice = @randomizer.roll_once(2)

        result += "幸福ですか？ ＞ "

        getaString = ''
        case dice
        when 1
          getaString = '幸福です'
        when 2
          getaString = '幸福ではありません'
        end

        result += getaString

        return result
      end
    end
  end
end
