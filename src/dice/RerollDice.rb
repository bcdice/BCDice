#--*-coding:utf-8-*--


class RerollDice
  
  def initialize(bcdice, diceBot)
    @bcdice = bcdice
    @diceBot = diceBot
    @nick_e = @bcdice.nick_e
  end
  
  ####################        個数振り足しダイス     ########################
  def rollDice(string) # 個数振り足し型ダイスロール
    debug('RerollDice.rollDice string', string)
    
    successCount = 0;
    signOfInequality = "";
    output = "";
    next_roll = 0;
    
    string = string.gsub(/-[\d]+R[\d]+/, '');   # 振り足しロールの引き算している部分をカット
    
    unless( /(^|\s)S?([\d]+R[\d\+R]+)(\[(\d+)\])?(([<>=]+)([\d]+))?(\@(\d+))?($|\s)/ =~ string )
      debug("is invaild rdice", string)
      return '1';
    end
    
    string = $2;
    
    rerollNumber_1 = $4
    rerollNumber_2 = $9
    judgeText = $5
    rerollNumber_1 = $4
    
    rerollNumber = getRerollNumber(rerollNumber_1, rerollNumber_2, judgeText)
    debug('rerollNumber', rerollNumber)
    
    diff = 0;
    if( judgeText )
      signOfInequality = @bcdice.marshalSignOfInequality( $6 );
      diff = $7.to_i;
    elsif( @diceBot.defaultSuccessTarget != "" )
      if( @diceBot.defaultSuccessTarget =~/([<>=]+)(\d+)/)
        signOfInequality = @bcdice.marshalSignOfInequality( $1 );
        diff = $2.to_i;
      end
    end
    
    debug("diff", diff)
    
    numberSpot1 = 0;
    dice_cnt_total =0;
    dice_max = 0
    
    dice_a = string.split(/\+/)
    dice_a.each do |dice_o|
      dice_cnt, dice_max = dice_o.split(/[rR]/).collect{|s|s.to_i}
      
      if( check_r(dice_max, signOfInequality, diff) )
        dice_dat = @bcdice.roll(dice_cnt, dice_max, (@diceBot.sortType & 2), 0, signOfInequality, diff, rerollNumber);
        successCount += dice_dat[5];
        output += "," if(output != "");
        output += dice_dat[1];
        next_roll += dice_dat[6];
        numberSpot1 += dice_dat[2];
        dice_cnt_total += dice_cnt;
      else
        successCount = 0;
        next_roll = 0;
        output = '条件が間違っています';
        break
      end
    end
    
    round = 0;
    output2 = "";
    
    if( next_roll > 0 )
      dice_cnt = next_roll;
      
      begin
        output2 += "#{output} + ";
        output = "";
        dice_dat = @bcdice.roll(dice_cnt, dice_max, (@diceBot.sortType & 2), 0, signOfInequality, diff, rerollNumber);
        successCount += dice_dat[5];
        output += dice_dat[1];
        round += 1;
        dice_cnt_total += dice_cnt;
        dice_cnt = dice_dat[6];
      end while ( @bcdice.isReRollAgain(dice_cnt, round) )
    end
    
    output = "#{output2}#{output} ＞ 成功数#{successCount}";
    string += "[#{rerollNumber}]#{signOfInequality}#{diff}";
    debug("string", string)
    output += @diceBot.getGrichText(numberSpot1, dice_cnt_total, successCount)
    
    output = "#{@nick_e}: (#{string}) ＞ #{output}";
    
    if( output.length > $SEND_STR_MAX )    # 長すぎたときの救済
      output = "#{@nick_e}: (#{string}) ＞ ... ＞ 回転数#{round} ＞ 成功数#{successCount}";
    end
    
    return output;
  end
  
  
  def getRerollNumber(rerollNumber_1, rerollNumber_2, judgeText)
    if( rerollNumber_1 )
      return rerollNumber_1.to_i
    elsif( rerollNumber_2 )
      return rerollNumber_2.to_i
    elsif( judgeText )
      return $7.to_i #<= 謎処理。何故 2R6>=10 の 10 がここで振り足し目標ダイス目になるのか？
    elsif( @diceBot.rerollNumber != 0 )
      return @diceBot.rerollNumber
    else
      return '条件が間違っています'
    end
  end
  
  def check_r(dice_max, signOfInequality, diff)   # 振り足しロールの条件確認
    flg = 1;
    
    case signOfInequality
    when '<='
      flg = 0 if(diff >= dice_max);
    when '>='
      flg = 0 if(diff <= 1);
    when '<>'
      flg = 0 if((diff > dice_max)||(diff < 1));
    when '<'
      flg = 0 if(diff > dice_max);
    when '>'
      flg = 0 if(diff < 1);
    end
    
    return flg;
  end
  
  
end
