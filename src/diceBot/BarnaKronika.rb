#--*-coding:utf-8-*--

class BarnaKronika < DiceBot
  
  def initialize
    super
    @sendMode = 2;
    @sortType = 3;
  end
  
  def gameType
    "BarnaKronika"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・バルナクロニカ　　一般判定　(nBK)
・　　　　　　　　　戦闘判定　(nBA)
・　　　　クリティカルコール　(nBKCt or nBACt)　(n:ダイス数, t:コール数)
MESSAGETEXT
  end
  
  def changeText(string)
    debug('parren_killer_add begin string', string)
    
    string = string.gsub(/(\d+)BKC(\d)/) {"#{$1}R6[0,#{$2}]"}
    string = string.gsub(/(\d+)BAC(\d)/) {"#{$1}R6[1,#{$2}]"}
    string = string.gsub(/(\d+)BK/) {"#{$1}R6[0,0]"}
    string = string.gsub(/(\d+)BA/) {"#{$1}R6[1,0]"}
    
    debug('parren_killer_add end string', string)
    return string
  end
  
  def dice_command_xRn(string, nick_e)
    @nick_e = nick_e
    output_msg = barna_kronika_check(string)
  end
  

####################        バルナ・クロニカ      ########################
  def barna_kronika_check(string)
    output = '1';

    reutrn output unless(/(^|\s)S?((\d+)[rR]6(\[([,\d]+)\])?)(\s|$)/i =~ string)
    
    string = $2;
    dice_n = 1;
    total_n = 0;
    
    @isBattleMode = false;       # 0=判定モード, 1=戦闘モード
    criticalCallDice = 0;         # 0=通常, 1〜6=クリティカルコール
    
    dice_n = $3 if($3);
    
    if($4);
      battleModeText, criticalCallDice = $5.split(",").collect{|i|i.to_i}
      @isBattleMode = (battleModeText == 1)
    end
    
    debug("@isBattleMode", @isBattleMode)
    
    dice_str, suc, set, at_str = barna_kronika_roll(dice_n, criticalCallDice);
    
    output = "#{@nick_t}: (#{string}) ＞ [#{dice_str}] ＞ ";
    
    if( @isBattleMode )
      output += at_str;
    else
      debug("suc", suc)
      if(suc > 1)
        output += "成功数#{suc}";
      else
        output += "失敗";
      end
      
      debug("set", set)
      output += ",セット#{set}" if(set > 0);
    end
    
    return output;
  end
  
  def barna_kronika_roll(dice_n, criticalCallDice);
    dice_n = dice_n.to_i
    
    output = '';
    suc = 0;
    set = 0;
    at_str = '';
    diceCountList = [0, 0, 0, 0, 0, 0];

    dice_n.times do |i|
      index = rand(6);
      diceCountList[index] += 1
      if(diceCountList[index] > suc);
        suc = diceCountList[index] 
      end
    end
    
    6.times do |i|
      diceCount = diceCountList[i];
      
      next if(diceCount == 0)
      
      diceCount.times do |j|
        output << "#{i + 1},";
      end
      
      if( isCriticalCall(i, criticalCallDice) )
        debug("isCriticalCall")
        at_str += getAttackStringWhenCriticalCall(i, diceCount)
      elsif( isNomalAtack(criticalCallDice, diceCount) )
        debug("isNomalAtack")
        at_str += getAttackStringWhenNomal(i, diceCount)
      end
      
      set += 1 if( diceCount > 1 )
    end
    
    if( criticalCallDice != 0)
      c_cnt = diceCountList[criticalCallDice - 1];
      suc = c_cnt * 2;
      
      if( c_cnt != 0)
        set = 1;
      else
        set = 0;
      end
    end
    
    if( @isBattleMode and suc < 2)
      at_str = "失敗";
    end
    
    output = output.sub(/,$/, '')
    at_str = at_str.sub(/,$/, '')
    
    return output, suc, set, at_str;
  end

  def isCriticalCall(index, criticalCallDice)
    return false unless( @isBattleMode )
    return false if(criticalCallDice == 0)
    return (criticalCallDice == (index + 1))
  end

  def isNomalAtack(criticalCallDice, diceCount)
    return false unless( @isBattleMode )
    return false if(criticalCallDice != 0)
    return (diceCount > 1)
  end
  
  def getAttackStringWhenCriticalCall(index, diceCount)
    hitLocation = getAtackHitLocation(index + 1)
    atackValue = (diceCount * 2)
    result = hitLocation + ":攻撃値#{atackValue},";
    return result
  end
  
  def getAttackStringWhenNomal(index, diceCount)
    hitLocation = getAtackHitLocation(index + 1)
    atackValue = diceCount
    result = hitLocation + ":攻撃値#{atackValue},";
    return result
  end
  
####################        バルナ・クロニカ      ########################
#** 命中部位表
  def getAtackHitLocation(num)
    table = [
        [ 1, '頭部' ],
        [ 2, '右腕' ],
        [ 3, '左腕' ],
        [ 4, '右脚' ],
        [ 5, '左脚' ],
        [ 6, '胴体' ],
    ]
    
    return get_table_by_number(num, table)
  end

end
