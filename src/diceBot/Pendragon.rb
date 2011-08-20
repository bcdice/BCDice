#--*-coding:utf-8-*--

class Pendragon < DiceBot
  
  def gameType
    "Pendragon"
  end
  
  def check_1D20(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)     # ゲーム別成功度判定(1d20)
    return '' unless(signOfInequality == "<=")
    
    if(total_n <= diff)
      if((total_n >= (40 - diff)) or (total_n == diff))
        return " ＞ クリティカル";
      end
      
      return " ＞ 成功";
    else
      if(total_n == 20)
        return " ＞ ファンブル";
      end
      
      return " ＞ 失敗";
    end
  end
  
  
end
