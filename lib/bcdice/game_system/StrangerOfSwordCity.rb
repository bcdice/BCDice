# frozen_string_literal: true

module BCDice
  module GameSystem
    class StrangerOfSwordCity < Base
      # ゲームシステムの識別子
      ID = 'StrangerOfSwordCity'

      # ゲームシステム名
      NAME = '剣の街の異邦人TRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'けんのまちのいほうしんTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定　xSR or xSRy or xSR+y or xSR-y or xSR+y>=z
        　x=ダイス数、y=修正値(省略可、±省略時は＋として扱う)、z=難易度(省略可)
        　判定時はクリティカル、ファンブルの自動判定を行います。
        ・通常のnD6ではクリティカル、ファンブルの自動判定は行いません。
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix('\d+SR')

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::NO_SORT
        @round_type = RoundType::FLOOR
      end

      def eval_game_system_specific_command(command)
        debug('eval_game_system_specific_command command', command)

        command = command.upcase

        result = checkRoll(command)
        return result unless result.empty?

        return result
      end

      def checkRoll(command)
        debug("checkRoll begin command", command)

        result = ''
        return result unless command =~ /^(\d+)SR([+\-]?\d+)?(>=(\d+))?$/i

        diceCount = Regexp.last_match(1).to_i
        modify = Regexp.last_match(2).to_i
        difficulty = Regexp.last_match(4).to_i if Regexp.last_match(4)

        diceList = @randomizer.roll_barabara(diceCount, 6).sort
        dice = diceList.sum()

        totalValue = (dice + modify)
        modifyText = getModifyText(modify)
        result += "(#{command}) ＞ #{dice}[#{diceList.join(',')}]#{modifyText} ＞ #{totalValue}"

        criticalResult = getCriticalResult(diceList)
        unless criticalResult.nil?
          result += " ＞ クリティカル(+#{criticalResult}D6)"
          return result
        end

        if isFumble(diceList, diceCount)
          result += ' ＞ ファンブル'
          return result
        end

        unless difficulty.nil?
          result += totalValue >= difficulty ? ' ＞ 成功' : ' ＞ 失敗'
        end

        return result
      end

      def getModifyText(modify)
        return "" if modify == 0
        return modify.to_s if modify < 0

        return "+#{modify}"
      end

      def getCriticalResult(diceList)
        dice6Count = diceList.select { |i| i == 6 }.size

        if dice6Count >= 2
          return dice6Count.to_s
        end

        return nil
      end

      def isFumble(diceList, diceCount)
        (diceList.select { |i| i == 1 }.size >= diceCount)
      end
    end
  end
end
