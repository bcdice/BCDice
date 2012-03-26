#--*-coding:utf-8-*--

class ChaosFlare < DiceBot
  
  def gameType
    "Chaos Flare"
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    output = ''
    if(dice_n <= 2)
      total_n -= 20;
      output += " ＞ ファンブル(-20)";
    end
    
    if(signOfInequality == ">=")
      if(total_n >= diff)
        output += " ＞ 成功";
        if(total_n > diff)
          output += " ＞ 差分値#{total_n-diff}"
        end
      else
        output += " ＞ 失敗";
        output += " ＞ 差分値#{total_n-diff}"
      end
    end
    
    return output
  end
  
end
