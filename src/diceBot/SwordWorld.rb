#--*-coding:utf-8-*--


class SwordWorld < DiceBot
  
  def initialize(rating_table)
    super()
    @rating_table = rating_table;
  end
  
  def gameType
    if( @rating_table == 2)
      return "SwordWorld2.0"
    end

    "SwordWorld"
  end
  
  def getHelpMessage
    '・SW　レーティング表　　　　　(Kx[c]+m$f) (x:キー, c:クリティカル値, m:ボーナス, f:出目修正)'
  end
  
  def changeText(string)
    return string unless( /(^|\s)(K[\d]+)/i =~ string )
    
    debug('parren_killer_add before string', string)
    string = string.gsub(/\[(\d+)\]/i) {"c[#{$1}]"}
    string = string.gsub(/\@(\d+)/i) {"c[#{$1}]"}
    string = string.gsub(/\$([\+\-]?[\d]+)/i) {"m[#{$1}]"}
    debug('parren_killer_add after string', string)
    
    return string
  end
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    unless ( /(^|\s)(S)?K[\d\+\-]+/i =~ string )
      return '1', secret_flg
    end
    
    debug("ソードワールドのレーティング表ロール検出")
    
    secretMarker = $2
    output_msg = rating(string, nick_e);
    if( secretMarker )
      debug("隠しロール")
      secret_flg = true if(output_msg != '1');
    end
    
    debug("rating output_msg, secret_flg", output_msg, secret_flg)
    
    return output_msg, secret_flg
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    if(dice_n >= 12)
      return " ＞ 自動的成功";
    end
    
    if(dice_n <=2)
      return " ＞ 自動的失敗";
    end
    
    return '' if(signOfInequality != ">=")
    return '' if(diff == "?")
    
    if(total_n >= diff)
      return " ＞ 成功";
    end
    
    return " ＞ 失敗";
  end
  
  ####################        SWレーティング表       ########################
  def rating(string, nick_e)     # レーティング表
    key = nil
    dice, output, dice_str, mod  = []
    key_max = 0
    dicestr_wk = 0
    rate_wk = 0
    dice_wk = ""
    rate_str = ""
    dice_add = 0
    
    add_p = "";
    dec_p = "";
    total_n = 0;
    round = 0;
    dice_f = 0;
    crit = 10;
    
    unless(/(^|\s)[sS]?(((k|K)[\d\+\-]+)([cmCM]\[([\d\+\-]+)\])*([\d\+\-]*)([cmCM]\[([\d\+\-]+)\])*)($|\s)/ =~ string)
      debug("not matched")
      return '1';
    end
    
    string = $2;
    if( /c\[(\d+)\]/i =~ string )
      crit = $1.to_i
      crit = 3 if(crit < 3);        # エラートラップ(クリティカル値が3未満なら3とする)
      string = string.gsub(/c\[(\d+)\]/i, '')
    end
    
    if( /m\[([\d\+\-]+)\]/i =~ string )
      mod = $1;
      unless(/[\+\-]/ =~ mod)
        dice_f = mod.to_i;
        mod = 0;
      end
      string = string.gsub(/m\[([\d\+\-]+)\]/i, '')
    end
    
    if(/K(\d+)([\d\+\-]*)/i =~ string)    # ボーナスの抽出
      key = $1;
      if($2)
        add_p = parren_killer("(" + $2 + ")").to_i
      end
    else
      key = string;
    end
    
    unless( key =~ /([\d]+)/ )
      return '1'
    end
    key = $1.to_i
    
    # 2.0対応
    rate_sw2_0 = [
                  #0
                  '*,0,0,0,1,2,2,3,3,4,4',
                  '*,0,0,0,1,2,3,3,3,4,4',
                  '*,0,0,0,1,2,3,4,4,4,4',
                  '*,0,0,1,1,2,3,4,4,4,5',
                  '*,0,0,1,2,2,3,4,4,5,5',
                  '*,0,1,1,2,2,3,4,5,5,5',
                  '*,0,1,1,2,3,3,4,5,5,5',
                  '*,0,1,1,2,3,4,4,5,5,6',
                  '*,0,1,2,2,3,4,4,5,6,6',
                  '*,0,1,2,3,3,4,4,5,6,7',
                  '*,1,1,2,3,3,4,5,5,6,7',
                  #11    
                  '*,1,2,2,3,3,4,5,6,6,7',
                  '*,1,2,2,3,4,4,5,6,6,7',
                  '*,1,2,3,3,4,4,5,6,7,7',
                  '*,1,2,3,4,4,4,5,6,7,8',
                  '*,1,2,3,4,4,5,5,6,7,8',
                  '*,1,2,3,4,4,5,6,7,7,8',
                  '*,1,2,3,4,5,5,6,7,7,8',
                  '*,1,2,3,4,5,6,6,7,7,8',
                  '*,1,2,3,4,5,6,7,7,8,9',
                  '*,1,2,3,4,5,6,7,8,9,10',
                  #21
                  '*,1,2,3,4,6,6,7,8,9,10',
                  '*,1,2,3,5,6,6,7,8,9,10',
                  '*,2,2,3,5,6,7,7,8,9,10',
                  '*,2,3,4,5,6,7,7,8,9,10',
                  '*,2,3,4,5,6,7,8,8,9,10',
                  '*,2,3,4,5,6,8,8,9,9,10',
                  '*,2,3,4,6,6,8,8,9,9,10',
                  '*,2,3,4,6,6,8,9,9,10,10',
                  '*,2,3,4,6,7,8,9,9,10,10',
                  '*,2,4,4,6,7,8,9,10,10,10',
                  #31
                  '*,2,4,5,6,7,8,9,10,10,11',
                  '*,3,4,5,6,7,8,10,10,10,11',
                  '*,3,4,5,6,8,8,10,10,10,11',
                  '*,3,4,5,6,8,9,10,10,11,11',
                  '*,3,4,5,7,8,9,10,10,11,12',
                  '*,3,5,5,7,8,9,10,11,11,12',
                  '*,3,5,6,7,8,9,10,11,12,12',
                  '*,3,5,6,7,8,10,10,11,12,13',
                  '*,4,5,6,7,8,10,11,11,12,13',
                  '*,4,5,6,7,9,10,11,11,12,13',
                  #41
                  '*,4,6,6,7,9,10,11,12,12,13',
                  '*,4,6,7,7,9,10,11,12,13,13',
                  '*,4,6,7,8,9,10,11,12,13,14',
                  '*,4,6,7,8,10,10,11,12,13,14',
                  '*,4,6,7,9,10,10,11,12,13,14',
                  '*,4,6,7,9,10,10,12,13,13,14',
                  '*,4,6,7,9,10,11,12,13,13,15',
                  '*,4,6,7,9,10,12,12,13,13,15',
                  '*,4,6,7,10,10,12,12,13,14,15',
                  '*,4,6,8,10,10,12,12,13,15,15',
                  #51
                  '*,5,7,8,10,10,12,12,13,15,15',
                  '*,5,7,8,10,11,12,12,13,15,15',
                  '*,5,7,9,10,11,12,12,14,15,15',
                  '*,5,7,9,10,11,12,13,14,15,16',
                  '*,5,7,10,10,11,12,13,14,16,16',
                  '*,5,8,10,10,11,12,13,15,16,16',
                  '*,5,8,10,11,11,12,13,15,16,17',
                  '*,5,8,10,11,12,12,13,15,16,17',
                  '*,5,9,10,11,12,12,14,15,16,17',
                  '*,5,9,10,11,12,13,14,15,16,18',
                  #61
                  '*,5,9,10,11,12,13,14,16,17,18',
                  '*,5,9,10,11,13,13,14,16,17,18',
                  '*,5,9,10,11,13,13,15,17,17,18',
                  '*,5,9,10,11,13,14,15,17,17,18',
                  '*,5,9,10,12,13,14,15,17,18,18',
                  '*,5,9,10,12,13,15,15,17,18,19',
                  '*,5,9,10,12,13,15,16,17,19,19',
                  '*,5,9,10,12,14,15,16,17,19,19',
                  '*,5,9,10,12,14,16,16,17,19,19',
                  '*,5,9,10,12,14,16,17,18,19,19',
                  #71
                  '*,5,9,10,13,14,16,17,18,19,20',
                  '*,5,9,10,13,15,16,17,18,19,20',
                  '*,5,9,10,13,15,16,17,19,20,21',
                  '*,6,9,10,13,15,16,18,19,20,21',
                  '*,6,9,10,13,16,16,18,19,20,21',
                  '*,6,9,10,13,16,17,18,19,20,21',
                  '*,6,9,10,13,16,17,18,20,21,22',
                  '*,6,9,10,13,16,17,19,20,22,23',
                  '*,6,9,10,13,16,18,19,20,22,23',
                  '*,6,9,10,13,16,18,20,21,22,23',
                  #81
                  '*,6,9,10,13,17,18,20,21,22,23',
                  '*,6,9,10,14,17,18,20,21,22,24',
                  '*,6,9,11,14,17,18,20,21,23,24',
                  '*,6,9,11,14,17,19,20,21,23,24',
                  '*,6,9,11,14,17,19,21,22,23,24',
                  '*,7,10,11,14,17,19,21,22,23,25',
                  '*,7,10,12,14,17,19,21,22,24,25',
                  '*,7,10,12,14,18,19,21,22,24,25',
                  '*,7,10,12,15,18,19,21,22,24,26',
                  '*,7,10,12,15,18,19,21,23,25,26',
                  #91
                  '*,7,11,13,15,18,19,21,23,25,26',
                  '*,7,11,13,15,18,20,21,23,25,27',
                  '*,8,11,13,15,18,20,22,23,25,27',
                  '*,8,11,13,16,18,20,22,23,25,28',
                  '*,8,11,14,16,18,20,22,23,26,28',
                  '*,8,11,14,16,19,20,22,23,26,28',
                  '*,8,12,14,16,19,20,22,24,26,28',
                  '*,8,12,15,16,19,20,22,24,27,28',
                  '*,8,12,15,17,19,20,22,24,27,29',
                  '*,8,12,15,18,19,20,22,24,27,30',
                 ]
    
    key_max = rate_sw2_0.length
    
    
    rate_3 = []
    rate_4 = []
    rate_5 = []
    rate_6 = []
    rate_7 = []
    rate_8 = []
    rate_9 = []
    rate_10 = []
    rate_11 = []
    rate_12 = []
    zeroArray = []
    
    rate_sw2_0.each do |rate_wk|
      rate_arr = rate_wk.split(/,/)
      zeroArray.push( 0 )
      rate_3.push( rate_arr[1].to_i )
      rate_4.push( rate_arr[2].to_i )
      rate_5.push( rate_arr[3].to_i )
      rate_6.push( rate_arr[4].to_i )
      rate_7.push( rate_arr[5].to_i )
      rate_8.push( rate_arr[6].to_i )
      rate_9.push( rate_arr[7].to_i )
      rate_10.push( rate_arr[8].to_i )
      rate_11.push( rate_arr[9].to_i )
      rate_12.push( rate_arr[10].to_i )
    end
    
    if(@rating_table == 1)
      # 完全版準拠に差し替え
      rate_12[31] = rate_12[32] = rate_12[33] = 10;
    end
    
    newRates = [zeroArray, zeroArray, zeroArray, rate_3, rate_4, rate_5, rate_6, rate_7, rate_8, rate_9, rate_10, rate_11, rate_12];
    
    if(key > key_max)
      return "キーナンバーは#{key_max}までです";
    end
    
    output = "#{nick_e}: KeyNo.#{key}";
    output += "c[#{crit}]" if(crit < 13);
    
    if( (not mod.nil?) and (mod != 0) )
      debug('mod', mod)
      output += "m[#{mod}]";
    elsif( dice_f != 0)
      debug( 'dice_f', dice_f )
      output += "m[#{dice_f}]";
    end
    debug('output', output);
    
    if( add_p )
      output += "+#{add_p}" if(add_p > 0);
      output +=  "#{add_p}" if(add_p < 0);
    end
    
    output += " ＞ ";
    
    dice_wk = "";
    
    begin
      dice, dice_str = roll(2, 6);
      
      if( dice_f != 0 )
        dice = dice_f;
        dice_f = 0;
        dice = 2 if(dice < 2);
        dice = 12 if(dice > 12);
      elsif( mod )
        dice += mod.to_i;
        mod = 0;
        dice = 2 if(dice < 2);
        dice = 12 if(dice > 12);
      end
      
      rate_wk = newRates[dice][key];
      
      total_n += rate_wk;
      dice_add += dice;
      
      if(dice_wk != "")
        dice_wk += ",#{dice}";
        dicestr_wk += " #{dice_str}";
        if(dice > 2)
          rate_str += ",#{rate_wk}";
        else 
          rate_str += ",**";
        end
      else 
        dice_wk = "#{dice}";
        dicestr_wk = dice_str;
        if(dice > 2)
          rate_str += rate_wk.to_s;
        else 
          rate_str += "**";
        end
      end
      
      round += 1;
    end while(dice >= crit);
    
    if(sendMode > 1)           # 表示モード２以上
      output += "2D:[#{dicestr_wk}]=#{dice_wk} ＞ #{rate_str}";
    elsif(sendMode > 0)  # 表示モード１以上
      output += "2D:#{dice_wk} ＞ #{total_n}";
    else                     # 表示モード０
      output += "#{total_n}";
    end
    if(dice_add <= 2) 
      return "#{output} ＞ 自動的失敗";
    end
    
    if( add_p != 0 )
      output += "+#{add_p}" if(add_p > 0);
      output +=  "#{add_p}" if(add_p < 0);
      total_n += add_p;
      output += " ＞ #{total_n}";
    end
    
    if (round > 1) 
      round -= 1;   # ここでは「回転数=クリティカルの出た数」とする
      output += " ＞ #{round}回転";
    end
    
    if ( output.length > $SEND_STR_MAX)   # 回りすぎて文字列オーバーフロウしたときの救済
      if(crit < 13) 
        output = "#{nick_e}: KeyNo.#{key}[#{crit}] ＞ ... ＞ #{total_n} ＞ #{round}回転";
      else 
        output = "#{nick_e}: KeyNo.#{key} ＞ ... ＞ #{total_n} ＞ #{round}回転";
      end
    end
    
    return output;
    
  end
  
  
  def setRatingTable(nick_e, tnick, channel_to_list)
    mode_str = ""
    pre_mode = @rating_table;
    
    if( /(\d+)/ =~ tnick )
      @rating_table = $1.to_i;
      if (@rating_table > 1)
        mode_str = "2.0-mode";
        @rating_table = 2;
      elsif (@rating_table > 0)
        mode_str = "new-mode";
        @rating_table = 1;
      else
        mode_str = "old-mode";
        @rating_table = 0;
      end
    else
      case tnick
      when /old/i
        @rating_table = 0;
        mode_str = "old-mode";
      when /new/i
        @rating_table = 1;
        mode_str = "new-mode";
      when /2\.0/i
        @rating_table = 2;
        mode_str = "2.0-mode";
      end
    end
    
    
    return '1' if( @rating_table == pre_mode )
    
    return "RatingTableを#{mode_str}に変更しました"
  end

end
