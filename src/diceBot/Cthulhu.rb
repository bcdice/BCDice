#--*-coding:utf-8-*--

class Cthulhu < DiceBot
  
  def gameName
    'クトゥルフ'
  end
  
  def gameType
    "Cthulhu"
  end
  
  def prefixs
     ['RES.*', 'CBR\(\d+,\d+\)']
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
・1D100の目標値判定で、クリティカル(決定的成功)／スペシャル／ファンブル(致命的失敗)の自動判定。
　例）1D100<=50
　　　Cthulhu : (1D100<=50) → 96 → 致命的失敗

・抵抗ロール　(RES(x-n))
　RES(自分の能力値-相手の能力値)で記述します。
　抵抗ロールに変換して成功したかどうかを表示します。
　例）RES(12-10)
　　　Cthulhu : (1d100<=60) → 35 → 成功

・組み合わせ判定　(CBR(x,y))
　目標値 x と y で％ロールを行い、成功したかどうかを表示します。
　例）CBR(50,20)
　　　Cthulhu : (1d100<=70,20) → 22[成功,失敗] → 失敗
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    # CoC抵抗表コマンド
    case command
    when /RES/i
      return getRegistResult(command)
    when /CBR/i
      return getCombineRoll(command)
    end
    
    return nil
  end
  
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless(signOfInequality == "<=")
    
    return ' ＞ ' + getCheckResultText(total_n, diff)
  end
  
  def getCheckResultText(total_n, diff)
    if((total_n <= diff) and (total_n < 100))
      
      if(total_n <= 5)
        if(total_n <= (diff / 5))
          return "決定的成功/スペシャル"
        end
        return "決定的成功"
      end
      
      if(total_n <= (diff / 5))
        return "スペシャル"
      end
      
      return "成功"
    end
    
    if((total_n >= 96) and (diff < 100))
      return "致命的失敗"
    end
    
    return "失敗"
  end
  
  
  def getRegistResult(command)
    output = "1"
    
    return output unless(/res([-\d]+)/i =~ command)
    
    value = $1.to_i
    target =  value * 5 + 50
    
    if(target < 5)    # 自動失敗
      return "(1d100<=#{target}) ＞ 自動失敗"
    end
    
    if(target > 95)  # 自動成功
      return "(1d100<=#{target}) ＞ 自動成功"
    end
    
    # 通常判定
    total_n, dice_dmy = roll(1, 100)
    if(total_n <= target)
      return "(1d100<=#{target}) ＞ #{total_n} ＞ 成功"
    end
    
    return "(1d100<=#{target}) ＞ #{total_n} ＞ 失敗"
  end
  
  
  def getCombineRoll(command)
    output = "1"
    
    return output unless(/CBR\((\d+),(\d+)\)/i =~ command)
    
    diff_1 = $1.to_i
    diff_2 = $2.to_i
    
    total, dummy = roll(1, 100)
    
    result_1 = getCheckResultText(total, diff_1)
    result_2 = getCheckResultText(total, diff_2)
    
    ranks = ["決定的成功/スペシャル", "決定的成功", "スペシャル", "成功", "失敗", "致命的失敗"]
    rankIndex_1 = ranks.index(result_1)
    rankIndex_2 = ranks.index(result_2)
    
    rankIndex = [rankIndex_1, rankIndex_2].max
    rank = ranks[rankIndex]
    
    return "(1d100<=#{diff_1},#{diff_2}) ＞ #{total}[#{result_1},#{result_2}] ＞ #{rank}"
  end
  
end
