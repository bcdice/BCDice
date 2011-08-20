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
    
    return '1', secret_flg unless(/((^|\s)(S)?RES[\-\d]+)($|\s)/i  =~ string)
    
    # CoC抵抗表コマンド
    command = $1.upcase
    secretMarker = $3
    output_msg = coc_res(command, nick_e);
    
    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    return output_msg, secret_flg
  end
  
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless(signOfInequality == "<=")
    
    if((total_n <= diff) and (total_n < 100))
      
      if(total_n <= 5)
        if(total_n <= (diff / 5))
          return " ＞ 決定的成功/スペシャル";
        end
        return " ＞ 決定的成功";
      end
      
      if(total_n <= (diff / 5))
        return " ＞ スペシャル";
      end
      
      return " ＞ 成功";
    end
    
    if((total_n >= 96) and (diff < 100))
      return " ＞ 致命的失敗";
    end
    
    return " ＞ 失敗";
  end
  
####################         Call Of Cthulhu        ########################
  def coc_res(string, nick_e)    # CoCの抵抗ロール
    output = "1";
    
    return output unless(/res([-\d]+)/i =~ string)
    
    value = $1.to_i
    target =  value * 5 + 50;
    
    if(target < 5)    # 自動失敗
      return "#{nick_e}: (1d100<=#{target}) ＞ 自動失敗";
    end
    
    if(target > 95)  # 自動成功
      return "#{nick_e}: (1d100<=#{target}) ＞ 自動成功";
    end
    
    # 通常判定
    total_n, dice_dmy = roll(1, 100);
    if(total_n <= target)
      return "#{nick_e}: (1d100<=#{target}) ＞ #{total_n} ＞ 成功";
    end
    
    return "#{nick_e}: (1d100<=#{target}) ＞ #{total_n} ＞ 失敗";
  end
  
end
