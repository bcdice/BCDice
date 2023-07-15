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
        else roll_tables(command, TABLES)
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
          Result.fumble("(1D12<=#{target_total}) ＞ #{dice_total} ＞ 大失敗")
        elsif dice_total == 11
          Result.critical("(1D12<=#{target_total}) ＞ #{dice_total} ＞ 大成功（成功度+#{success_degree}, 次の継続判定の目標値を10に変更）")
        elsif dice_total <= target_total
          Result.success("(1D12<=#{target_total}) ＞ #{dice_total} ＞ 成功（成功度+#{success_degree}）")
        else
          Result.failure("(1D12<=#{target_total}) ＞ #{dice_total} ＞ 失敗")
        end
      end

      def get_trap_result()
        tra_check_num = @randomizer.roll_once(12)
        unless tra_check_num == 12
          return Result.new("罠動作チェック(1D12) ＞ #{tra_check_num} ＞ 罠は動作していなかった")
        end

        chase_num = @randomizer.roll_once(12)
        chase = case chase_num
                when 1, 2, 3, 4 then '小型動物'
                when 5, 6, 7, 8 then '大型動物'
                when 9, 10, 11, 12 then '人間の放浪者'
                end
        Result.new("罠動作チェック(1D12) ＞ #{tra_check_num} ＞ 罠が動作していた！ ＞ 獲物表(#{chase_num}) ＞ #{chase}が罠にかかっていた")
      end

      def get_escape_experience_table_result(command)
        escape_experience = roll_tables(command, TABLES)
        escape_duration = @randomizer.roll_once(12)
        Result.new("#{escape_experience} (再登場: #{escape_duration}時間後)")
      end

      TABLES = {
        'FT' => DiceTable::RangeTable.new(
          '大失敗表',
          '1D12',
          [
            [1..3, '【余裕】が3点減少する（最低0まで）'],
            [4..5, 'ランダムな荷物1個が落ちて行方不明になる（大失敗したエリアのアイテム調査で見つけることが可能）'],
            [6..7, 'ランダムな荷物1個が破壊される'],
            [8..9, 'ランダム天気表(RWT)を使用し、結果をターンの終了まで適用する'],
            [10,   'ランダムな準備している小道具1個が破壊される'],
            [11,   '着装している防具が破壊される'],
            [12,   '準備している武器が破壊される'],
          ]
        ),
        'RST' => DiceTable::RangeTable.new(
          '能力値ランダム決定表',
          '1D12',
          [
            [1..2,   '【移動】'],
            [3..4,   '【格闘】'],
            [5..6,   '【射撃】'],
            [7..8,   '【製作】'],
            [9..10,  '【察知】'],
            [11..12, '【自制】'],
          ]
        ),
        'RTT' => DiceTable::RangeTable.new(
          'ランダム所要時間表',
          '1D12',
          [
            [1..3,   '2'],
            [4..6,   '3'],
            [7..9,   '4'],
            [10..12, '5'],
          ]
        ),
        'RET' => DiceTable::RangeTable.new(
          'ランダム消耗表',
          '1D12',
          [
            [1..3,   '0'],
            [4..6,   '1'],
            [7..9,   '2'],
            [10..12, '4'],
          ]
        ),
        'RWT' => DiceTable::RangeTable.new(
          'ランダム天気表',
          '1D12',
          [
            [1..2,   '濃霧'],
            [3..4,   '大雨'],
            [5..6,   '雷雨'],
            [7..8,   '強風'],
            [9..10,  '酷暑'],
            [11..12, '極寒'],
          ]
        ),
        'RWDT' => DiceTable::RangeTable.new(
          'ランダム天気持続表',
          '1D12',
          [
            [1..2,   '1ターン'],
            [3..4,   '3ターン'],
            [5..6,   '6ターン'],
            [7..8,   '24ターン'],
            [9..10,  '72ターン'],
            [11..12, '156ターン'],
          ]
        ),
        'ROMT' => DiceTable::RangeTable.new(
          'ランダム遮蔽物表(屋外)',
          '1D12',
          [
            [1..2,   '【藪】耐久度3,軽減値1,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加'],
            [3..5,   '【木】耐久度5,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加'],
            [6..8,   '【大木】耐久度7,軽減値3,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加'],
            [9..10,  '【岩】耐久度6,軽減値4,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加/コンタクト内で行われる格闘攻撃のダメージ+1'],
            [11..12, '【岩壁】耐久度8,軽減値4,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加/コンタクト内で行われる格闘攻撃のダメージ+2'],
          ]
        ),
        'RIMT' => DiceTable::RangeTable.new(
          'ランダム遮蔽物表(屋内)',
          '1D12',
          [
            [1..4,  '【木材の壁】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加'],
            [5..8,  '【木材の扉】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1、接触判定と突撃判定に-2の修正を付加'],
            [9..12, '【木製家具】耐久度3,軽減値2,特殊効果:コンタクト内で行われる格闘攻撃のダメージ+1'],
          ]
        ),
        'EET' => DiceTable::RangeTable.new(
          '逃走体験表',
          '1D12',
          [
            [1..3,   '【余裕】が0になる'],
            [4..6,   '任意の【絆】を合計2点減少する'],
            [7..9,   '全ての荷物を失う（逃走したエリアに配置され、調査で発見可能）'],
            [10..12, '全ての武器と防具と小道具と荷物を失う（逃走したエリアに配置され、調査で発見可能）'],
          ]
        ),
        'GFT' => DiceTable::RangeTable.new(
          '食材採集表',
          '1D12',
          [
            [1..2,  '食べられる根（栄養価:2）'],
            [3..5,  '食べられる草（栄養価:3）'],
            [6..8,  '食べられる実（栄養価:5）'],
            [9..10, '小型動物（栄養価:10）'],
            [11,    '大型動物（栄養価:40）'],
            [12,    '気持ち悪い虫（栄養価:1）'],
          ]
        ),
        'GWT' => DiceTable::RangeTable.new(
          '水採集表',
          '1D12',
          [
            [1..6,  '汚水'],
            [7..11, '飲料水'],
            [12,    '毒水'],
          ]
        ),
        'WST' => DiceTable::Table.new(
          '白の魔石効果表',
          '1D12',
          [
            '役に立たないものの色を変える',
            '役に立たないものを大きくする',
            '役に立たないものを小さくする',
            '役に立たないものを保存する',
            '役に立たないものを復元する',
            '役に立たないものを召喚する',
            '役に立たないものを動かす',
            '役に立たないものを増やす',
            '役に立たないものを貼り付ける',
            '役に立たないものを作り出す',
            '小型動物を召喚する',
            '大型動物を召喚する',
          ]
        ),
        'HPT' => DiceTable::RangeTable.new(
          '人間部位表',
          '1D12',
          [
            [1..2,  '右腕部'],
            [3..4,  '左腕部'],
            [5..6,  '右脚部'],
            [7..8,  '左脚部'],
            [9..11, '胴部'],
            [12,    '頭部'],
          ]
        ),
        'PDT' => DiceTable::RangeTable.new(
          '部位ダメージ段階表',
          '1D12',
          [
            [1..6,  '軽傷'],
            [7..10, '重傷'],
            [11,    '破壊'],
            [12,    '喪失'],
          ]
        ),
        'QPT' => DiceTable::RangeTable.new(
          '四足動物部位表',
          '1D12',
          [
            [1..2,    '異形'],
            [3,       '武器'],
            [4,       '右前脚部'],
            [5,       '左前脚部'],
            [6,       '右後脚部'],
            [7,       '左後脚部'],
            [8..10,   '胴部'],
            [11..12,  '頭部'],
          ]
        ),
        'APT' => DiceTable::RangeTable.new(
          '無足動物部位表',
          '1D12',
          [
            [1..3,    '異形'],
            [4..6,    '武器'],
            [7..10,   '胴部'],
            [11..12,  '頭部'],
          ]
        ),
        'TPT' => DiceTable::RangeTable.new(
          '二足動物部位表',
          '1D12',
          [
            [1,     '異形'],
            [2,     '武器'],
            [3,     '右腕部'],
            [4,     '左腕部'],
            [5..6,  '右脚部'],
            [7..8,  '左脚部'],
            [9..11, '胴部'],
            [12,    '頭部'],
          ]
        ),
        'BPT' => DiceTable::RangeTable.new(
          '鳥部位表',
          '1D12',
          [
            [1,     '異形'],
            [2,     '武器'],
            [3..4,  '右翼(右腕部)'],
            [5..6,  '左翼(左腕部)'],
            [7,     '右脚部'],
            [8,     '左脚部'],
            [9..11, '胴部'],
            [12,    '頭部'],
          ]
        ),
        'CPT' => DiceTable::RangeTable.new(
          '頭足動物部位表',
          '1D12',
          [
            [1,     '異形'],
            [2,     '武器'],
            [3,     '右腕部'],
            [4,     '左腕部'],
            [5..7,  '右脚部'],
            [8..10, '左脚部'],
            [11,    '胴部'],
            [12,    '頭部'],
          ]
        ),
        'IPT' => DiceTable::RangeTable.new(
          '昆虫部位表',
          '1D12',
          [
            [1..2,    '異形'],
            [3,       '武器'],
            [4,       '右前脚部'],
            [5,       '左前脚部'],
            [6,       '右中脚部'],
            [7,       '左中脚部'],
            [8,       '右後脚部'],
            [9,       '左後脚部'],
            [10..11,  '胴部'],
            [12,      '頭部'],
          ]
        ),
        'SPT' => DiceTable::RangeTable.new(
          '蜘蛛部位表',
          '1D12',
          [
            [1,   '異形'],
            [2,   '武器'],
            [3,   '右第一脚部'],
            [4,   '左第一脚部'],
            [5,   '右第二脚部'],
            [6,   '左第二脚部'],
            [7,   '右第三脚部'],
            [8,   '左第三脚部'],
            [9,   '右第四脚部'],
            [10,  '左第四脚部'],
            [11,  '胴部'],
            [12,  '頭部'],
          ]
        ),
      }.freeze

      register_prefix('K[AC]', 'CTR', TABLES.keys)
    end
  end
end
