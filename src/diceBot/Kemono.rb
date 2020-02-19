# -*- coding: utf-8 -*-

class Kemono < DiceBot
  def initialize
    super
  end

  def gameName
    '獸ノ森'
  end

  def gameType
    'Kemono'
  end

  def getHelpMessage
    return <<MESSAGETEXT
・行為判定(成功度自動算出): KAx[±y]
・継続判定(成功度+1固定): KCx[±y]
   x=目標値
   y=目標値への修正(任意) x+y-z のように複数指定可能
     例1）KA7+3 → 目標値7にプラス3の修正を加えた行為判定
     例2）KC6 → 目標値6の継続判定
・罠動作判定: CTR
   罠ごとに1D12を振る。12が出た場合は罠が動作し、獲物がその効果を受ける
・各種表
  ・大失敗表: FT
  ・能力値ランダム決定表: RST
  ・ランダム所要時間表: RTT
  ・ランダム消耗表: RET
  ・ランダム天気表: RWT
  ・ランダム天気持続表: RWDT
  ・ランダム遮蔽物表（屋外）: ROMT
  ・ランダム遮蔽物表（屋内）: RIMT
  ・逃走体験表: EET
  ・食材採集表: GFT
  ・水採集表: GWT
  ・白の魔石効果表: WST
