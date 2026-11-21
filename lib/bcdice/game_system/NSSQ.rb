# frozen_string_literal: true

module BCDice
  module GameSystem
    class NSSQ < Base
      ID = "NSSQ"
      NAME = "SRSじゃない世界樹の迷宮TRPG"
      SORT_KEY = "えすああるえすしやないせかいしゆのめいきゆうTRPG"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 判定 (xSQ±y>=z)
          xD6の判定。3つ以上振ったとき、出目の高い2つを表示します。絶対成功、絶対失敗も計算します。
          2つのサイコロを使用して出目に1があった場合は、FPの獲得も表示します。3つ以上使用した場合は表示しません。
          ±y: yに修正値を入力。±の計算に対応。省略可能。
          z: 目標値。省略可能。

        ■ ダメージロール (xDR(C)(+)y)
          xD6のダメージロール。クリティカルヒットの自動判定を行います。Cを付けるとクリティカルアップ状態で計算できます。+を付けるとクリティカルヒット時のダイスが8個になります。
          x: xに振るダイス数を入力。
          y: yに耐性を入力。
          例) 5DR3 5DRC4 5DRC+4

        ■ 回復ロール (xHRy)
          xD6の回復ロール。クリティカルヒットが発生しません。
          x: xに振るダイス数を入力。
          y: yに耐性を入力。省略した場合3。
          例) 2HR 10HR2

        ■ 採集ロール (TC±z,SC±z,GC±z)
          少しだけ(T)、そこそこ(S)、ガッツリ(G)採取採掘伐採を行います。
          z: zに追加でロールする回数を入力。省略可能。
          例) TC SC+1 GC-1
      MESSAGETEXT

      register_prefix('\d+SQ[\+\-\d]*', '\d+DR(C)?(\+)?\d+', '[TSG]C', '\d+HR\d*')

      def eval_game_system_specific_command(command)
        roll_sq(command) || damage_roll(command) || heal_roll(command) || collecting_roll(command)
      end

      private

      # 判定
      def roll_sq(command)
        m = /(\d+)SQ([+\-\d]+)?(([>=]+)(\d+))?/i.match(command)
        return nil unless m

        dice_count = m[1].to_i
        modifier = ArithmeticEvaluator.eval(m[2])
        target = m[5]&.to_i

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        largest_two = dice_list.sort.reverse.take(2)
        total = largest_two.sum + modifier
        num_1 = dice_list.count(1)

        result =
          if largest_two == [6, 6]
            Result.critical(" ＞ 絶対成功！")
          elsif largest_two == [1, 1]
            Result.fumble(" ＞ 絶対失敗！")
          elsif target && total >= target
            Result.success(" ＞ 成功")
          elsif target && total < target
            Result.failure(" ＞ 失敗")
          else
            Result.new
          end

        # ダイス数が2個の場合は1の出目の数だけ【FP】を獲得できる
        fp_result = dice_count == 2 && num_1 >= 1 ? " (【FP】#{num_1}獲得)" : ""

        sequence = [
          "(#{command})",
          "[#{dice_list.join(',')}]#{Format.modifier(modifier)}",
          "#{total}[#{largest_two.join(',')}]#{result.text}#{fp_result}",
        ]

        result.text = sequence.join(" ＞ ")
        return result
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
        normal_damage = damage(dice_list, resist)

        result = "(#{command}) ＞ [#{dice_list.join(',')}]#{resist}"

        critical_target = critical_up ? 1 : 2

        if dice_list.count(6) - dice_list.count(1) >= critical_target
          result += critical_damage_roll(increase_critical_dice, resist, normal_damage)
          result = Result.critical(result)
        else
          result += " ＞ #{normal_damage}ダメージ"
          result = normal_damage > 0 ? Result.success(result) : Result.failure(result)
        end

        return result
      end

      def critical_damage_roll(increase_critical_dice, resist, normal_damage)
        dice_count = increase_critical_dice ? 8 : 4

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        critical_damage = damage(dice_list, resist)
        return " ＞ クリティカルヒット！ ＞ (#{dice_count}DR#{resist}) ＞ [#{dice_list.join(',')}]#{resist} ＞ #{normal_damage + critical_damage}ダメージ"
      end

      # 回復ロール
      def heal_roll(command)
        m = /^(\d+)HR(\d+)?$/i.match(command)
        return nil unless m

        dice_count = m[1].to_i
        resist = m[2]&.to_i || 3

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        heal_amount = damage(dice_list, resist)
        result_text = "(#{command}) ＞ [#{dice_list.join(',')}]#{resist} ＞ #{heal_amount}回復"

        return heal_amount > 0 ? Result.success(result_text) : Result.failure(result_text)
      end

      def damage(dice_list, resist)
        dice_list.count { |x| x > resist }
      end

      # 採取ロール
      def collecting_roll(command)
        m = /([TSG])C([+\-\d]+)?/i.match(command)
        return nil unless m

        type = m[1]
        modifier = ArithmeticEvaluator.eval(m[2])

        aatto_param =
          case type
          when "T"
            3
          when "S"
            4
          when "G"
            5
          end

        roll_times = aatto_param - 2 + modifier
        return nil if roll_times <= 0

        results = Array.new(roll_times) do |i|
          dice_list = @randomizer.roll_barabara(2, 6)
          dice = dice_list.sum()

          "(#{command}) ＞ #{dice}[#{dice_list.join(',')}]: #{result_collecting(i, dice, aatto_param)}"
        end

        results.join("\n")
      end

      def result_collecting(i, dice, aatto)
        if (dice <= aatto) && (aatto - 2 > i)
          "！ああっと！"
        elsif aatto - 2 <= i
          "成功（追加分）"
        else
          "成功"
        end
      end
    end
  end
end
