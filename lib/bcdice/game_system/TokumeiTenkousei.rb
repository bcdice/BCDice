# frozen_string_literal: true

module BCDice
  module GameSystem
    class TokumeiTenkousei < Base
      # ゲームシステムの識別子
      ID = 'TokumeiTenkousei'

      # ゲームシステム名
      NAME = '特命転攻生'

      # ゲームシステム名の読みがな
      SORT_KEY = 'とくめいてんこうせい'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ・判定 (xD6+y>=n)
        　ゾロ目での自動振り足し
        　1の出目に応じてEPPの獲得量を表示
        　目標値 "?" には未対応
      HELP

      def initialize
        super

        @sort_add_dice = true
      end

      register_prefix(['\d+D6.*'])

      def rollDiceCommand(command)
        parser = CommandParser.new(/^\d+D6$/)
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        times = cmd.command.to_i

        dice_list = @randomizer.roll_barabara(times, 6).sort
        @dice_list = [dice_list]
        while same_all_dice?(dice_list)
          dice_list = @randomizer.roll_barabara(times, 6).sort
          @dice_list.push(dice_list)
        end

        dice_list_flatten = @dice_list.flatten
        dice_total = dice_list_flatten.sum()
        count_one = dice_list_flatten.count(1)

        total = dice_total + cmd.modify_number

        result =
          if cmd.cmp_op
            total.send(cmd.cmp_op, cmd.target_number) ? "成功" : "失敗"
          end

        sequence = [
          "(#{cmd})",
          interim_expr(cmd, dice_total),
          total.to_s,
          result,
          epp(count_one)
        ].compact

        return sequence.join(" ＞ ")
      end

      # 出目が全て同じか
      def same_all_dice?(dice_list)
        dice_list.size > 1 && dice_list.uniq.size == 1
      end

      def interim_expr(cmd, dice_total)
        if @dice_list.flatten.size == 1 && cmd.modify_number == 0
          return nil
        end

        dice_list = @dice_list.map { |ds| "[#{ds.join(',')}]" }.join("")
        modifier = Format.modifier(cmd.modify_number)

        return [dice_total.to_s, dice_list, modifier].join("")
      end

      # エキストラパワーポイント獲得
      #
      # @return count_one [Integer]
      # @return [String, nil]
      def epp(count_one)
        if count_one > 0
          "#{count_one * 5}EPP獲得"
        end
      end
    end
  end
end
