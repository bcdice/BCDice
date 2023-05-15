# frozen_string_literal: true

require 'bcdice/base'

module BCDice
  module GameSystem
    class Ventangle < Base
      # ゲームシステムの識別子
      ID = 'Ventangle'

      # ゲームシステム名
      NAME = 'Ventangle'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'うえんたんくる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        基本書式 VTn@s#f$g>=T n=ダイス数（省略時2） s=スペシャル値（省略時12） f=ファンブル値（省略時2） g=レベルギャップ判定値（省略可） T=目標値（省略可）

        例：
        VT        デフォルトのスペシャル値・ファンブル値の判定を行う
        VT@10#3   スペシャル値10、ファンブル値3の判定を行う
        VT3@10#3  スペシャル値10、ファンブル値3の判定を、アドバンテージを1点消費してダイス3つで行う

        VT>=5         デフォルトのスペシャル値・ファンブル値で目標値5の判定を行う
        VT@10#3>=5    スペシャル値10、ファンブル値3で目標値5の判定を行う
        VT@10#3$5>=5  スペシャル値10、ファンブル値3で目標値5の判定を行う。この際達成値が目標値より5以上大きい場合、ギャップボーナスを表示する
        VT3@10#3>=5   スペシャル値10、ファンブル値3で目標値5の判定を、アドバンテージを1点消費してダイス3つで行う
        VT3@10#3$4>=5 スペシャル値10、ファンブル値3で目標値5の判定を、アドバンテージを1点消費してダイス3つで行う。この際達成値が目標値より4以上大きい場合、ギャップボーナスを表示する
      MESSAGETEXT

      # 既定のスペシャル値
      DEFAULT_SPECIAL_VALUE = 12
      # 既定のファンブル値
      DEFAULT_FUMBLE_VALUE = 2
      # 規定のダイス個数
      DEFAULT_DICE_NUM = 2

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('VT')

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command Begin")

        parser = Command::Parser.new('VT', round_type: round_type)
                                .enable_critical
                                .enable_fumble
                                .enable_dollar
                                .enable_suffix_number
                                .restrict_cmp_op_to(nil, :>=)
        cmd = parser.parse(command)

        unless cmd
          return nil
        end

        dice_num = cmd.suffix_number || DEFAULT_DICE_NUM
        if dice_num < DEFAULT_DICE_NUM
          return nil
        end

        dice_list = @randomizer.roll_barabara(dice_num, 6)
        if dice_num > 2
          # 出目の順序を保存して上位2つの出目を取得
          j = 0 # 安定ソートのために利用 cf. https://docs.ruby-lang.org/ja/latest/method/Enumerable/i/sort_by.html
          using_list = dice_list.map.with_index { |x, i| {index: i, value: x} }
                                .sort_by { |x| [x[:value], j += 1] }.reverse.take(2)
                                .sort_by { |x| x[:index] }.map { |x| x[:value] }
        else
          using_list = dice_list
        end
        dice_total = using_list.sum
        total = dice_total + cmd.modify_number

        result = compare(dice_total, total, cmd)

        advantage_str =
          if dice_num > 2
            using_list.to_s
          end

        modifier_str =
          if cmd.modify_number > 0
            "#{dice_total}#{Format.modifier(cmd.modify_number)}"
          end

        level_gap_str =
          if cmd.target_number && cmd.dollar && result.success? && (gap = total - cmd.target_number) >= cmd.dollar
            "ギャップボーナス(#{gap})"
          end

        sequence = [
          cmd.to_s,
          dice_list.to_s,
          advantage_str,
          modifier_str,
          total.to_s,
          result.text,
          level_gap_str,
        ].compact

        result.text = sequence.join(" ＞ ")

        return result
      end

      def compare(dice_total, total, cmd)
        special = cmd.critical || DEFAULT_SPECIAL_VALUE
        fumble = cmd.fumble || DEFAULT_FUMBLE_VALUE

        if dice_total <= fumble
          return Result.fumble('ファンブル')
        elsif dice_total >= special
          return Result.critical('スペシャル')
        end

        if cmd.target_number
          if total.send(cmd.cmp_op, cmd.target_number)
            return Result.success('成功')
          else
            return Result.failure('失敗')
          end
        else
          return Result.new(nil)
        end
      end
    end
  end
end
