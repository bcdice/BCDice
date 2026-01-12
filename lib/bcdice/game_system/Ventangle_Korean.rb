# frozen_string_literal: true

require 'bcdice/base'
require 'bcdice/game_system/Ventangle'

module BCDice
  module GameSystem
    class Ventangle_Korean < Ventangle
      # ゲームシステムの識別子
      ID = 'Ventangle:Korean'

      # ゲームシステム名
      NAME = '벤탱글'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:벤탱글'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        기본 양식 VTn@s#f$g>=T n=주사위 개수（생략 시 2） s=스페셜치（생략 시 12） f=펌블치（생략 시 2） g=레벨 갭 판정치（생략 가능） T=목표치（생략 가능）

        예시：
        VT        기본 스페셜치, 펌블치로 판정
        VT@10#3   스페셜치 10、펌블치 3으로 판정
        VT3@10#3  어드밴티지 1점을 사용해 스페셜치 10, 펌블치 3 판정을 주사위 3개로 판정

        VT>=5         기본 스페셜치, 펌블치로 목표치 5 판정
        VT@10#3>=5    스페셜치 10, 펌블치 3으로 목표치 5 판정
        VT@10#3$5>=5  스페셜치 10, 펌블치 3으로 목표치 5 판정. 이때 달성치가 목표치보다 5이상 큰 경우, 갭 보너스를 표시
        VT3@10#3>=5   어드밴티지 1점을 사용해 스페셜치 10, 펌블치 3, 목표치 5 판정을 주사위 3개로 판정
        VT3@10#3$4>=5 어드밴티지 1점을 사용해 스페셜치 10, 펌블치 3, 목표치 5 판정을 주사위 3개로 판정. 이때 달성치가 목표치보다 4이상 큰 경우, 갭 보너스를 표시
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
            "갭 보너스(#{gap})"
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
          return Result.fumble('펌블')
        elsif dice_total >= special
          return Result.critical('스페셜')
        end

        if cmd.target_number
          if total.send(cmd.cmp_op, cmd.target_number)
            return Result.success('성공')
          else
            return Result.failure('실패')
          end
        else
          return Result.new(nil)
        end
      end
    end
  end
end
