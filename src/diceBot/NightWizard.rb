#--*-coding:utf-8-*--

class NightWizard < DiceBot
  
  def initialize
    super
    @sendMode = 2;
  end
  
  def gameType
    "NightWizard"
  end
  
  def getHelpMessage
    '・判定ロール　　　　　　　(nNW+m@x#y) (n:基本値+常時, m:否常時+状態異常, x:クリティカル値, y:ファンブル値)'
  end
  
  def changeText(string)
    return string unless(string =~ /NW/i)
    
    string = string.gsub(/(\d+)NW\+?([\-\d]+)@([,\d]+)#([,\d]+)/i) {"2R6m[#{$1},#{$2}]c[#{$3}]f[#{$4}]"}
    string = string.gsub(/(\d+)NW\+?([\-\d]+)/i) {"2R6m[#{$1},#{$2}]"}
    string = string.gsub(/(\d+)NW/i) {"2R6m[#{$1},0]"}
  end
  
  def dice_command_xRn(string, nick_e)
    output_msg = night_wizard_check(string, nick_e);
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    return '' unless(signOfInequality == ">=")
    
    if(total_n >= diff)
      return " ＞ 成功";
    end
    
    return " ＞ 失敗";
  end
  

####################        ナイトウィザード       ########################
  def night_wizard_check(string, nick_e)
    debug('night_wizard_check string', string)
    
    output = '1';
    
    num = '[,\d\+\-]+';
    return output unless(/(^|\s)S?(2R6m\[(#{num})\](c\[(#{num})\])?(f\[(#{num})\])?(([>=]+)(\d+))?)(\s|$)/i =~ string)
    
    debug('is valid string')
    
    string = $2;
    base_and_mod = $3
    criticalText = $4
    criticalValue = $5
    fumbleTet = $6
    fumbleValue = $7
    judgeText = $8
    judgeOperator = $9
    judgeValue = $10.to_i
    
    base, mod = base_and_mod.split(/,/)
    crit = "0";
    fumble = "0";
    signOfInequality = "";
    diff = 0;
    
    if(criticalText)
      crit = criticalValue
    end
    
    if(fumbleTet)
      fumble = fumbleValue
    end
    if(judgeText)
      diff = judgeValue
      debug('judgeOperator', judgeOperator)
      signOfInequality = marshalSignOfInequality(judgeOperator);
    end
    
    base = parren_killer("(0#{base})").to_i;
    mod = parren_killer("(0#{mod})").to_i;
    
    total, out_str = nw_dice(base, mod, crit, fumble);
    output = "#{nick_e}: (#{string}) ＞ #{out_str}";
    if(signOfInequality != "")  # 成功度判定処理
      output += check_suc(total, 0, signOfInequality, diff, 3, 6, 0, 0);
    end
    
    return output;
  end
  
  
  def nw_dice(base, mod, criticalText, fumbleText)
    debug("nw_dice : base, mod, criticalText, fumbleText", base, mod, criticalText, fumbleText)
    
    @criticalValues = getValuesFromText(criticalText, [10])
    @fumbleValues = getValuesFromText(fumbleText, [5])
    total = 0;
    output = "";
    
    debug('@criticalValues', @criticalValues)
    debug('@fumbleValues', @fumbleValues)
    
    dice_n, dice_str, = roll(2, 6, 0);
    
    total = base + mod
    
    if( @fumbleValues.include?(dice_n) )
      total = base
      total -= 10;
      output = "#{base}-10[#{dice_str}] ＞ #{total}";
    else
      total = base + mod
      total, output = checkCritical(total, dice_str, dice_n)
    end
    
    return total, output
  end
  
  
  def setCriticalValues(text)
    @criticalValues = getValuesFromText(text, [10])
  end
  
  def getValuesFromText(text, default)
    if( text == "0" )
      return default
    end
    
    return text.split(/,/).collect{|i|i.to_i}
  end
  
  def checkCritical(total, dice_str, dice_n)
    debug("addRollWhenCritical begin total, dice_str", total, dice_str)
    output = "#{total}";
    
    isCritical = isCriticalValue(dice_n)
    
    while(isCritical)
      total += 10;
      output += "+10[#{dice_str}]";
      
      dice_n, dice_str, = roll(2, 6, 0);
      
      isCritical = isCriticalValue(dice_n)
      debug("isCritical", isCritical)
    end
    
    total += dice_n;
    output += "+#{dice_n}[#{dice_str}] ＞ #{total}";
    
    return total, output
  end
  
  def isCriticalValue(dice_n)
    return @criticalValues.include?(dice_n)
  end
  
end
