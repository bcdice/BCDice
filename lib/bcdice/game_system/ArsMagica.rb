# frozen_string_literal: true

require "bcdice/normalize"
require "bcdice/format"

module BCDice
  module GameSystem
    class ArsMagica < Base
      # ゲームシステムの識別子
      ID = 'ArsMagica'

      # ゲームシステム名
      NAME = 'アルスマギカ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あるすまきか'

      # ダイスボットの使い方
      HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・ストレスダイス　(ArSx+y)
　"ArS(ボッチダイス)+(修正)"です。判定にも使えます。Rコマンド(1R10+y[m])に読替をします。
　ボッチダイスと修正は省略可能です。(ボッチダイスを省略すると1として扱います)
　botchダイスの0の数が2以上の時は、数えて表示します。
　（注意！） botchの判断が発生したときには、そのダイスを含めてロールした全てのダイスを[]の中に並べて表示します。
　例) (1R10[5]) ＞ 0[0,1,8,0,8,1] ＞ Botch!
　　最初の0が判断基準で、その右側5つがボッチダイスです。1*2,8*2,0*1なので1botchという訳です。
INFO_MESSAGE_TEXT

      setPrefixes(['ArS.*', '1R10.*'])

      def rollDiceCommand(string)
        unless parse_ars(string) || parse_1r10(string)
          return nil
        end

        diff = @target_numner || 0
        botch = @botch
        bonus = @modify_number
        crit_mul = 1
        total = 0
        cmp_op = @cmp_op

        die = @randomizer.roll_once(10) - 1
        output = "(#{expr()}) ＞ "

        if die == 0 # botch?
          count0 = 0
          dice_n = []

          botch.times do |_i|
            botch_die = @randomizer.roll_once(10) - 1
            count0 += 1 if botch_die == 0
            dice_n.push(botch_die)
          end

          dice_n = dice_n.sort if sortType != 0

          output += "0[#{die},#{dice_n.join(',')}]"

          if count0 != 0
            if count0 > 1
              output += " ＞ #{count0}Botch!"
            else
              output += " ＞ Botch!"
            end

            # Botchの時には目標値を使った判定はしない
            cmp_op = nil
          else
            if bonus > 0
              output += "+#{bonus} ＞ #{bonus}"
            elsif bonus < 0
              output += "#{bonus} ＞ #{bonus}"
            else
              output += " ＞ 0"
            end
            total = bonus
          end
        elsif die == 1 # Crit
          crit_dice = ""
          while die == 1
            crit_mul *= 2
            die = @randomizer.roll_once(10)
            crit_dice += "#{die},"
          end
          total = die * crit_mul
          crit_dice = crit_dice.sub(/,$/, '')
          output += total.to_s
          output += "[1,#{crit_dice}]"
          total += bonus
          if bonus > 0
            output += "+#{bonus} ＞ #{total}"
          elsif bonus < 0
            output += "#{bonus} ＞ #{total}"
          end
        else
          total = die + bonus
          if bonus > 0
            output += "#{die}+#{bonus} ＞ #{total}"
          elsif bonus < 0
            output += "#{die}#{bonus} ＞ #{total}"
          else
            output += total.to_s
          end
        end

        if cmp_op == :>=
          output += (total >= diff ? " ＞ 成功" : " ＞ 失敗")
        end

        return output.to_s
      end

      private

      def parse_ars(command)
        m = /^ArS(\d+)?((?:[+-]-?\d+)+)?(?:([>=]+)(\d+))?$/i.match(command)
        unless m
          return false
        end

        @botch = m[1]&.to_i || 1
        @modify_number = ArithmeticEvaluator.new.eval(m[2] || "")
        @cmp_op = Normalize.comparison_operator(m[3])
        @target_numner = m[4]&.to_i

        return true
      end

      def parse_1r10(command)
        m = /^1R10((?:[+-]-?\d+)+)?(?:\[(\d+)\])?(?:([>=]+)(\d+))?$/i.match(command)
        unless m
          return false
        end

        @modify_number = ArithmeticEvaluator.new.eval(m[1] || "")
        @botch = m[2]&.to_i || 1
        @cmp_op = Normalize.comparison_operator(m[3])
        @target_numner = m[4]&.to_i

        return true
      end

      def expr()
        modifier = Format.modifier(@modify_number)

        "1R10#{modifier}[#{@botch}]#{@cmp_op}#{@target_numner}"
      end
    end
  end
end