MESSAGETEXT
  end

  def rollDiceCommand(command)
    case command
    when /^KA\d[-+\d]*/i
      return check_1D12(command, true)
    when /^KC\d[-+\d]*/i
      return check_1D12(command, false)
    when /CTR/i
      return getTrapResult()
    when /EET/i
      return getEscapeExperienceTableResult(command)
    when /FT/i, /RST/i, /RTT/i, /RET/i, /RWT/i, /RWDT/i, /ROMT/i, /RIMT/i, /GFT/i, /GWT/i, /WST/i
      return getTableDiceCommandResult(command)
    end
  end

  def check_1D12(command, is_action_judge)
    debug('獸ノ森の1d12判定')
    m = /^K[AC](\d[-+\d]*)/i.match(command)
    unless m
      return ''
    end

    # 修正込みの目標値を計算
    target_total = parren_killer("(#{m[1]})").to_i
    debug("target_total", target_total)

    # 行為判定の成功度は [目標値の10の位の数+1]
    # 継続判定の成功度は固定で+1
    success_degree = is_action_judge ? target_total / 10 + 1 : 1

    dice_total, = roll(1, 12)
    debug("dice_total, target_total, success_degree = ", dice_total, target_total, success_degree)

    if dice_total == 12
      return "(1D12<=#{target_total}) ＞ #{dice_total} ＞ 大失敗"
    elsif dice_total == 11
      return "(1D12<=#{target_total}) ＞ #{dice_total} ＞ 大成功（成功度+#{success_degree}, 次の継続判定の目標値を10に変更）"
    elsif dice_total <= target_total
      return "(1D12<=#{target_total}) ＞ #{dice_total} ＞ 成功（成功度+#{success_degree}）"
    else
      return "(1D12<=#{target_total}) ＞ #{dice_total} ＞ 失敗"
    end
  end

  def getTableDiceCommandResult(command)
    info = @@tables[command]
    return nil if info.nil?

    name = info[:name]
    table = info[:table]

    text, number = get_table_by_nDx(table, 1, 12)
    return nil if text.nil?

    return "#{name}(#{number}) ＞ #{text}"
  end

  def getTrapResult()
    trapCheckNumber, = roll(1, 12)

    # 12が出た場合のみ罠が動作する
    if trapCheckNumber == 12
      chaseNumber, = roll(1, 12)
      chase = nil
      case chaseNumber
      when 1, 2, 3, 4
        chase = '小型動物'
      when 5, 6, 7, 8
        chase = '大型動物'
      when 9, 10, 11, 12
        chase = '人間の放浪者'
      end
      return "罠動作チェック(1D12) ＞ #{trapCheckNumber} ＞ 罠が動作していた！ ＞ 獲物表(#{chaseNumber}) ＞ #{chase}が罠にかかっていた"
    end

    return "罠動作チェック(1D12) ＞ #{trapCheckNumber} ＞ 罠は動作していなかった"
  end

  def getEscapeExperienceTableResult(command)
    escapeExperience = getTableDiceCommandResult(command)
    escapeDuration, = roll(1, 12)
    return "#{escapeExperience} (再登場: #{escapeDuration}時間後)"
  end

  @@tables =
    {
      'FT' => {
        :name => '大失敗表',
        :table => %w{
          【余裕】が3点減少する（最低0まで）
          【余裕】が3点減少する（最低0まで）
          【余裕】が3点減少する（最低0まで）
          ランダムな荷物1個が落ちて行方不明になる（大失敗したエリアのアイテム調査で見つけることが可能）
          ランダムな荷物1個が落ちて行方不明になる（大失敗したエリアのアイテム調査で見つけることが可能）
          ランダムな荷物1個が破壊される
          ランダムな荷物1個が破壊される
          ランダム天気表を使用し、結果をターンの終了まで適用する
          ランダム天気表を使用し、結果をターンの終了まで適用する
          ランダムな準備している小道具1個が破壊される
          着想している防具が破壊される
          準備している武器が破壊される
        },
      },

      'RST' => {
        :name => '能力値ランダム決定表',
        :table => %w{
          【移動】
          【移動】
          【格闘】
          【格闘】
          【射撃】
          【射撃】
          【製作】
          【製作】
          【察知】
          【察知】
          【自制】
          【自制】
        }
      },

      'RTT' => {
        :name => 'ランダム所要時間表',
        :table => %w{
          2
          2
          2
          3
          3
          3
          4
          4
          4
          5
          5
          5
        }
      },

      'RET' => {
        :name => 'ランダム消耗表',
        :table => %w{
          0
          0
          0
          1
          1
          1
          2
          2
          2
          4
          4
          4
        }
      },

      'RWT' => {
        :name => 'ランダム天気表',
        :table => %w{
          濃霧
          濃霧
          大雨
          大雨
          雷雨
          雷雨
          強風
          強風
          酷暑
          酷暑
          極寒
          極寒
        }
      },

      'RWDT' => {
        :name => 'ランダム天気持続表',
        :table => %w{
          1ターン
          1ターン
          3ターン
          3ターン
          6ターン
          6ターン
          24ターン
          24ターン
          72ターン
          72ターン
          156ターン
          156ターン
        }
      },

      'ROMT' => {
        :name => 'ランダム遮蔽物表(屋外)',
        :table => %w{
          【藪】耐久度3,軽減値1,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【藪】耐久度3,軽減値1,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木】耐久度5,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木】耐久度5,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木】耐久度5,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【大木】耐久度7,軽減値3,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加
          【大木】耐久度7,軽減値3,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加
          【大木】耐久度7,軽減値3,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加
          【岩】耐久度6,軽減値4,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加/コンタクト内で行われる格闘攻撃のダメージ+1
          【岩】耐久度6,軽減値4,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加/コンタクト内で行われる格闘攻撃のダメージ+1
          【岩壁】耐久度8,軽減値4,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加/コンタクト内で行われる格闘攻撃のダメージ+2
          【岩壁】耐久度8,軽減値4,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-2の修正を付加/コンタクト内で行われる格闘攻撃のダメージ+2
        }
      },

      'RIMT' => {
        :name => 'ランダム遮蔽物表(屋内)',
        :table => %w{
          【木材の壁】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木材の壁】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木材の壁】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木材の壁】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1の修正を付加
          【木材の扉】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1、接触判定と突撃判定に-2の修正を付加
          【木材の扉】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1、接触判定と突撃判定に-2の修正を付加
          【木材の扉】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1、接触判定と突撃判定に-2の修正を付加
          【木材の扉】耐久度4,軽減値2,特殊効果:コンタクト内のキャラクターに対する射撃攻撃判定に-1、接触判定と突撃判定に-2の修正を付加
          【木製家具】耐久度3,軽減値2,特殊効果:コンタクト内で行われる格闘攻撃のダメージ+1
          【木製家具】耐久度3,軽減値2,特殊効果:コンタクト内で行われる格闘攻撃のダメージ+1
          【木製家具】耐久度3,軽減値2,特殊効果:コンタクト内で行われる格闘攻撃のダメージ+1
          【木製家具】耐久度3,軽減値2,特殊効果:コンタクト内で行われる格闘攻撃のダメージ+1
        }
      },

      'EET' => {
        :name => '逃走体験表',
        :table => %w{
          【余裕】が0になる
          【余裕】が0になる
          【余裕】が0になる
          任意の【絆】を合計2点減少する
          任意の【絆】を合計2点減少する
          任意の【絆】を合計2点減少する
          全ての荷物を失う（逃走したエリアに配置され、調査で発見可能）
          全ての荷物を失う（逃走したエリアに配置され、調査で発見可能）
          全ての荷物を失う（逃走したエリアに配置され、調査で発見可能）
          全ての武器と防具と小道具と荷物を失う（逃走したエリアに配置され、調査で発見可能）
          全ての武器と防具と小道具と荷物を失う（逃走したエリアに配置され、調査で発見可能）
          全ての武器と防具と小道具と荷物を失う（逃走したエリアに配置され、調査で発見可能）
        }
      },

      'GFT' => {
        :name => '食材採集表',
        :table => %w{
          食べられる根（栄養価:2）
          食べられる根（栄養価:2）
          食べられる草（栄養価:3）
          食べられる草（栄養価:3）
          食べられる草（栄養価:3）
          食べられる実（栄養価:5）
          食べられる実（栄養価:5）
          食べられる実（栄養価:5）
          小型動物（栄養価:10）
          小型動物（栄養価:10）
          大型動物（栄養価:40）
          気持ち悪い虫（栄養価:1）
        }
      },

      'GWT' => {
        :name => '水採集表',
        :table => %w{
          汚水
          汚水
          汚水
          汚水
          汚水
          汚水
          飲料水
          飲料水
          飲料水
          飲料水
          飲料水
          毒水
        }
      },

      'WST' => {
        :name => '白の魔石効果表',
        :table => %w{
          役に立たないものの色を変える
          役に立たないものを大きくする
          役に立たないものを小さくする
          役に立たないものを保存する
          役に立たないものを復元する
          役に立たないものを召喚する
          役に立たないものを動かす
          役に立たないものを増やす
          役に立たないものを貼り付ける
          役に立たないものを作り出す
          小型動物を召喚する
          大型動物を召喚する
        }
      }
    }

  setPrefixes([/^K[AC]\d[-+\d]*/i, /CTR/i] + @@tables.keys)
end
