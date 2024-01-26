# frozen_string_literal: true

module BCDice
  module GameSystem
    class BBN < Base
      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d+BN')

      ID = 'BBN'

      NAME = 'BBNTRPG'

      SORT_KEY = 'ひいひいえぬTRPG'

      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定(xBN±y>=z[c,f])
        　xD6の判定。クリティカル、ファンブルの自動判定を行います。
        　1Dのクリティカル値とファンブル値は1。2Dのクリティカル値とファンブル値は2。
        　nDのクリティカル値とファンブル値は n/2 の切り上げ。
        　クリティカルとファンブルが同時に発生した場合、クリティカルを優先。
        　x：xに振るダイス数を入力。
        　y：yに修正値を入力。省略可能。
          z：zに目標値を入力。省略可能。
          c：クリティカルに必要なダイス目「6」の数の増減。省略可能。
          f：ファンブルに必要なダイス目「1」の数の増減。省略可能。
        　例） 3BN+4　3BN>=8　3BN+1>=10[-1] 3BN+1>=10[,1] 3BN+1>=10[1,1]
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        unless parse(command)
          return nil
        end

        # ダイスロール
        dice_list = @randomizer.roll_barabara(@roll_times, 6)
        dice = dice_list.sum()
        dice_str = dice_list.join(",")

        total = dice + @modify

        # 出力文の生成
        sequence = [
          "(#{command})",
          "#{dice}[#{dice_str}]#{@modify_str}",
          total
        ]

        # クリティカルとファンブルが同時に発生した時にはクリティカルが優先
        if critical_?(dice_list)
          sequence.push("クリティカル！", *additional_roll(dice_list.count(6), total))
        elsif fumble_?(dice_list)
          sequence.push("ファンブル！")
        elsif @difficulty
          sequence.push(total >= @difficulty ? "成功" : "失敗")
        end

        return sequence.join(" ＞ ")
      end

      private

      # コマンド文字列をパースする
      #
      # @param command [String] コマンド
      # @return [Boolean] パースに成功したか
      def parse(command)
        m = /^(\d+)BN([+-]\d+)?(>=(([+-]?\d+)))?(\[([+-]?\d+)?(,([+-]?\d+))?\])?/.match(command)
        unless m
          return false
        end

        @roll_times = m[1].to_i
        @modify_str = m[2] || ''
        @modify = m[2].to_i
        @difficulty = m[4]&.to_i

        base = critical_base(@roll_times)
        @critical = base + m[7].to_i
        @fumble = base + m[9].to_i

        return true
      end

      # 振るダイスの数からクリティカルとファンブルの基本値を算出する
      #
      # @param roll_times [Integer] 振るダイスの数
      # @return [Integer] クリティカルの値
      def critical_base(roll_times)
        case roll_times
        when 1, 2
          roll_times
        else
          (roll_times.to_f / 2).ceil
        end
      end

      # @return [Boolean] クリティカルか
      def critical_?(dice_list)
        dice_list.count(6) >= @critical
      end

      # @return [Boolean] ファンブルか
      def fumble_?(dice_list)
        dice_list.count(1) >= @fumble
      end

      # クリティカルの追加ロールをする
      # 追加ロールで6が出た場合、さらに追加ロールが行われる
      #
      # @param additional_dice [Integer] クリティカルによる追加のダイス数
      # @param total [Integer] 現在の合計値
      # @return [Array<String>]
      def additional_roll(additional_dice, total)
        sequence = []
        reroll_count = 0

        # 追加クリティカルは無限ループしうるので、10回に制限
        while additional_dice > 0 && reroll_count < 10
          reroll_count += 1

          dice_list = @randomizer.roll_barabara(additional_dice, 6)
          dice_total = dice_list.sum()
          dice_str = dice_list.join(",")
          additional_dice = dice_list.count(6)

          sequence.push("#{total}+#{dice_total}[#{dice_str}]")
          sequence.push("追加クリティカル！") if additional_dice > 0

          total += dice_total
        end

        if additional_dice > 0
          sequence.push("無限ループ防止のため中断")
        end

        sequence.push total
        if @difficulty
          sequence.push(total >= @difficulty ? "成功" : "失敗")
        end

        return sequence
      end
    end
  end
end
