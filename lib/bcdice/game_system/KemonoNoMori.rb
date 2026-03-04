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
            'FT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.FT.name', locale: locale),
              '1D12',
              [
                [1..3,  I18n.t('KemonoNoMori.table.FT.1_3', locale: locale)],
                [4..5,  I18n.t('KemonoNoMori.table.FT.4_5', locale: locale)],
                [6..7,  I18n.t('KemonoNoMori.table.FT.6_7', locale: locale)],
                [8..9,  I18n.t('KemonoNoMori.table.FT.8_9', locale: locale)],
                [10..10, I18n.t('KemonoNoMori.table.FT.10', locale: locale)],
                [11..11, I18n.t('KemonoNoMori.table.FT.11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.FT.12', locale: locale)],
              ]
            ),
            'RST' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.RST.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.RST.1_2', locale: locale)],
                [3..4,   I18n.t('KemonoNoMori.table.RST.3_4', locale: locale)],
                [5..6,   I18n.t('KemonoNoMori.table.RST.5_6', locale: locale)],
                [7..8,   I18n.t('KemonoNoMori.table.RST.7_8', locale: locale)],
                [9..10,  I18n.t('KemonoNoMori.table.RST.9_10', locale: locale)],
                [11..12, I18n.t('KemonoNoMori.table.RST.11_12', locale: locale)],
              ]
            ),
            'RTT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.RTT.name', locale: locale),
              '1D12',
              [
                [1..3,   I18n.t('KemonoNoMori.table.RTT.1_3', locale: locale)],
                [4..6,   I18n.t('KemonoNoMori.table.RTT.4_6', locale: locale)],
                [7..9,   I18n.t('KemonoNoMori.table.RTT.7_9', locale: locale)],
                [10..12, I18n.t('KemonoNoMori.table.RTT.10_12', locale: locale)],
              ]
            ),
            'RET' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.RET.name', locale: locale),
              '1D12',
              [
                [1..3,   I18n.t('KemonoNoMori.table.RET.1_3', locale: locale)],
                [4..6,   I18n.t('KemonoNoMori.table.RET.4_6', locale: locale)],
                [7..9,   I18n.t('KemonoNoMori.table.RET.7_9', locale: locale)],
                [10..12, I18n.t('KemonoNoMori.table.RET.10_12', locale: locale)],
              ]
            ),
            'RWT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.RWT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.RWT.1_2', locale: locale)],
                [3..4,   I18n.t('KemonoNoMori.table.RWT.3_4', locale: locale)],
                [5..6,   I18n.t('KemonoNoMori.table.RWT.5_6', locale: locale)],
                [7..8,   I18n.t('KemonoNoMori.table.RWT.7_8', locale: locale)],
                [9..10,  I18n.t('KemonoNoMori.table.RWT.9_10', locale: locale)],
                [11..12, I18n.t('KemonoNoMori.table.RWT.11_12', locale: locale)],
              ]
            ),
            'RWDT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.RWDT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.RWDT.1_2', locale: locale)],
                [3..4,   I18n.t('KemonoNoMori.table.RWDT.3_4', locale: locale)],
                [5..6,   I18n.t('KemonoNoMori.table.RWDT.5_6', locale: locale)],
                [7..8,   I18n.t('KemonoNoMori.table.RWDT.7_8', locale: locale)],
                [9..10,  I18n.t('KemonoNoMori.table.RWDT.9_10', locale: locale)],
                [11..12, I18n.t('KemonoNoMori.table.RWDT.11_12', locale: locale)],
              ]
            ),
          }
        end

        def field_tables(locale)
          {
            'ROMT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.ROMT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.ROMT.1_2', locale: locale)],
                [3..5,   I18n.t('KemonoNoMori.table.ROMT.3_5', locale: locale)],
                [6..8,   I18n.t('KemonoNoMori.table.ROMT.6_8', locale: locale)],
                [9..10,  I18n.t('KemonoNoMori.table.ROMT.9_10', locale: locale)],
                [11..12, I18n.t('KemonoNoMori.table.ROMT.11_12', locale: locale)],
              ]
            ),
            'RIMT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.RIMT.name', locale: locale),
              '1D12',
              [
                [1..4,  I18n.t('KemonoNoMori.table.RIMT.1_4', locale: locale)],
                [5..8,  I18n.t('KemonoNoMori.table.RIMT.5_8', locale: locale)],
                [9..12, I18n.t('KemonoNoMori.table.RIMT.9_12', locale: locale)],
              ]
            ),
            'EET' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.EET.name', locale: locale),
              '1D12',
              [
                [1..3,   I18n.t('KemonoNoMori.table.EET.1_3', locale: locale)],
                [4..6,   I18n.t('KemonoNoMori.table.EET.4_6', locale: locale)],
                [7..9,   I18n.t('KemonoNoMori.table.EET.7_9', locale: locale)],
                [10..12, I18n.t('KemonoNoMori.table.EET.10_12', locale: locale)],
              ]
            ),
            'GFT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.GFT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.GFT.1_2', locale: locale)],
                [3..5,   I18n.t('KemonoNoMori.table.GFT.3_5', locale: locale)],
                [6..8,   I18n.t('KemonoNoMori.table.GFT.6_8', locale: locale)],
                [9..10,  I18n.t('KemonoNoMori.table.GFT.9_10', locale: locale)],
                [11..11, I18n.t('KemonoNoMori.table.GFT.11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.GFT.12', locale: locale)],
              ]
            ),
            'GWT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.GWT.name', locale: locale),
              '1D12',
              [
                [1..6,   I18n.t('KemonoNoMori.table.GWT.1_6', locale: locale)],
                [7..11,  I18n.t('KemonoNoMori.table.GWT.7_11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.GWT.12', locale: locale)],
              ]
            ),
            'WST' => DiceTable::Table.from_i18n('KemonoNoMori.table.WST', locale),
          }
        end

        def body_part_tables(locale)
          {
            'HPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.HPT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.HPT.1_2', locale: locale)],
                [3..4,   I18n.t('KemonoNoMori.table.HPT.3_4', locale: locale)],
                [5..6,   I18n.t('KemonoNoMori.table.HPT.5_6', locale: locale)],
                [7..8,   I18n.t('KemonoNoMori.table.HPT.7_8', locale: locale)],
                [9..11,  I18n.t('KemonoNoMori.table.HPT.9_11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.HPT.12', locale: locale)],
              ]
            ),
            'PDT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.PDT.name', locale: locale),
              '1D12',
              [
                [1..6,   I18n.t('KemonoNoMori.table.PDT.1_6', locale: locale)],
                [7..10,  I18n.t('KemonoNoMori.table.PDT.7_10', locale: locale)],
                [11..11, I18n.t('KemonoNoMori.table.PDT.11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.PDT.12', locale: locale)],
              ]
            ),
            'QPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.QPT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.QPT.1_2', locale: locale)],
                [3..3,   I18n.t('KemonoNoMori.table.QPT.3', locale: locale)],
                [4..4,   I18n.t('KemonoNoMori.table.QPT.4', locale: locale)],
                [5..5,   I18n.t('KemonoNoMori.table.QPT.5', locale: locale)],
                [6..6,   I18n.t('KemonoNoMori.table.QPT.6', locale: locale)],
                [7..7,   I18n.t('KemonoNoMori.table.QPT.7', locale: locale)],
                [8..10,  I18n.t('KemonoNoMori.table.QPT.8_10', locale: locale)],
                [11..12, I18n.t('KemonoNoMori.table.QPT.11_12', locale: locale)],
              ]
            ),
            'APT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.APT.name', locale: locale),
              '1D12',
              [
                [1..3,   I18n.t('KemonoNoMori.table.APT.1_3', locale: locale)],
                [4..6,   I18n.t('KemonoNoMori.table.APT.4_6', locale: locale)],
                [7..10,  I18n.t('KemonoNoMori.table.APT.7_10', locale: locale)],
                [11..12, I18n.t('KemonoNoMori.table.APT.11_12', locale: locale)],
              ]
            ),
            'TPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.TPT.name', locale: locale),
              '1D12',
              [
                [1..1,   I18n.t('KemonoNoMori.table.TPT.1', locale: locale)],
                [2..2,   I18n.t('KemonoNoMori.table.TPT.2', locale: locale)],
                [3..3,   I18n.t('KemonoNoMori.table.TPT.3', locale: locale)],
                [4..4,   I18n.t('KemonoNoMori.table.TPT.4', locale: locale)],
                [5..6,   I18n.t('KemonoNoMori.table.TPT.5_6', locale: locale)],
                [7..8,   I18n.t('KemonoNoMori.table.TPT.7_8', locale: locale)],
                [9..11,  I18n.t('KemonoNoMori.table.TPT.9_11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.TPT.12', locale: locale)],
              ]
            ),
            'BPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.BPT.name', locale: locale),
              '1D12',
              [
                [1..1,   I18n.t('KemonoNoMori.table.BPT.1', locale: locale)],
                [2..2,   I18n.t('KemonoNoMori.table.BPT.2', locale: locale)],
                [3..4,   I18n.t('KemonoNoMori.table.BPT.3_4', locale: locale)],
                [5..6,   I18n.t('KemonoNoMori.table.BPT.5_6', locale: locale)],
                [7..7,   I18n.t('KemonoNoMori.table.BPT.7', locale: locale)],
                [8..8,   I18n.t('KemonoNoMori.table.BPT.8', locale: locale)],
                [9..11,  I18n.t('KemonoNoMori.table.BPT.9_11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.BPT.12', locale: locale)],
              ]
            ),
            'CPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.CPT.name', locale: locale),
              '1D12',
              [
                [1..1,   I18n.t('KemonoNoMori.table.CPT.1', locale: locale)],
                [2..2,   I18n.t('KemonoNoMori.table.CPT.2', locale: locale)],
                [3..3,   I18n.t('KemonoNoMori.table.CPT.3', locale: locale)],
                [4..4,   I18n.t('KemonoNoMori.table.CPT.4', locale: locale)],
                [5..7,   I18n.t('KemonoNoMori.table.CPT.5_7', locale: locale)],
                [8..10,  I18n.t('KemonoNoMori.table.CPT.8_10', locale: locale)],
                [11..11, I18n.t('KemonoNoMori.table.CPT.11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.CPT.12', locale: locale)],
              ]
            ),
            'IPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.IPT.name', locale: locale),
              '1D12',
              [
                [1..2,   I18n.t('KemonoNoMori.table.IPT.1_2', locale: locale)],
                [3..3,   I18n.t('KemonoNoMori.table.IPT.3', locale: locale)],
                [4..4,   I18n.t('KemonoNoMori.table.IPT.4', locale: locale)],
                [5..5,   I18n.t('KemonoNoMori.table.IPT.5', locale: locale)],
                [6..6,   I18n.t('KemonoNoMori.table.IPT.6', locale: locale)],
                [7..7,   I18n.t('KemonoNoMori.table.IPT.7', locale: locale)],
                [8..8,   I18n.t('KemonoNoMori.table.IPT.8', locale: locale)],
                [9..9,   I18n.t('KemonoNoMori.table.IPT.9', locale: locale)],
                [10..11, I18n.t('KemonoNoMori.table.IPT.10_11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.IPT.12', locale: locale)],
              ]
            ),
            'SPT' => DiceTable::RangeTable.new(
              I18n.t('KemonoNoMori.table.SPT.name', locale: locale),
              '1D12',
              [
                [1..1,   I18n.t('KemonoNoMori.table.SPT.1', locale: locale)],
                [2..2,   I18n.t('KemonoNoMori.table.SPT.2', locale: locale)],
                [3..3,   I18n.t('KemonoNoMori.table.SPT.3', locale: locale)],
                [4..4,   I18n.t('KemonoNoMori.table.SPT.4', locale: locale)],
                [5..5,   I18n.t('KemonoNoMori.table.SPT.5', locale: locale)],
                [6..6,   I18n.t('KemonoNoMori.table.SPT.6', locale: locale)],
                [7..7,   I18n.t('KemonoNoMori.table.SPT.7', locale: locale)],
                [8..8,   I18n.t('KemonoNoMori.table.SPT.8', locale: locale)],
                [9..9,   I18n.t('KemonoNoMori.table.SPT.9', locale: locale)],
                [10..10, I18n.t('KemonoNoMori.table.SPT.10', locale: locale)],
                [11..11, I18n.t('KemonoNoMori.table.SPT.11', locale: locale)],
                [12..12, I18n.t('KemonoNoMori.table.SPT.12', locale: locale)],
              ]
            ),
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      register_prefix('K[AC]', 'CTR', TABLES.keys)
    end
  end
end
