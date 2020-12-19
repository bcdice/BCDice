# frozen_string_literal: true

module BCDice
  module GameSystem
    class GoldenSkyStories < Base
      # ゲームシステムの識別子
      ID = 'GoldenSkyStories'

      # ゲームシステム名
      NAME = 'ゆうやけこやけ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ゆうやけこやけ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ※「ゆうやけこやけ」はダイスロールを使用しないシステムです。
        ※このダイスボットは部屋のシステム名表示用となります。

        ・下駄占い (GETA)
          あーしたてんきになーれ
      MESSAGETEXT

      register_prefix('geta')

      def initialize(command)
        super(command)
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
        dice = @randomizer.roll_once(7)

        # result << " あーしたてんきになーれっ ＞ [#{diceList.join(',')}] ＞ "
        result += "下駄占い ＞ "

        getaString = ''
        case dice
        when 1
          getaString = '裏：あめ'
        when 2
          getaString = '表：はれ'
        when 3
          getaString = '裏：あめ'
        when 4
          getaString = '表：はれ'
        when 5
          getaString = '裏：あめ'
        when 6
          getaString = '表：はれ'
        when 7
          getaString = '横：くもり'
        end

        result += getaString

        return result
      end
    end
  end
end
