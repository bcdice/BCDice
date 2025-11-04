# frozen_string_literal: true

require 'bcdice/dice_table/table'

module BCDice
  module GameSystem
    class MorkBorg < Base
      # ゲームシステムの識別子
      ID = 'MorkBorg'

      # ゲームシステム名
      NAME = 'MorkBorg'

      # ゲームシステム名の読みがな
      SORT_KEY = 'むるくほりい'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　sDRt        s: 能力値(省略時:0) t:目標値

        例)+3DR12: 能力値+3、DR12で1d20を振って、その結果を表示(クリティカル・ファンブルも表示)

        ■イニシアティヴ　sINS s: 能力値(省略時:0. 個別のイニシアティブを使う場合)

        例)INS: 1d6を振って、イニシアティヴの結果を表示(PC先行を成功として表示)

        ■モラル　sMOR s: 能力値(省略時:0)

        例)MOR: 1d6を振って、モラルの結果を表示(降伏を成功として表示)


        ■各種表

        ・遭遇反応表(ERT)

      INFO_MESSAGETEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) || resolute_initiative(command) || resolute_morale(command) || roll_tables(command, TABLES)
      end

      private

      def result_dr(total, dice_total, target)
        if dice_total <= 1
          Result.fumble("Fumble")
        elsif dice_total >= 20
          Result.critical("Crit")
        elsif total >= target
          Result.success("Succeed")
        else
          Result.failure("Failure")
        end
      end

      # DR判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /^([+-]?\d+)?DR(\d+)$/.match(command)
        return nil unless m

        num_status = m[1].to_i
        num_target = m[2].to_i

        total = @randomizer.roll_once(20)
        total_status = total.to_s + with_symbol(num_status)
        result = result_dr(total + num_status, total, num_target)

        sequence = [
          "(#{command})",
          total_status,
          total + num_status,
          result.text,
        ]

        result.text = sequence.join(" ＞ ")
        return result
      end

      def with_symbol(number)
        if number == 0
          return "+0"
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      # イニシアティヴ判定
      # @param [String] command
      # @return [Result]
      def resolute_initiative(command)
        m = /^([+-]?\d+)?INS$/.match(command)
        return nil unless m

        num_status = m[1].to_i

        die = @randomizer.roll_once(6)
        total = die + num_status
        result =
          if total >= 4
            Result.success("PCs go first")
          else
            Result.failure("enemies go first")
          end

        result.text = "(#{command}) ＞ #{die}#{with_symbol(num_status)} ＞ #{total} ＞ #{result.text}"
        return result
      end

      # モラル判定
      # @param [String] command
      # @return [Result]
      def resolute_morale(command)
        m = /^([+-]?\d+)?MOR$/.match(command)
        return nil unless m

        num_status = m[1].to_i

        die = @randomizer.roll_once(6)
        total = die + num_status
        result =
          if total >= 4
            Result.success("surrenders")
          else
            Result.failure("flees")
          end

        result.text = "(#{command}) ＞ #{die}#{with_symbol(num_status)} ＞ #{total} ＞ #{result.text}"
        return result
      end

      # 各種表

      TABLES = {
        # 無理に高度なことをしなくても、表は展開して実装しても動く
        'ERT' => DiceTable::Table.new(
          '遭遇反応表',
          '2D6',
          [
            'Kill!',
            'Kill!',
            'Angered',
            'Angered',
            'Angered',
            'Indifferent',
            'Indifferent',
            'Almost friendly',
            'Almost friendly',
            'Helpful',
            'Helpful',
          ]
        ),
      }.freeze

      register_prefix('([+-]?\d+)?DR[\d]+', '([+-]?\d+)?INS', '([+-]?\d+)?MOR', TABLES.keys)
    end
  end
end
