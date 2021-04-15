# frozen_string_literal: true

module BCDice
  module GameSystem
    class Fiasco < Base
      # ゲームシステムの識別子
      ID = 'Fiasco'

      # ゲームシステム名
      NAME = 'フィアスコ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふいあすこ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<INFO_MESSAGE_TEXT
  ・判定コマンド(FSx, WxBx)
    相関図・転落要素用(FSx)：相関図や転落要素のためにx個ダイスを振り、出目ごとに分類する
    黒白差分判定用(WxBx)  ：転落、残響のために白ダイス(W指定)と黒ダイス(B指定)で差分を求める
      ※ WとBは片方指定(Bx, Wx)、入替指定(WxBx,BxWx)可能
INFO_MESSAGE_TEXT

      register_prefix('FS', 'W', 'B')

      def eval_game_system_specific_command(command)
        roll_fs(command) || roll_white_black(command) || roll_white_black_single(command)
      end

      private

      # 6面ダイスを複数ダイスロールして、各面が出た個数をカウントする
      # @param command [String]
      # @return [String, nil]
      def roll_fs(command)
        m = /^FS(\d+)$/.match(command)
        unless m
          return nil
        end

        dice_count = m[1].to_i
        dice_list = @randomizer.roll_barabara(dice_count, 6)

        # 各出目の個数を数える
        bucket = [nil, 0, 0, 0, 0, 0, 0]
        dice_list.each do |val|
          bucket[val] += 1
        end

        # "n個" 表記にする
        bucket.map! { |count| translate("Fiasco.fs.count", count: count) }

        return "1 => #{bucket[1]}, 2 => #{bucket[2]}, 3 => #{bucket[3]}, 4 => #{bucket[4]}, 5 => #{bucket[5]}, 6 => #{bucket[6]}"
      end

      # 白か黒かの片方だけダイスロールする
      #
      # "W4", "B6" など
      # @param command [String]
      # @return [String, nil]
      def roll_white_black_single(command)
        m = /^([WB])(\d+)$/.match(command)
        unless m
          return nil
        end

        a = Side.new(color(m[1]), m[2].to_i)
        result = a.roll(@randomizer)

        return "#{result} ＞ #{a.color}#{a.total}"
      end

      # 白黒両方ダイスロールして、その差分を表示する
      # @param command [String]
      # @return [String, nil]
      def roll_white_black(command)
        m = /^([WB])(\d+)([WB])(\d+)$/.match(command)
        unless m
          return nil
        end

        case command
        when /^W\d+W\d+$/
          return "#{command}：#{translate('Fiasco.wb.duplicate_error.white')}"
        when /^B\d+B\d+$/
          return "#{command}：#{translate('Fiasco.wb.duplicate_error.black')}"
        end

        a = Side.new(color(m[1]), m[2].to_i)
        result_a = a.roll(@randomizer)

        b = Side.new(color(m[3]), m[4].to_i)
        result_b = b.roll(@randomizer)

        return "#{result_a} #{result_b} ＞ #{a.diff(b)}"
      end

      def color(c)
        c == "W" ? translate("Fiasco.white") : translate("Fiasco.black")
      end

      # 片方の色のダイスロールを抽象化したクラス
      class Side
        def initialize(color, count)
          @color = color
          @count = count
        end

        # @param randomizer [Randomizer]
        # @return [String]
        def roll(randomizer)
          @dice_list =
            if @count == 0
              [0]
            else
              randomizer.roll_barabara(@count, 6)
            end

          @total = @dice_list.sum()

          "#{@color}#{@total}[#{@dice_list.join(',')}]"
        end

        # もう一方の色との差分を求める
        # @param other [Side]
        # @return [String]
        def diff(other)
          if @total == other.total
            "0"
          elsif @total > other.total
            "#{@color}#{@total - other.total}"
          else
            "#{other.color}#{other.total - @total}"
          end
        end

        attr_reader :color, :total
      end
    end
  end
end
