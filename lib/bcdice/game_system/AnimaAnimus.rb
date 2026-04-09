# frozen_string_literal: true

require 'bcdice/dice_table/table'
require 'bcdice/dice_table/range_table'
require 'bcdice/arithmetic'

module BCDice
  module GameSystem
    class AnimaAnimus < Base
      # ゲームシステムの識別子
      ID = 'AnimaAnimus'

      # ゲームシステム名
      NAME = 'アニマアニムス'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'あにまあにむす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定(xAN<=y±z)
        　十面ダイスをx個振って判定します。達成値が算出されます(クリティカル発生時は2増加)。
        　x：振るダイスの数。魂魄値や攻撃値。
        　y：成功値。
        　z：成功値への補正。省略可能。
        　(例) 2AN<=3+1 5AN<=7
        ・各種表
        　情報収集表　IGT/喪失表　LT
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        m = /(\d+)AN<=(\d+([+-]\d+)*)/i.match(command)
        if self.class::TABLES.key?(command)
          return roll_tables(command, self.class::TABLES)
        elsif m
          return check_action(m)
        else
          return nil
        end
      end

      def check_action(match_data)
        dice_cnt = Arithmetic.eval(match_data[1], RoundType::FLOOR)
        target = Arithmetic.eval(match_data[2], RoundType::FLOOR)
        debug("dice_cnt", dice_cnt)
        debug("target", target)

        dice_arr = @randomizer.roll_barabara(dice_cnt, 10)
        dice_str = dice_arr.join(",")
        suc_cnt = dice_arr.count { |x| x <= target }
        has_critical = dice_arr.include?(1)
        result = has_critical ? suc_cnt + 2 : suc_cnt

        Result.new.tap do |r|
          r.text = "(#{dice_cnt}B10<=#{target}) ＞ #{dice_str} ＞ #{result > 0 ? translate('success') : translate('failure')}(#{translate('AnimaAnimus.achievement_value')}:#{result})#{has_critical ? " (#{translate('AnimaAnimus.critical')})" : ''}"
          r.critical = has_critical
          r.success = result > 0
          r.failure = !r.success?
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            'IGT' => DiceTable::Table.from_i18n('AnimaAnimus.table.IGT', locale),
            'LT' => DiceTable::RangeTable.from_i18n('AnimaAnimus.table.LT', locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d+AN<=', TABLES.keys)
    end
  end
end
