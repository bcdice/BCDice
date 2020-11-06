# frozen_string_literal: true

module BCDice
  module GameSystem
    class Nssq < Base
      ID = "Nssq"
      NAME = "SRSじゃない世界樹の迷宮TRPG"
      SORT_KEY = "えすえすああるしやないせかいしゆのめいきゆうTRPG"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 判定 (xSQ±y)
          xD6の判定。3つ以上振ったとき、出目の高い2つを表示します。クリティカル、ファンブルも計算します。
          ±y: yに修正値を入力。±の計算に対応。省略可能。

        ■ ダメージロール (xDR(C)(+)y)
          xD6のダメージロール。クリティカルの自動判定を行います。Cを付けるとクリティカルアップ状態で計算できます。+を付けるとクリティカル時のダイスが8個になります。
          x: xに振るダイス数を入力。
          y: yに耐性を入力。
          例) 5DR3 5DRC4 5DRC+4

        ■ 回復ロール (xHRy)
          xD6の回復ロール。クリティカルが発生しません。
          x: xに振るダイス数を入力。
          y: yに耐性を入力。省略した場合3。
          例) 2HR 10HR2

        ■ 採取ロール (TC±z,SC±z,GC±z)
          ちょっと(T)、そこそこ(S)、がっつり(G)採取採掘伐採を行う。
          z: zに追加でロールする回数を入力。省略可能。
          例) TC SC+1 GC-1
      MESSAGETEXT

      register_prefix('\d+SQ[\+\-\d]*', '\d+DR(C)?(\+)?\d+', '(T|S|G)C.*', '\d+HR\d*')

      def eval_game_system_specific_command(command)
        # get～DiceCommandResultという名前のメソッドを集めて実行、
        # 結果がnil以外の場合それを返して終了。

        methodList = public_methods(false).select do |method|
          method.to_s =~ /\Aget.+DiceCommandResult\z/
        end

        methodList.each do |method|
          result = send(method, command)
          return result.strip unless result.nil?
        end

        return roll_sq(command) || heal_roll(command)
      end

      def roll_sq(command)
        m = /(\d+)SQ([\+\-\d]+)?/i.match(command)
        return nil unless m

        dice_count = m[1].to_i
        modifier = ArithmeticEvaluator.eval(m[2])

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        largest_two = dice_list.sort.reverse.take(2)
        total = largest_two.sum + modifier

        additional_result =
          if largest_two == [6, 6]
            " クリティカル！"
          elsif largest_two == [1, 1]
            " ファンブル！"
          end

        sequence = [
          "(#{command})",
          "[#{dice_list.join(',')}]#{Format.modifier(modifier)}",
          "#{total}[#{largest_two.join(',')}]#{additional_result}",
        ]

        return sequence.join(" ＞ ")
      end

      def getValue(text, defaultValue)
        return defaultValue if text.nil? || text.empty?

        ArithmeticEvaluator.eval(text)
      end

      def getDamegeRollDiceCommandResult(command)
        # ダメージロール
        return nil unless command =~ /(\d+)DR(C)?(\+)?(\d+)/i

        diceCount = Regexp.last_match(1).to_i
        criticalText = (Regexp.last_match(2) || '')
        plusText = (Regexp.last_match(3) || '')
        resist = Regexp.last_match(4).to_i

        # ダイスロール
        dice_str = @randomizer.roll_barabara(diceCount, 6).join(",")
        diceList = dice_str.split(/,/).collect { |i| i.to_i }.sort

        # 出力文の生成
        result = makeCommand(diceCount, diceList, dice_str, criticalText, plusText, resist)

        # クリティカルチェック
        # クリティカルアップ状態かどうかを判定
        if criticalText == ''
          if numCheck(diceList, 6) >= numCheck(diceList, 1) + 2
            result += "クリティカル！\n"
            result += criticalPlus(plusText, resist)
          end
        else
          if numCheck(diceList, 6) >= numCheck(diceList, 1) + 1
            result += "クリティカル！\n"
            result += criticalPlus(plusText, resist)
          end
        end

        return result
      end

      def heal_roll(command)
        m = /^(\d+)HR(\d+)?$/i.match(command)
        return nil unless m

        dice_count = m[1].to_i
        resist = m[2]&.to_i || 3

        dice_list = @randomizer.roll_barabara(dice_count, 6)

        return "(#{command}) ＞ [#{dice_list.join(',')}]#{resist} ＞ #{damage(dice_list, resist)}回復"
      end

      def makeCommand(diceCount, diceList, dice_str, criticalText, plusText, resist)
        # 出力用ダイスコマンドを生成
        command = "#{diceCount}DR" + criticalText + plusText + resist.to_s

        # 出力文の生成
        result = "(#{command}) ＞ [#{dice_str}]#{resist} ＞ "

        damage = damageCheck(diceList, resist)

        result += damage.to_s + "ダメージ "

        return result
      end

      def numCheck(diceList, num)
        return(diceList.select { |i| i == num }.size)
      end

      def damage(dice_list, resist)
        dice_list.count {|x| x > resist}
      end

      def damageCheck(diceList, resist)
        # ダメージ計算
        damage = diceList.select { |i| i > resist }.size

        return damage
      end

      def criticalPlus(plusText, resist)
        # クリティカル時に4つダイスを振るか8つダイスを振るか判定し、ダメージロール
        if plusText == ''
          diceCount = 4
        else
          diceCount = 8
        end
        dice_str = @randomizer.roll_barabara(diceCount, 6).join(",")
        diceList = dice_str.split(/,/).collect { |i| i.to_i }.sort

        result = makeCommand(diceCount, diceList, dice_str, '', '', resist)

        return result
      end

      def getCollectDiceCommandResult(command)
        # 採取表

        return nil unless command =~ /(T|S|G)C([\+\-\d]*)/i

        type = Regexp.last_match(1)
        modify = (Regexp.last_match(2) || 0).to_i

        # ああっと値の設定
        case type
        when "T"
          aattoParam = 3
        when "S"
          aattoParam = 4
        when "G"
          aattoParam = 5
        else
          return nil
        end
        if (aattoParam - 2 + modify) <= 0
          return nil
        end

        # ダイスロール
        i = 0
        result = ""
        while i < (aattoParam - 2 + modify)
          # ああっと値-2回が採集回数
          dice_list = @randomizer.roll_barabara(2, 6)
          dice = dice_list.sum
          dice_str = dice_list.join(",")

          # 出力用文の生成
          result += "(#{command}) ＞ #{dice}[#{dice_str}]: "

          # ！ああっと！の判定
          if (dice <= aattoParam) && (aattoParam - 2 > i)
            result += "！ああっと！"
          else
            result += "成功"
            if aattoParam - 2 <= i
              result += "（追加分）"
            end
          end
          result += "\n"
          i += 1
        end
        # 末尾の改行文字を削除
        result.chomp!

        return result
      end
    end
  end
end
