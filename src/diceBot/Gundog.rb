#--*-coding:utf-8-*--

class Gundog < DiceBot
  
  def gameType
    "Gundog"
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    
    return '' unless(signOfInequality == "<=")
    
    if(total_n >= 100)
      return " ＞ ファンブル"
    end
    
    if(total_n <= 1) 
      return " ＞ 絶対成功(達成値1+SL)"
    end
    
    if(total_n <= diff)
      dig10 = (total_n / 10).to_i;
      dig1 = (total_n) - dig10 * 10;
      dig10 = 0 if(dig10 >= 10);
      dig1 = 0 if(dig1 >= 10);  # 条件的にはあり得ない(笑
      
      if(dig1 <= 0)
        return " ＞ クリティカル(達成値20+SL)";
      end
      
      return " ＞ 成功(達成値#{(dig10 + dig1)}+SL)";
    end
    
    return " ＞ 失敗";
  end
  
  def isD9
    true
  end
  
end
