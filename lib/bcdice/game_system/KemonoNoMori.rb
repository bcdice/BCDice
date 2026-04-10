# frozen_string_literal: true

require 'bcdice/dice_table/table'
require 'bcdice/dice_table/range_table'

module BCDice
  module GameSystem
    class KemonoNoMori < Base
      # ゲームシステムの識別子
      ID = 'KemonoNoMori'

      # ゲームシステム名
      NAME = '獸ノ森'

      # ゲームシステム名の読みがな
      SORT_KEY = 'けもののもり'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定(成功度自動算出)(P119): KAx[±y]
        ・継続判定(成功度+1固定): KCx[±y]
           x=目標値
           y=目標値への修正(任意) x+y-z のように複数指定可能
             例1）KA7+3 → 目標値7にプラス3の修正を加えた行為判定
             例2）KC6 → 目標値6の継続判定
        ・罠動作チェック+獲物表(P163): CTR
           罠ごとに1D12を振り、12が出た場合には生き物が罠を動作させ、その影響を受けている。
        ・各種表（基本ルールブック）
          ・大失敗表(P120): FT
          ・能力値ランダム決定表(P121): RST
          ・ランダム所要時間表(P122): RTT
          ・ランダム消耗表(P122): RET
          ・ランダム天気表(P128): RWT
          ・ランダム天気持続表(P128): RWDT
          ・ランダム遮蔽物表（屋外）(P140): ROMT
          ・ランダム遮蔽物表（屋内）(P140): RIMT
          ・逃走体験表(P144): EET
          ・食材採集表(P157): GFT
          ・水採集表(P157): GWT
          ・白の魔石効果表(P186): WST
        ・部位ダメージ関連の表（参照先ページはリプレイ&データブック「嚙神ノ宴」のもの）
          ・人間部位表(P216): HPT
          ・部位ダメージ段階表(P217): PDT
          ・四足動物部位表(P225): QPT
          ・無足動物部位表(P225): APT
          ・二足動物部位表(P226): TPT
          ・鳥部位表(P226): BPT
          ・頭足動物部位表(P227): CPT
          ・昆虫部位表(P227): IPT
          ・蜘蛛部位表(P228): SPT
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        case command
        when /KA\d[-+\d]*/ then check_1D12(command, true)
        when /KC\d[-+\d]*/ then check_1D12(command, false)
        when 'CTR' then get_trap_result()
        when 'EET' then get_escape_experience_table_result(command)
        else roll_tables(command, self.class::TABLES)
        end
      end

      def check_1D12(command, is_action_judge)
        debug('獸ノ森の1d12判定')
        m = /K[AC](\d[-+\d]*)/.match(command)
        return nil unless m

        # 修正込みの目標値を計算
        target_total = ArithmeticEvaluator.eval(m[1])
        debug('target_total', target_total)

        # 行為判定の成功度は [目標値の10の位の数+1]
        # 継続判定の成功度は固定で+1
        success_degree = is_action_judge ? target_total / 10 + 1 : 1

        dice_total = @randomizer.roll_once(12)
        debug('dice_total, target_total, success_degree = ', dice_total, target_total, success_degree)

        if dice_total == 12
          Result.fumble("(1D12<=#{target_total}) ＞ #{dice_total} ＞ #{translate('KemonoNoMori.fumble')}")
        elsif dice_total == 11
          Result.critical("(1D12<=#{target_total}) ＞ #{dice_total} ＞ #{translate('KemonoNoMori.critical', success_degree: success_degree)}")
        elsif dice_total <= target_total
          Result.success("(1D12<=#{target_total}) ＞ #{dice_total} ＞ #{translate('KemonoNoMori.success', success_degree: success_degree)}")
        else
          Result.failure("(1D12<=#{target_total}) ＞ #{dice_total} ＞ #{translate('failure')}")
        end
      end

      def get_trap_result()
        tra_check_num = @randomizer.roll_once(12)
        unless tra_check_num == 12
          return Result.new(translate('KemonoNoMori.trap_not_activated', check_num: tra_check_num))
        end

        chase_num = @randomizer.roll_once(12)
        chase_key = case chase_num
                    when 1..4  then 'KemonoNoMori.trap_activated_small'
                    when 5..8  then 'KemonoNoMori.trap_activated_large'
                    when 9..12 then 'KemonoNoMori.trap_activated_human'
                    end
        Result.new(translate(chase_key, check_num: tra_check_num, chase_num: chase_num))
      end

      def get_escape_experience_table_result(command)
        escape_experience = roll_tables(command, self.class::TABLES)
        escape_duration = @randomizer.roll_once(12)
        Result.new("#{escape_experience} (#{translate('KemonoNoMori.reappear', hours: escape_duration)})")
      end

      class << self
        private

        def translate_tables(locale)
          general_tables(locale)
            .merge(field_tables(locale))
            .merge(body_part_tables(locale))
        end

        def general_tables(locale)
          {
            'FT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.FT', locale),
            'RST' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RST', locale),
            'RTT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RTT', locale),
            'RET' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RET', locale),
            'RWT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RWT', locale),
            'RWDT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RWDT', locale),
            'ROMT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.ROMT', locale),
            'RIMT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RIMT', locale),
            'EET' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.EET', locale),
            'GFT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.GFT', locale),
            'GWT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.GWT', locale),
            'WST' => DiceTable::Table.from_i18n('KemonoNoMori.table.WST', locale),
          }
        end

        def field_tables(locale)
          {
            'ROMT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.ROMT', locale),
            'RIMT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.RIMT', locale),
            'EET' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.EET', locale),
            'GFT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.GFT', locale),
            'GWT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.GWT', locale),
            'WST' => DiceTable::Table.from_i18n('KemonoNoMori.table.WST', locale),
          }
        end

        def body_part_tables(locale)
          {
            'HPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.HPT', locale),
            'PDT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.PDT', locale),
            'QPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.QPT', locale),
            'APT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.APT', locale),
            'TPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.TPT', locale),
            'BPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.BPT', locale),
            'CPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.CPT', locale),
            'IPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.IPT', locale),
            'SPT' => DiceTable::RangeTable.from_i18n('KemonoNoMori.table.SPT', locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      register_prefix('K[AC]', 'CTR', TABLES.keys)
    end
  end
end
