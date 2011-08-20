#--*-coding:utf-8-*--

class InfiniteFantasia < DiceBot
  
  def gameType
    "Infinite Fantasia";
  end
  
  def check_1D20(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)     # ゲーム別成功度判定(1d20)
    return '' unless(signOfInequality == "<=")
    
    unless(total_n <= diff) 
      return " ＞ 失敗";
    end
    
    critical = ""
    if(total_n <= 1)
      critical = "/クリティカル";
    end
    
    if(total_n <= (diff / 32))
      return " ＞ 32レベル成功(32Lv+)#{critical}";
    elsif(total_n <= (diff / 16))
      return " ＞ 16レベル成功(16LV+)#{critical}";
    elsif(total_n <= (diff / 8))
      return " ＞ 8レベル成功#{critical}";
    elsif(total_n <= (diff / 4))
      return " ＞ 4レベル成功#{critical}";
    elsif(total_n <= (diff / 2))
      return " ＞ 2レベル成功#{critical}";
    end
    
    return " ＞ 1レベル成功#{critical}";
    
  end
  
end
