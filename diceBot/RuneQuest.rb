#--*-coding:utf-8-*--

class RuneQuest < DiceBot
  
  def gameType
    "RuneQuest"
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return unless(signOfInequality == "<=")
    
    cliticalValue = ((1.0 * diff / 20) + 0.5)
    if((total_n <= 1) or (total_n <= cliticalValue))   # 1は常に決定的成功
      return " ＞ 決定的成功";
    end
    
    if(total_n >= 100)   # 100は常に致命的失敗
      return " ＞ 致命的失敗";
    end
    
    if(total_n <= (diff / 5 + 0.5))
      return " ＞ 効果的成功";
    end
    
    if(total_n <= diff)
      return " ＞ 成功";
    end
    
    if(total_n >= (95 + (diff / 20 + 0.5)))
      return " ＞ 致命的失敗";
    end
    
    return " ＞ 失敗";
  end
  
end
