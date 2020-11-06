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

        return roll_sq(command) || damage_roll(command) || heal_roll(command)
      end

      # 判定
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

      # ダメージロール
      def damage_roll(command)
        m = /(\d+)DR(C)?(\+)?(\d+)/i.match(command)
        return nil unless m

        dice_count = m[1].to_i
        critical_up = !m[2].nil? # 強化効果 クリティカルアップ
        increase_critical_dice = !m[3].nil?
        resist = m[4].to_i

        dice_list = @randomizer.roll_barabara(dice_count, 6)

        result = "(#{command}) ＞ [#{dice_list.join(',')}]#{resist} ＞ #{damage(dice_list, resist)}ダメージ"

        critical_target = critical_up ? 1 : 2

        if dice_list.count(6) - dice_list.count(1) >= critical_target
          result += " クリティカル！\n"
          result += additional_damage_roll(increase_critical_dice, resist)
        end

        return result
      end

      def additional_damage_roll(increase_critical_dice, resist)
        dice_count = increase_critical_dice ? 8 : 4

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        "(#{dice_count}DR#{resist}) ＞ [#{dice_list.join(',')}]#{resist} ＞ #{damage(dice_list, resist)}ダメージ"
      end

      def heal_roll(command)
        m = /^(\d+)HR(\d+)?$/i.match(command)
        return nil unless m

        dice_count = m[1].to_i
        resist = m[2]&.to_i || 3

        dice_list = @randomizer.roll_barabara(dice_count, 6)

        return "(#{command}) ＞ [#{dice_list.join(',')}]#{resist} ＞ #{damage(dice_list, resist)}回復"
      end

      def damage(dice_list, resist)
        dice_list.count {|x| x > resist}
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
