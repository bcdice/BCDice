# frozen_string_literal: true

module BCDice
  module GameSystem
    class TunnelsAndTrolls < Base
      # ゲームシステムの識別子
      ID = 'TunnelsAndTrolls'

      # ゲームシステム名
      NAME = 'トンネルズ＆トロールズ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'とんねるすあんととろおるす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定　(nD6+x>=nLV)
        失敗、成功、自動失敗の自動判定とゾロ目の振り足し経験値の自動計算を行います。
        SAVEの難易度を「レベル」で表記することが出来ます。
        例えば「2Lv」と書くと「25」に置換されます。
        判定時以外は悪意ダメージを表示します。
        バーサークとハイパーバーサーク用に専用コマンドが使えます。
        例）2D6+1>=1Lv
        　 (2D6+1>=20) ＞ 7[2,5]+1 ＞ 8 ＞ 失敗
        　判定時にはゾロ目を自動で振り足します。

        ・バーサークとハイパーバーサーク　(nBS+x or nHBS+x)
        　"(ダイス数)BS(修正値)"でバーサーク、"(ダイス数)HBS(修正値)"でハイパーバーサークでロールできます。
        　最初のダイスの読替は、個別の出目はそのままで表示。
        　下から２番目の出目をずらした分だけ合計にマイナス修正を追加して表示します。
      INFO_MESSAGE_TEXT

      register_prefix('\d+H?BS.*', '\d+R6.*', '\d+D\d+.+', '\dD6.*')

      def initialize(command)
        super(command)

        @sort_add_dice = true
      end

      private

      def replace_text(string)
        if /BS/i =~ string
          string = string.gsub(/(\d+)HBS([^\d\s][+\-\d]+)/i) { "#{Regexp.last_match(1)}R6#{Regexp.last_match(2)}[H]" }
          string = string.gsub(/(\d+)HBS/i) { "#{Regexp.last_match(1)}R6[H]" }
          string = string.gsub(/(\d+)BS([^\d\s][+\-\d]+)/i) { "#{Regexp.last_match(1)}R6#{Regexp.last_match(2)}" }
          string = string.gsub(/(\d+)BS/i) { "#{Regexp.last_match(1)}R6" }
        end

        return string
      end

      def eval_game_system_specific_command(string)
        if /^\d+D\d+/i.match?(string)
          return roll_action(string)
        end

        string = replace_text(string)
        debug('tandt_berserk string', string)

        output = "1"

        return output unless (m = /(^|\s)S?((\d+)[rR]6([+\-\d]*)(\[(\w+)\])?)(\s|$)/i.match(string))

        debug('tandt_berserk matched')

        string = m[2]
        dice_c = m[3].to_i
        bonus = 0
        bonus = ArithmeticEvaluator.eval(m[4]) if m[4]
        isHyperBerserk = false
        isHyperBerserk = true if m[5] && (m[6] =~ /[Hh]/)
        dice_arr = []
        dice_now = 0
        dice_str = ""
        isFirstLoop = true
        n_max = 0
        bonus2 = 0

        debug('isHyperBerserk', isHyperBerserk)

        # ２回目以降
        dice_arr.push(dice_c)

        loop do
          debug('loop dice_arr', dice_arr)
          dice_wk = dice_arr.shift

          debug('roll dice_wk d6', dice_wk)
          dice_list = @randomizer.roll_barabara(dice_wk, 6).sort
          rollTotal = dice_list.sum()
          rollDiceMaxCount = dice_list.count(6)

          if dice_wk >= 2 # ダイスが二個以上
            dice_num = dice_list

            diceType = 6

            dice_face = []
            diceType.times do |_i|
              dice_face.push(0)
            end

            dice_num.each do |dice_o|
              dice_face[dice_o - 1] += 1
            end

            dice_face.each do |dice_o|
              if dice_o >= 2
                dice_o += 1 if isHyperBerserk
                dice_arr.push(dice_o)
              end
            end

            if isFirstLoop && dice_arr.empty?
              min1 = 0
              min2 = 0

              diceType.times do |i|
                index = diceType - i - 1
                debug('diceType index', index)
                if dice_face[index] > 0
                  min2 = min1
                  min1 = index
                end
              end

              debug("min1, min2", min1, min2)
              bonus2 = -(min2 - min1)
              rollDiceMaxCount -= 1 if min2 == 5

              if isHyperBerserk
                dice_arr.push(3)
              else
                dice_arr.push(2)
              end
            end
          end

          dice_now += rollTotal
          dice_str += "][" if dice_str != ""
          dice_str += dice_list.join(",")
          n_max += rollDiceMaxCount
          isFirstLoop = false

          debug('loop last chek dice_arr', dice_arr)

          break if dice_arr.empty?
        end

        debug('loop breaked')

        debug('dice_now, bonus, bonus2', dice_now, bonus, bonus2)
        total_n = dice_now + bonus + bonus2

        dice_str = "[#{dice_str}]"
        output = "#{dice_now}#{dice_str}"

        if bonus2 < 0
          debug('bonus2', bonus2)
          output += bonus2.to_s
        end

        debug('bonus', bonus)
        if bonus > 0
          output += "+#{bonus}"
        elsif bonus < 0
          output += bonus.to_s
        end

        if output =~ /[^\d\[\]]+/
          output = "(#{string}) ＞ #{output} ＞ #{total_n}"
        else
          output = "(#{string}) ＞ #{total_n}"
        end

        output += " ＞ 悪意#{n_max}" if n_max > 0

        return output
      end

      def roll_action(command)
        command = command
                  .sub(/\d+LV$/i) { |level| level.to_i * 5 + 15 }

        parser = CommandParser.new(/^\d+D6$/)
                              .allow_cmp_op(nil, :>=)
                              .enable_question_target()
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        times = cmd.command.to_i
        roll_action_dice(times)
        total = @dice_total + cmd.modify_number

        target = cmd.question_target? ? "?" : cmd.target_number

        sequence = [
          "(#{cmd})",
          interim_expr(cmd, @dice_total),
          total.to_s,
          action_result(total, @dice_total, target),
          additional_result(@count_6)
        ].compact

        return sequence.join(" ＞ ")
      end

      def roll_action_dice(times)
        dice_list = @randomizer.roll_barabara(times, 6).sort
        @dice_list = [dice_list]
        while same_all_dice?(dice_list)
          dice_list = @randomizer.roll_barabara(times, 6).sort
          @dice_list.push(dice_list)
        end

        dice_list_flatten = @dice_list.flatten
        @dice_total = dice_list_flatten.sum()
        @count_6 = dice_list_flatten.count(6)
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

      def action_result(total, dice_total, target_number)
        if dice_total == 3
          "自動失敗"
        elsif target_number.nil?
          nil
        elsif target_number == "?"
          success_level(total, dice_total)
        elsif total >= target_number
          "成功 ＞ 経験値#{experience_point(target_number, dice_total)}"
        else
          "失敗"
        end
      end

      def success_level(total, dice_total)
        level = (total - 15) / 5
        if level <= 0
          "失敗 ＞ 経験値#{dice_total}"
        else
          "#{level}Lv成功 ＞ 経験値#{dice_total}"
        end
      end

      def experience_point(target_number, dice_total)
        ep = 1.0 * (target_number - 15) / 5 * dice_total

        if ep <= 0
          "0"
        elsif int?(ep)
          ep.to_i.to_s
        else
          format("%.1f", ep)
        end
      end

      def int?(v)
        v == v.to_i
      end

      def additional_result(count_6)
        if count_6 > 0
          "悪意#{count_6}"
        end
      end
    end
  end
end
