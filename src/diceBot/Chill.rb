#--*-coding:utf-8-*--

class Chill < DiceBot
  def gameType
    "Chill"
  end
  
  def getHelpMessage
    "・CHILL　ストライクランク　 　(SRx)"
  end
  
  def dice_command(arg, nick_e)
    secret_flg = false
    
    # ストライクランク計算
    unless( /(^|\s)(S)?SR(\d+)($|\s)/i =~ arg )
      return '1', secret_flg
    end
    
    secretMarker = $2
    output_msg = strike_rank(arg, nick_e);
    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    
    return output_msg, secret_flg
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)     # ゲーム別成功度判定(1D10)
    return '' if(signOfInequality != "<=")
    
    if(total_n >= 100)
      return " ＞ ファンブル"
    end
    
    if(total_n <= diff)
      if(total_n >= (diff * 0.9))
        return " ＞ Ｌ成功";
      end
      if(total_n >= (diff / 2))
        return " ＞ Ｍ成功";
      end
      if(total_n >= (diff / 10))
        return " ＞ Ｈ成功";
      end
      return " ＞ Ｃ成功";
    end
    
    return " ＞ 失敗";
  end
  

####################    CHILLストライクランク表    ########################
  def strike_rank(string, nick_e)    # Chillのストライクランク
    debug('strike_rank begin')
    
    output = ''
    wounds = 0
    sta_loss = 0
    dice = ''
    dice_add = ""
    dice_str = ""
    
    unless( /(^|\s)[sS]?(SR|sr)(\d+)($|\s)/ =~ string )
      debug('invalid string', string)
      return "1";
    end
    
    strikeRank = $3.to_i
    dice_w = ''
    dice_ws = ''
    dice_wa = ''

    if(strikeRank < 14)
      sta_loss, dice, dice_add, dice_str = chill_sr( strikeRank );
      wounds, dice_w, dice_wa, dice_ws = chill_sr(strikeRank - 3);
      dice = dice + ', ' + dice_w;
      dice_add += ', ' + dice_wa;
      dice_str = dice_str + ', ' + dice_ws;
    else 
      wounds_wk = 0
      sta_loss, dice, dice_add, dice_str = chill_sr(13);
      wounds, dice_ws = roll(4, 10);
      dice = '5d10*3, 4d10+' + ((strikeRank - 13) * 2).to_s + 'd10';
      dice_add += ', ' + wounds.to_s;
      dice_str = "#{dice_str}, #{dice_ws.to_s}";
      wounds_wk, dice_ws = roll((strikeRank - 13) * 2, 10);
      dice_str += "+#{dice_ws}";
      dice_add += "+#{wounds_wk}";
        wounds += wounds_wk;
    end
    
    if(sendMode > 1)
      output = "#{dice_str} ＞ #{dice_add} ＞ スタミナ損失#{sta_loss}, 負傷#{wounds}";
    elsif(sendMode > 0)
      output = "#{dice_add} ＞ スタミナ損失#{sta_loss}, 負傷#{wounds}";
    else
      output = 'スタミナ損失' + sta_loss + ', 負傷' + wounds;
    end
    
    string += ':' + dice
    
    if( output.empty? )
        return "1";
    end
    
    output = "#{nick_e}: (#{string}) ＞ #{output}";
    debug('strike_rank end output', output)
    return output;
  end
  
  def chill_sr(strikeRank)
    strikeRank = strikeRank.to_i
    
    dice = ''
    dice_add = ''
    dice_str = ''
    damage = 0

    if(strikeRank < 1)
      damage = 0;
      dice_str = '-';
      dice_add = '-';
      dice = '-';
      
    elsif(strikeRank < 2)
      dice = '0or1';
      damage, dice_str = roll(1, 2);
      damage -= 1;
      dice_add = damage.to_s
    
    elsif(strikeRank < 3)
      dice = '1or2';
      damage, dice_str = roll(1, 2);
      dice_add = damage.to_s
    
    elsif(strikeRank < 4)
      dice = '1d5';
      damage, dice_str = roll(1, 5);
      dice_add = damage.to_s
    
    elsif(strikeRank < 10)
      dice = (strikeRank - 3).to_s + 'd10';
      damage, dice_str = roll(strikeRank - 3, 10);
      dice_add = damage.to_s
    
    elsif(strikeRank < 13)
      dice = (strikeRank - 6).to_s + 'd10*2';
      damage, dice_str = roll(strikeRank - 6, 10);
      dice_add = damage.to_s + '*2';
      damage = damage * 2;
      dice_str = "(#{dice_str})*2";
    else
      dice = '5d10*3';
      damage, dice_str = roll(5, 10);
      dice_add = damage.to_s + '*3';
      damage = damage * 3;
      dice_str = "(#{dice_str})*3";
    end
    
    return damage, dice, dice_add, dice_str
  end


end
