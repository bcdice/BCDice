#--*-coding:utf-8-*--

class Arianrhod < DiceBot
  
  def initialize
    super
    @sendMode = 2;
    @sortType = 1;
    @d66Type = 1;
  end
  
  def gameType
    "Arianrhod"
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
  end
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    debug("check_nD6 begin")
    
    if(n1 >= dice_cnt)  # 全部１の目ならファンブル
      return " ＞ ファンブル";
    elsif(n_max >= 2)  # ２個以上６の目があったらクリティカル
      return " ＞ クリティカル(+#{n_max}D6)";
    elsif(signOfInequality == ">=")
      if(diff != "?")
        if(total_n >= diff)
          return " ＞ 成功";
        else
          return " ＞ 失敗";
        end
      end
    end
    
    return ''
  end
  
end
