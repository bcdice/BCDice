# -*- coding: utf-8 -*-

require 'diceBot/DiceBot'

class NinjaSlayer < DiceBot
  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes([
      'NJ\d+.*',
      'EV\d+.*',
      'AT\d+.*'
      ])

  def initialize
    super

    @defaultSuccessTarget = ">=4"
  end

  def gameName
    'ニンジャスレイヤーTRPG'
  end

  def gameType
    "NinjaSlayer"
  end

  def getHelpMessage
    return <<MESSAGETEXT
・通常判定　NJ
　NJx[y] or NJx@y or NJx
　x=判定ダイス y=難易度 省略時はNORMAL(4)
　例:NJ4@H 難易度HARD、判定ダイス4で判定
・回避判定　EV
　EVx[y]/z or EVx@y/z or EVx/z or EVx[y] or EVx@y or EVx
　x=判定ダイス y=難易度 z=攻撃側の成功数(省略可) 難易度を省略時はNORMAL(4)
　攻撃側の成功数を指定した場合、カウンターカラテ発生時には表示
　例:EV5/3 難易度NORMAL(省略時)、判定ダイス5、攻撃側の成功数3で判定
・近接攻撃　AT
　ATx[y] or ATx@y or ATx
　x=判定ダイス y=難易度 省略時はNORMAL(4) サツバツ！発生時には表示
　例:AT6[H] 難易度HARD,判定ダイス5で近接攻撃の判定

・難易度
　KIDS=K,EASY=E,NORMAL=N,HARD=H,ULTRA HARD=UH 数字にも対応
MESSAGETEXT
  end

  # 難易度の値の正規表現
  DIFFICULTY_VALUE_RE = /UH|[2-6KENH]/i
  # 難易度の正規表現
  DIFFICULTY_RE = /\[(#{DIFFICULTY_VALUE_RE})\]|@(#{DIFFICULTY_VALUE_RE})/io
  # 通常判定の正規表現
  NJ_RE = /\ANJ(\d+)#{DIFFICULTY_RE}?\z/io
  # 回避判定の正規表現
  EV_RE = %r{\AEV(\d+)#{DIFFICULTY_RE}?(?:/(\d+))?\z}io

  # 回避判定のノード
  EV = Struct.new(:num, :difficulty, :targetValue)

  # 難易度の文字表現から整数値への対応
  DIFFICULTY_SYMBOL_TO_INTEGER = {
    'K' => 2,
    'E' => 3,
    'N' => 4,
    'H' => 5,
    'UH' => 6
  }

  def changeText(str)
    m = NJ_RE.match(str)
    return str unless m

    return bRollCommand(m[1], integerValueOfDifficulty(m[2] || m[3]))
  end

  def rollDiceCommand(command)
    debug('rollDiceCommand begin string', command)

    case node = parse(command)
    when EV
      return executeEV(node)
    end

    result = ''

    # combat attack difficults
    at_kids_pattern = /^(?:at)(\d+)(?:@|\[)?[k2](?:\])?/i
    at_easy_pattern = /^(?:at)(\d+)(?:@|\[)?[e3](?:\])?/i
    at_normal_pattern = /^(?:at)(\d+)(?:@|\[)?[n4](?:\])?/i
    at_hard_pattern = /^(?:at)(\d+)(?:@|\[)?[h5](?:\])?/i
    at_ultrahard_pattern = /^(?:at)(\d+)(?:@|\[)?(?:uh|6)(?:\])?/i
    at_short_pattern = /^(?:at)(\d+)$/i

    # AT evaluate
    if (m = at_kids_pattern.match(command))
      debug('at kids: ', command)

      dice_cnt = m[1]
      dice = roll(m[1], 6, 0, 0, '>=', 2)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice[3]

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=2) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += ' ＞ サツバツ!!'
      end
    elsif (m = at_easy_pattern.match(command))
      debug('at easy: ', command)

      dice_cnt = m[1]
      dice = roll(m[1], 6, 0, 0, '>=', 3)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice[3]

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=3) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += ' ＞ サツバツ!!'
      end
    elsif (m = at_normal_pattern.match(command))
      debug('at normal: ', command)

      dice_cnt = m[1]
      dice = roll(m[1], 6, 0, 0, '>=', 4)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice[3]

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=4) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += ' ＞ サツバツ!!'
      end
    elsif (m = at_hard_pattern.match(command))
      debug('at hard: ', command)

      dice_cnt = m[1]
      dice = roll(m[1], 6, 0, 0, '>=', 5)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice[3]

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=5) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += ' ＞ サツバツ!!'
      end
    elsif (m = at_ultrahard_pattern.match(command))
      debug('at ultrahard: ', command)

      dice_cnt = m[1]
      dice = roll(m[1], 6, 0, 0, '>=', 6)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice[3]

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=6) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += ' ＞ サツバツ!!'
      end
    elsif (m = at_short_pattern.match(command))
      debug('at short: ', command)

      dice_cnt = m[1]
      dice = roll(m[1], 6, 0, 0, '>=', 4)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice[3]

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=4) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += ' ＞ サツバツ!!'
      end

    else
      debug('rollDiceCommand else: ', command)
      result = nil
    end

    return result
  end

  private

  # 構文解析する
  # @param [String] command コマンド文字列
  # @return [EV, nil]
  def parse(command)
    case
    when mEV = EV_RE.match(command)
      return parseEV(mEV)
    else
      return nil
    end
  end

  # 正規表現のマッチ情報から回避判定ノードを作る
  # @param [MatchData] m 正規表現のマッチ情報
  # @return [EV]
  def parseEV(m)
    num = m[1].to_i
    difficulty = integerValueOfDifficulty(m[2] || m[3])
    targetValue = m[4] && m[4].to_i

    return EV.new(num, difficulty, targetValue)
  end

  # 回避判定を行う
  # @param [EV] ev 回避判定ノード
  # @return [String] 回避判定結果
  def executeEV(ev)
    command = bRollCommand(ev.num, ev.difficulty)
    rollResult = bcdice.
      bdice(command).
      sub(/\A[^(]+/, '')

    return rollResult unless ev.targetValue

    m = /成功数(\d+)/.match(rollResult)
    raise '成功数が見つかりません' unless m
    numOfSuccesses = m[1].to_i

    if numOfSuccesses > ev.targetValue
      return "#{rollResult} ＞ カウンターカラテ!!"
    end

    return rollResult
  end

  # 難易度の整数値を返す
  # @param [String, nil] s 難易度表記
  # @return [Integer] 難易度の整数値
  # @raise [KeyError, IndexError] 無効な難易度表記が渡された場合。
  #
  # sは2から6までの数字あるいは'K', 'E', 'N', 'H', 'UH'。
  # sがnilの場合は 4 を返す。
  def integerValueOfDifficulty(s)
    return 4 unless s

    return s.to_i if /\A[2-6]\z/.match(s)

    return DIFFICULTY_SYMBOL_TO_INTEGER.fetch(s.upcase)
  end

  # バラバラロールのコマンドを返す
  # @param [#to_s] num ダイス数
  # @param [#to_s] difficulty 難易度
  # @return [String]
  def bRollCommand(num, difficulty)
    "#{num}B6>=#{difficulty}"
  end
end
