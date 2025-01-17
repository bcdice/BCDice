# frozen_string_literal: true

module BCDice
  module GameSystem
    class BarnaKronika < Base
      # ゲームシステムの識別子
      ID = 'BarnaKronika'

      # ゲームシステム名
      NAME = 'バルナ・クロニカ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はるなくろにか'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・通常判定　nBK
        　ダイス数nで判定ロールを行います。
        　セット数が1以上の時はセット数も表示します。
        ・攻撃判定　nBA
        　ダイス数nで判定ロールを行い、攻撃値と命中部位も表示します。
        ・クリティカルコール　nBKCt　nBACt
        　判定コマンドの後ろに「Ct」を付けるとクリティカルコールです。
        　ダイス数n,コール数tで判定ロールを行います。
        　ダイス数nで判定ロールを行います。
        　セット数が1以上の時はセット数も表示し、攻撃判定の場合は命中部位も表示します。
      INFO_MESSAGE_TEXT

      register_prefix('\d+BK', '\d+BA', '\d+BKC', '\d+BAC', '\d+R6')

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @sort_barabara_dice = true
      end

      def replace_text(string)
        string = string.gsub(/(\d+)BKC(\d)/) { "#{Regexp.last_match(1)}R6[0,#{Regexp.last_match(2)}]" }
        string = string.gsub(/(\d+)BAC(\d)/) { "#{Regexp.last_match(1)}R6[1,#{Regexp.last_match(2)}]" }
        string = string.gsub(/(\d+)BK/) { "#{Regexp.last_match(1)}R6[0,0]" }
        string = string.gsub(/(\d+)BA/) { "#{Regexp.last_match(1)}R6[1,0]" }
        return string
      end

      def eval_game_system_specific_command(string)
        string = replace_text(string)

        return nil unless /(^|\s)S?((\d+)[rR]6(\[([,\d]+)\])?)(\s|$)/i =~ string

        string = Regexp.last_match(2)
        option = Regexp.last_match(5)
        dice_n = Regexp.last_match(3)
        dice_n ||= 1

        @isBattleMode = false # 0=判定モード, 1=戦闘モード
        criticalCallDice = 0 # 0=通常, 1〜6=クリティカルコール

        if option
          battleModeText, criticalCallDice = option.split(",").map(&:to_i)
          @isBattleMode = (battleModeText == 1)
        end

        debug("@isBattleMode", @isBattleMode)

        dice_str, suc, set, at_str = roll_barna_kronika(dice_n, criticalCallDice)

        output = "(#{string}) ＞ [#{dice_str}] ＞ "

        if @isBattleMode
          output += at_str
        else
          debug("suc", suc)
          if suc > 1
            output += "成功数#{suc}"
          else
            output += "失敗"
          end

          debug("set", set)
          output += ",セット#{set}" if set > 0
        end

        return output
      end

      def roll_barna_kronika(dice_n, criticalCallDice)
        dice_n = dice_n.to_i

        output = ''
        suc = 0
        set = 0
        at_str = ''
        diceCountList = [0, 0, 0, 0, 0, 0]

        dice_n.times do |_i|
          index = @randomizer.roll_index(6)
          diceCountList[index] += 1
          if diceCountList[index] > suc
            suc = diceCountList[index]
          end
        end

        6.times do |i|
          diceCount = diceCountList[i]

          next if diceCount == 0

          diceCount.times do |_j|
            output += "#{i + 1},"
          end

          if isCriticalCall(i, criticalCallDice)
            debug("isCriticalCall")
            at_str += getAttackStringWhenCriticalCall(i, diceCount)
          elsif isNomalAttack(criticalCallDice, diceCount)
            debug("isNomalAttack")
            at_str += getAttackStringWhenNomal(i, diceCount)
          end

          set += 1 if diceCount > 1
        end

        if criticalCallDice != 0
          c_cnt = diceCountList[criticalCallDice - 1]
          suc = c_cnt * 2

          if  c_cnt != 0
            set = 1
          else
            set = 0
          end
        end

        if @isBattleMode && (suc < 2)
          at_str = "失敗"
        end

        output = output.sub(/,$/, '')
        at_str = at_str.sub(/,$/, '')

        return output, suc, set, at_str
      end

      def isCriticalCall(index, criticalCallDice)
        return false unless @isBattleMode
        return false if criticalCallDice == 0

        return (criticalCallDice == (index + 1))
      end

      def isNomalAttack(criticalCallDice, diceCount)
        return false unless @isBattleMode
        return false if criticalCallDice != 0

        return (diceCount > 1)
      end

      def getAttackStringWhenCriticalCall(index, diceCount)
        hitLocation = getAttackHitLocation(index + 1)
        attackValue = (diceCount * 2)
        result = hitLocation + ":攻撃値#{attackValue},"
        return result
      end

      def getAttackStringWhenNomal(index, diceCount)
        hitLocation = getAttackHitLocation(index + 1)
        attackValue = diceCount
        result = hitLocation + ":攻撃値#{attackValue},"
        return result
      end

      # 命中部位表
      def getAttackHitLocation(num)
        table = [
          [1, '頭部'],
          [2, '右腕'],
          [3, '左腕'],
          [4, '右脚'],
          [5, '左脚'],
          [6, '胴体'],
        ]

        return get_table_by_number(num, table)
      end
    end
  end
end
