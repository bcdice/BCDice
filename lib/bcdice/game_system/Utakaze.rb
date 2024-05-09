# frozen_string_literal: true

module BCDice
  module GameSystem
    class Utakaze < Base
      # ゲームシステムの識別子
      ID = 'Utakaze'

      # ゲームシステム名
      NAME = 'ウタカゼ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'うたかせ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定ロール（nUK）
          n個のサイコロで行為判定ロール。ゾロ目の最大個数を成功レベルとして表示。nを省略すると2UK扱い。
          例）3UK ：サイコロ3個で行為判定
          例）UK  ：サイコロ2個で行為判定
        ・難易度付き行為判定ロール（nUK>=t）
          tに難易度を指定した行為判定ロール。
          成功レベルと難易度tを比べて成否を判定します。
          例）6UK>=3 ：サイコロ6個で行為判定して、成功レベル3が出れば成功。
        ・クリティカルコール付き行為判定ロール（nUK@c or nUKc）
          cに「龍のダイス目」を指定した行為判定ロール。
          ゾロ目ではなく、cと同じ値の出目数x2が成功レベルとなります。難易度の指定も可能です。
          例）3UK@5 ：龍のダイス「月」でクリティカルコール宣言したサイコロ3個の行為判定
         ・対抗判定ロール(nUR[@c], nUO[@c]) n:ダイス数 c:クリティカルコール
         　行為判定ロールと同様にロールするが、最期に成功レベルとセット数から求めたマジックナンバーが表示される。
         　マジックナンバーの大きいものが成功、同値は引き分け。
         　ダイスは18個まで対応。
      MESSAGETEXT

      register_prefix('\d*U[KRO]')

      def eval_game_system_specific_command(command)
        debug('eval_game_system_specific_command command', command)

        check_roll(command) ||
          opposed_roll(command)
      end

      private

      DRAGON_DICE_NAME = {
        1 => "風",
        2 => "雨",
        3 => "雲",
        4 => "影",
        5 => "月",
        6 => "歌"
      }.freeze

      def check_roll(command)
        m = /^(\d+)?UK(@?(\d))?(>=(\d+))?$/i.match(command)
        return nil unless m

        base = (m[1] || 2).to_i
        crit = m[3].to_i
        diff = m[5].to_i

        base = getValue(base)
        crit = getValue(crit)

        return nil if base < 1

        crit = 6 if crit > 6

        dice_list = @randomizer.roll_barabara(base, 6).sort
        result = get_roll_result(dice_list, crit, diff)

        sequence = [
          command,
          "(#{base}D6)",
          "[#{dice_list.join(',')}]",
          result.text
        ]
        result.text = sequence.join(" ＞ ")

        return result
      end

      def get_roll_result(diceList, crit, diff)
        success, maxnum, setCount = getSuccessInfo(diceList, crit)

        sequence = []

        if isDragonDice(crit)
          sequence.push("龍のダイス「#{DRAGON_DICE_NAME[crit]}」(#{crit})を使用")
        end

        if success
          sequence.push("成功レベル:#{maxnum} (#{setCount}セット)")
        else
          sequence.push("失敗")
          return Result.failure(sequence.join(" ＞ "))
        end

        if diff == 0
          return Result.success(sequence.join(" ＞ ")) # 難易度なしでも成功として扱う
        elsif maxnum >= diff
          sequence.push("成功")
          return Result.success(sequence.join(" ＞ "))
        else
          sequence.push("失敗")
          return Result.failure(sequence.join(" ＞ "))
        end
      end

      # 対抗判定
      def opposed_roll(command)
        m = /^(\d+)?U[R|O](@?(\d))?$/i.match(command)
        return nil unless m

        base = (m[1] || 2).to_i
        crit = m[3].to_i

        base = getValue(base)
        crit = getValue(crit)

        return nil if base < 1 || base > 18

        crit = 6 if crit > 6

        dice_list = @randomizer.roll_barabara(base, 6).sort
        result = get_opposed_roll_result(dice_list, crit)

        sequence = [
          command,
          "(#{base}D6)",
          "[#{dice_list.join(',')}]",
          result.text
        ]
        result.text = sequence.join(" ＞ ")

        return result
      end

      def get_opposed_roll_result(diceList, crit)
        success, maxnum, setCount = getSuccessInfo(diceList, crit)

        sequence = []

        if isDragonDice(crit)
          sequence.push("龍のダイス「#{DRAGON_DICE_NAME[crit]}」(#{crit})を使用")
        end

        if success
          sequence.push("成功レベル:#{maxnum} (#{setCount}セット)")
          sequence.push("(" + format("%#02d%#1d", maxnum, setCount) + ")")
          return Result.success(sequence.join(" ＞ ")) # 出力上は成功として扱う
        else
          sequence.push("(000)")
          return Result.failure(sequence.join(" ＞ "))
        end
      end

      def getSuccessInfo(diceList, crit)
        debug("checkSuccess diceList, crit", diceList, crit)

        diceCountHash = getDiceCountHash(diceList, crit)
        debug("diceCountHash", diceCountHash)

        maxnum = 0
        successDiceList = []
        countThreshold = (isDragonDice(crit) ? 1 : 2)

        diceCountHash.each do |dice, count|
          maxnum = count if count > maxnum
          successDiceList << dice if count >= countThreshold
        end

        debug("successDiceList", successDiceList)

        if successDiceList.size <= 0
          # 失敗：ゾロ目無し(全部違う)
          return false, 0, 0
        end

        # 竜のダイスの場合
        maxnum *= 2 if isDragonDice(crit)

        # 成功：ゾロ目あり
        return true, maxnum, successDiceList.size
      end

      # 各ダイスの個数を数えてHashにする
      def getDiceCountHash(dice_list, critical)
        dice_list
          .select { |dice| isNomalDice(critical) || dice == critical }
          .group_by(&:itself)
          .transform_values(&:size)
      end

      def isNomalDice(crit)
        !isDragonDice(crit)
      end

      def isDragonDice(crit)
        (crit != 0)
      end

      def getValue(number)
        return 0 if number > 100

        return number
      end
    end
  end
end
