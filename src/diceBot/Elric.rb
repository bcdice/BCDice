#--*-coding:utf-8-*--

class Elric < DiceBot
  
  def gameType
    "Elric!"
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless(signOfInequality == "<=")
    
    if(total_n <= 1)  # 1は常に貫通
      return " ＞ 貫通";
    end
    if(total_n >= 100)   # 100は常に致命的失敗
      return " ＞ 致命的失敗";
    end
    if(total_n <= (diff / 5 + 0.9)) 
      return " ＞ 決定的成功";
    end
    if(total_n <= diff) 
      return " ＞ 成功";
    end
    if((total_n >= 99) and (diff < 100)) 
      return " ＞ 致命的失敗";
    end
    
    return " ＞ 失敗";
  end
  
end
