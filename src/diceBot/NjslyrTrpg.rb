# -*- coding: utf-8 -*-

class NjslyrTrpg < DiceBot
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
    "NjslyrTrpg"
  end

  def getHelpMessage
    return <<MESSAGETEXT
・通常判定　NJ
　NJx[y] or NJx@y or NJx
　x=判定ダイス y=難易度 省略時はNORMAL(4)
　例:NJ4@H 難易度HARD、判定ダイス4で判定
・回避判定　EV
　EVx[y]/z or EVx@y/z or EVx/z or EVx
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

  def changeText(string)
    # roll difficults
    kids_pattern = /^(?:nj|NJ|Nj)(\d+)(?:@|\[)?[kK2](?:\])?/
    easy_pattern = /^(?:nj|NJ|Nj)(\d+)(?:@|\[)?[eE3](?:\])?/
    normal_pattern = /^(?:nj|NJ|Nj)(\d+)(?:@|\[)?[nN4](?:\])?/
    hard_pattern = /^(?:nj|NJ|Nj)(\d+)(?:@|\[)?[hH5](?:\])?/
    ultrahard_pattern = /^(?:nj|NJ|Nj)(\d+)(?:@|\[)?(?:uh|UH|Uh|6)(?:\])?/
    short_pattern = /^(?:nj|NJ|Nj)(\d+)$/

    debug("src word: ", string)

    case string
    # NJ evaluate
    when kids_pattern
      debug("nj kids: ", string)
      string = string.gsub(kids_pattern) { "#{Regexp.last_match(1)}B6>=2" }
    when easy_pattern
      debug("nj easy: ", string)
      string = string.gsub(easy_pattern) { "#{Regexp.last_match(1)}B6>=3" }
    when normal_pattern
      debug("nj normal: ", string)
      string = string.gsub(normal_pattern) { "#{Regexp.last_match(1)}B6>=4" }
    when hard_pattern
      debug("nj hard: ", string)
      string = string.gsub(hard_pattern) { "#{Regexp.last_match(1)}B6>=5" }
    when ultrahard_pattern
      debug("nj ultrahard: ", string)
      string = string.gsub(ultrahard_pattern) { "#{Regexp.last_match(1)}B6>=6" }
    when short_pattern
      debug("nj short: ", string)
      string = string.gsub(short_pattern) { "#{Regexp.last_match(1)}B6>=4" }

    else
      debug("else: ", string)
      string
    end
  end

  def rollDiceCommand(command)
    debug("rollDiceCommand begin string", command)

    result = ''

    # ev roll difficults
    ev_kids_pattern = %r{^(?:ev|EV|Ev)(\d+)(?:@|\[)?[kK2](?:\])?(?:/)?(\d+)?}
    ev_easy_pattern = %r{^(?:ev|EV|Ev)(\d+)(?:@|\[)?[eE3](?:\])?(?:/)?(\d+)?}
    ev_normal_pattern = %r{^(?:ev|EV|Ev)(\d+)(?:@|\[)?[nN4](?:\])?(?:/)?(\d+)?}
    ev_hard_pattern = %r{^(?:ev|EV|Ev)(\d+)(?:@|\[)?[hH5](?:\])?(?:/)?(\d+)?}
    ev_ultrahard_pattern = %r{^(?:ev|EV|Ev)(\d+)(?:@|\[)?(?:uh|UH|Uh|6)(?:\])?(?:/)?(\d+)?}
    ev_short_pattern = %r{^(?:ev|EV|Ev)(\d+)(?:/)?(\d+)?$}

    # combat attack difficults
    at_kids_pattern = /^(?:at|AT|At)(\d+)(?:@|\[)?[kK2](?:\])?/
    at_easy_pattern = /^(?:at|AT|At)(\d+)(?:@|\[)?[eE3](?:\])?/
    at_normal_pattern = /^(?:at|AT|At)(\d+)(?:@|\[)?[nN4](?:\])?/
    at_hard_pattern = /^(?:at|AT|At)(\d+)(?:@|\[)?[hH5](?:\])?/
    at_ultrahard_pattern = /^(?:at|AT|At)(\d+)(?:@|\[)?(?:uh|UH|Uh|6)(?:\])?/
    at_short_pattern = /^(?:at|AT|At)(\d+)$/

    case command
    # EV evaluate
    when ev_kids_pattern
      debug('ev kids: ', command)

      dice_cnt = Regexp.last_match(1)
      suc_rate ||= Regexp.last_match(2)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 2)
      dice_str = dice[1]
      suc_cnt = dice[5]
      counter_karate = false

      if !suc_rate.nil? && suc_cnt > suc_rate.to_i
        debug('counter karate: true')
        counter_karate = true
      end

      result += "(#{Regexp.last_match(1)}B6>=2) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if counter_karate
        result += " ＞ カウンターカラテ!!"
      end
    when ev_easy_pattern
      debug('ev easy: ', command)

      dice_cnt = Regexp.last_match(1)
      suc_rate ||= Regexp.last_match(2)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 3)
      dice_str = dice[1]
      suc_cnt = dice[5]
      counter_karate = false

      if !suc_rate.nil? && suc_cnt > suc_rate.to_i
        debug('counter karate: true')
        counter_karate = true
      end

      result += "(#{Regexp.last_match(1)}B6>=3) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if counter_karate
        result += " ＞ カウンターカラテ!!"
      end
    when ev_normal_pattern
      debug('ev normal: ', command)

      dice_cnt = Regexp.last_match(1)
      suc_rate ||= Regexp.last_match(2)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 4)
      dice_str = dice[1]
      suc_cnt = dice[5]
      counter_karate = false

      if !suc_rate.nil? && suc_cnt > suc_rate.to_i
        debug('counter karate: true')
        counter_karate = true
      end

      result += "(#{Regexp.last_match(1)}B6>=4) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if counter_karate
        result += " ＞ カウンターカラテ!!"
      end
    when ev_hard_pattern
      debug('ev hard: ', command)

      dice_cnt = Regexp.last_match(1)
      suc_rate ||= Regexp.last_match(2)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 5)
      dice_str = dice[1]
      suc_cnt = dice[5]
      counter_karate = false

      if !suc_rate.nil? && suc_cnt > suc_rate.to_i
        debug('counter karate: true')
        counter_karate = true
      end

      result += "(#{Regexp.last_match(1)}B6>=5) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if counter_karate
        result += " ＞ カウンターカラテ!!"
      end
    when ev_ultrahard_pattern
      debug('ev ultrahard: ', command)

      dice_cnt = Regexp.last_match(1)
      suc_rate ||= Regexp.last_match(2)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 6)
      dice_str = dice[1]
      suc_cnt = dice[5]
      counter_karate = false

      if !suc_rate.nil? && suc_cnt > suc_rate.to_i
        debug('counter karate: true')
        counter_karate = true
      end

      result += "(#{Regexp.last_match(1)}B6>=6) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if counter_karate
        result += " ＞ カウンターカラテ!!"
      end
    when ev_short_pattern
      debug('ev short: ', command)

      dice_cnt = Regexp.last_match(1)
      suc_rate ||= Regexp.last_match(2)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 4)
      dice_str = dice[1]
      suc_cnt = dice[5]
      counter_karate = false

      if !suc_rate.nil? && suc_cnt > suc_rate.to_i
        debug('counter karate: true')
        counter_karate = true
      end

      result += "(#{Regexp.last_match(1)}B6>=4) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if counter_karate
        result += " ＞ カウンターカラテ!!"
      end

    # AT evaluate
    when at_kids_pattern
      debug('at kids: ', command)

      dice_cnt = Regexp.last_match(1)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 2)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice_str.scan('6').size

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=2) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += " ＞ サツバツ!!"
      end
    when at_easy_pattern
      debug('at easy: ', command)

      dice_cnt = Regexp.last_match(1)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 3)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice_str.scan('6').size

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=3) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += " ＞ サツバツ!!"
      end
    when at_normal_pattern
      debug('at normal: ', command)

      dice_cnt = Regexp.last_match(1)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 4)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice_str.scan('6').size

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=4) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += " ＞ サツバツ!!"
      end
    when at_hard_pattern
      debug('at hard: ', command)

      dice_cnt = Regexp.last_match(1)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 5)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice_str.scan('6').size

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=5) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += " ＞ サツバツ!!"
      end
    when at_ultrahard_pattern
      debug('at ultrahard: ', command)

      dice_cnt = Regexp.last_match(1)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 6)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice_str.scan('6').size

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=6) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += " ＞ サツバツ!!"
      end
    when at_short_pattern
      debug('at short: ', command)

      dice_cnt = Regexp.last_match(1)
      dice = roll(Regexp.last_match(1), 6, 0, 0, '>=', 4)
      dice_str = dice[1]
      suc_cnt = dice[5]
      satsubatsu = false

      six_cnt = dice_str.scan('6').size

      if six_cnt >= 2
        satsubatsu = true
      end

      result += "(#{dice_cnt}B6>=4) ＞ #{dice_str} ＞ 成功数#{suc_cnt}"
      if satsubatsu
        result += " ＞ サツバツ!!"
      end

    else
      debug('rollDiceCommand else: ', command)
      result = command
    end

    return result
  end
end
