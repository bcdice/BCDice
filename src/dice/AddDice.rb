#--*-coding:utf-8-*--


class AddDice
  
  def initialize(bcdice, diceBot)
    @bcdice = bcdice
    @diceBot = diceBot
    @nick_e = @bcdice.nick_e
  end
  
  ####################             加算ダイス        ########################  

  def rollDice(string)
    debug("AddDice.rollDice() begin string", string)
    
    dice_cnt = 0;
    dice_max = 0;
    total_n = 0;
    dice_n = 0;
    output = "";
    n1 = 0;
    n_max = 0;
    isCheckSuccess = false;
    
    unless( /(^|\s)S?(([\d\+\*\-]*[\d]+D[\d]*[\d\+\*\-D]*)(([<>=]+)([?\-\d]+))?)($|\s)/ =~ string )
      return "1";
    end
    
    string = $2;
    judgeText = $4 # '>=10'といった成否判定文字
    judgeOperator = $5 # '>=' といった判定の条件演算子 文字
    diffText = $6
    
    signOfInequality = "";
    if( judgeText )
      debug("judgeText", judgeText)
      signOfInequality = @bcdice.marshalSignOfInequality(judgeOperator);
      diffText = $6
      string = $3;
      isCheckSuccess = true;
    end
    
    addUpTextList = string.split(/\+/)
    
    addUpTextList.each do |addUpText|
      
      subtractTextList = addUpText.split(/-/)
      
      subtractTextList.each_with_index do |subtractText, index|
        next if( subtractText.empty? )
        
        debug("begin rollDiceAddingUp(subtractText, isCheckSuccess)", subtractText, isCheckSuccess)
        dice_now, dice_n_wk, dice_str, n1_wk, n_max_wk, cnt_wk, max_wk = rollDiceAddingUp(subtractText, isCheckSuccess);
        debug("end rollDiceAddingUp(subtractText, isCheckSuccess) -> dice_now", dice_now)
        
        #return "1" if(dice_now <= 0)
        
        rate = (index == 0 ? 1 : -1)
        
        total_n += (dice_now) * rate;
        dice_n += dice_n_wk * rate;
        n1 += n1_wk;
        n_max += n_max_wk;
        dice_cnt += cnt_wk;
        dice_max = max_wk if(max_wk > dice_max);
        
        next if(@diceBot.sendMode == 0)
        
        operatorText = getOperatorText(rate, output)
        output += "#{operatorText}#{dice_str}"
      end
    end
    
    if( signOfInequality != "" )
      string += "#{signOfInequality}#{diffText}";
    end
    
    @diceBot.setDiceText(output);
    @diceBot.setDiffText(diffText)
    
    #ダイス目による補正処理（現状ナイトメアハンターディープ専用）
    addText, revision = @diceBot.getDiceRevision(n_max, dice_max, total_n)
    debug('addText, revision', addText, revision)
    
    debug("@nick_e", @nick_e)
    if( @diceBot.sendMode > 0 )
      if( output =~ /[^\d\[\]]+/ )
        output = "#{@nick_e}: (#{string}) ＞ #{output} ＞ #{total_n}#{addText}"
      else
        output = "#{@nick_e}: (#{string}) ＞ #{total_n}#{addText}"
      end
    else
      output = "#{@nick_e}: (#{string}) ＞ #{total_n}#{addText}"
    end
    
    total_n += revision
    
    if( signOfInequality != "" )   # 成功度判定処理
      successText = @bcdice.check_suc(total_n, dice_n, signOfInequality, diffText, dice_cnt, dice_max, n1, n_max);
      debug("check_suc successText", successText)
      output += successText
    end
    
    
    #ダイスロールによるポイント等の取得処理用（T&T悪意、ナイトメアハンター・ディープ宿命、特命転校生エクストラパワーポイントなど）
    output += @diceBot.getDiceRolledAdditionalText(n1, n_max, dice_max)
    
    if( (dice_cnt == 0) or (dice_max == 0) )
      output = '1';
    end
    
    debug("AddDice.rollDice() end output", output)
    return output;
  end
  
  def rollDiceAddingUp( string, isCheckSuccess = false)   # 加算ダイスロール(個別処理)
    debug("rollDiceAddingUp() begin string", string)
    
    dice_max = 0;
    dice_total = 1;
    dice_n = 0;
    output ="";
    n1 = 0;
    n_max = 0;
    dice_cnt_total = 0;
    double_check = false
    
    if( @diceBot.sameDiceRerollCount != 0 ) # 振り足しありのゲームでダイスが二個以上
      if( @diceBot.sameDiceRerollType <= 0 )  # 判定のみ振り足し
        debug('判定のみ振り足し')
        double_check = true if( isCheckSuccess );
      elsif( @diceBot.sameDiceRerollType <= 1 ) # ダメージのみ振り足し
        debug('ダメージのみ振り足し')
        double_check = true if( not isCheckSuccess );
      else     # 両方振り足し
        double_check = true;
      end
    end
    
    debug("double_check", double_check)
    
    while(/(^([\d]+\*[\d]+)\*(.+)|(.+)\*([\d]+\*[\d]+)$|(.+)\*([\d]+\*[\d]+)\*(.+))/ =~ string)
      
      if( $2 )
        string = parren_killer('(' + $2 + ')') + '*' + $3;
      elsif( $5 )
        string = $4 + '*' + parren_killer('(' + $5 + ')');
      elsif( $7 )
        string = $6 + '*' + parren_killer('(' + $7 + ')') + '*' + $8;
      end
    end
    
    debug("string", string)
    
    mul_cmd = string.split(/\*/)
    mul_cmd.each do |mul_line|
      if( /([\d]+)D([\d]+)/ =~ mul_line )
        dice_cnt = $1.to_i;
        dice_max = $2.to_i;
        if( dice_max > $DICE_MAXNUM )
          return 0, 0, "", 0, 0, 0, 0;
        end
        
        dice_now = 0
        n1_wk = 0
        n_max_wk = 0;
        dice_str = "";
        dice_arr = []
        dice_arr.push( dice_cnt );
        
        debug("before while dice_arr", dice_arr)
        
        while( not dice_arr.empty? )
          debug("IN while dice_arr", dice_arr)
          
          dice_wk = dice_arr.shift
          dice_cnt_total += dice_wk;
          
          debug('dice_wk, dice_max, (sortType & 1)', dice_wk, dice_max, (@diceBot.sortType & 1))
          dice_dat = @bcdice.roll(dice_wk, dice_max, (@diceBot.sortType & 1));
          debug('dice_dat', dice_dat)
          
          dice_now += dice_dat[0];
          
          dice_str += "][" if( dice_str != "");
          debug('dice_str', dice_str)
          
          dice_str += dice_dat[1];
          n1_wk += dice_dat[2];
          n_max_wk += dice_dat[3];
          
          if( double_check and (dice_wk >= 2) )     # 振り足しありでダイスが二個以上
            dice_num = dice_dat[1].split(/,/).collect{|s|s.to_i}
            dice_face = []
            
            dice_max.times do |i|
              dice_face.push( 0 );
            end
            
            dice_num.each do |dice_o|
              dice_face[dice_o - 1] += 1;
            end
            
            dice_face.each do |dice_o|
              if( @diceBot.sameDiceRerollCount == 1) # 全部同じ目じゃないと振り足しなし
                dice_arr.push(dice_o) if( dice_o == dice_wk );
              else
                dice_arr.push( dice_o ) if( dice_o >= @diceBot.sameDiceRerollCount );
              end
            end
          end
        end
        
        #ダイス目文字列からダイス値を変更する場合の処理（現状クトゥルフ・テック専用）
        dice_now = @diceBot.changeDiceValueByDiceText(dice_now, dice_str, isCheckSuccess, dice_max)
        
        dice_total *= dice_now;
        dice_n += dice_now;
        n1 += n1_wk;
        n_max += n_max_wk;
        if( output != "" )
          output += "*";
        end
        if( @diceBot.sendMode > 1 )
          output += "#{dice_now}[#{dice_str}]";
        elsif( @diceBot.sendMode > 0 )
          output += "#{dice_now}";
        end
      else
        mul_line = mul_line.to_i
        debug('dice_total', dice_total)
        debug('mul_line', mul_line)
        
        dice_total *= mul_line;
        
        unless(output.empty?)
          output += "*";
        end
        
        if( mul_line < 0)
          output += "(#{mul_line})";
        else
          output += "#{mul_line}";
        end
      end
    end
    
    debug("rollDiceAddingUp() end output", dice_total, dice_n, output, n1, n_max, dice_cnt_total, dice_max)
    return dice_total, dice_n, output, n1, n_max, dice_cnt_total, dice_max;
  end
  
  def marshalSignOfInequality(*arg)
    @bcdice.marshalSignOfInequality(*arg)
  end
  
  def getOperatorText(rate, output)
    return '-' if(rate < 0)
    return '' if(output.empty?)
    return "+" 
  end
end
