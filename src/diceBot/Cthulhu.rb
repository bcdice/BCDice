#--*-coding:utf-8-*--

class Cthulhu < DiceBot
  def gameType
    "Cthulhu"
  end
  
  def getHelpMessage
    "・クトゥルフ　抵抗ロール　  　(RES(x1-x2)) (x1は自分の能力値, x2は相手の能力値)"
  end
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    return '1', secret_flg unless(/(^|\s)(S)?(RES[\-\d]+|CBR\(\d+,\d+\))($|\s)/i  =~ string)
    
    # CoC抵抗表コマンド
    command = $3.upcase
    secretMarker = $2
    
    case command
    when /RES/i
      output_msg = getRegistResult(command)
    when /CBR/i
      output_msg = getCombineRoll(command)
    end
    
    if( output_msg != '1' )
      output_msg = "#{nick_e}: #{output_msg}"
    end

    
    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    return output_msg, secret_flg
  end
  
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless(signOfInequality == "<=")
    
    return ' ＞ ' + getCheckResultText(total_n, diff)
  end
  
  def getCheckResultText(total_n, diff)
    if((total_n <= diff) and (total_n < 100))
      
      if(total_n <= 5)
        if(total_n <= (diff / 5))
          return "決定的成功/スペシャル";
        end
        return "決定的成功";
      end
      
      if(total_n <= (diff / 5))
        return "スペシャル";
      end
      
      return "成功";
    end
    
    if((total_n >= 96) and (diff < 100))
      return "致命的失敗";
    end
    
    return "失敗";
  end
  
  
  def getRegistResult(command)
    output = "1";
    
    return output unless(/res([-\d]+)/i =~ command)
    
    value = $1.to_i
    target =  value * 5 + 50;
    
    if(target < 5)    # 自動失敗
      return "(1d100<=#{target}) ＞ 自動失敗";
    end
    
    if(target > 95)  # 自動成功
      return "(1d100<=#{target}) ＞ 自動成功";
    end
    
    # 通常判定
    total_n, dice_dmy = roll(1, 100);
    if(total_n <= target)
      return "(1d100<=#{target}) ＞ #{total_n} ＞ 成功";
    end
    
    return "(1d100<=#{target}) ＞ #{total_n} ＞ 失敗";
  end
  
  
  def getCombineRoll(command)
    output = "1";
    
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
