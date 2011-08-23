#--*-coding:utf-8-*--

class GehennaAn < DiceBot
  
  def initialize
    super
    @sendMode = 3;
    @sortType = 3;
  end
  
  
  def gameType
    "GehennaAn"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・通常判定　　　　　　　　(nGt+m)  (n:ダイス数, t:目標値, m:修正値)
・戦闘判定　　　　　　　　(nGAt+m) (n:ダイス数, t:目標値, m:修正値)
MESSAGETEXT
  end
  
  def changeText(string)
    string = string.gsub(/(\d+)GA(\d+)([\+\-][\+\-\d]+)/) {"#{$1}R6#{$3}>=#{$2}[1]"}
    string = string.gsub(/(\d+)GA(\d+)/) {"#{$1}R6>=#{$2}[1]"}
    string = string.gsub(/(\d+)G(\d+)([\+\-][\+\-\d]+)/) {"#{$1}R6#{$3}>=#{$2}[0]"}
    string = string.gsub(/(\d+)G(\d+)/) {"#{$1}R6>=#{$2}[0]"}
  end
  
  
  def dice_command_xRn(string, nick_e)
    output_msg = gehenna_an_check(string, nick_e);
  end
  
####################      ゲヘナ・アナスタシス    ########################

  def gehenna_an_check(string, nick_e)
    output = '1';

    return output unless(/(^|\s)S?((\d+)[rR]6([\+\-\d]+)?([>=]+(\d+))(\[(\d)\]))(\s|$)/i =~ string)
    
    string = $2;
    
    dice_n = $3.to_i
    dice_n ||= 1;
    
    modText = $4
    
    diff = $6.to_i
    mode = $8.to_i
    
    mod = parren_killer("(0#{modText})").to_i
    
    signOfInequality = ">=";
    fumble = 2;
    total_n = 0;
    
    dice_now, dice_str, dummy = roll(dice_n, 6, (sortType & 1));
    
    diceArray = dice_str.split(/,/).collect{|i|i.to_i}
    
    dice_1st = "";
    isLuck = true
    dice_now = 0;
    
    # 幸運の助けチェック
    diceArray.each do |i|
      if( dice_1st != "" )
        if( dice_1st != i or i < diff )
          isLuck = false
        end
      else
        dice_1st = i;
      end
      
      dice_now += 1 if(i >= diff);
    end
    
    dice_now *= 2 if(isLuck and (dice_n > 1));
    
    output = "#{dice_now}[#{dice_str}]";
    total_n = dice_now + mod;
    
    if(mod > 0)
      output += "+#{mod}";
    elsif(mod < 0)
      output += "#{mod}";
    end
    
    if(/[^\d\[\]]+/ =~ output )
      output = "#{nick_e}: (#{string}) ＞ #{output} ＞ #{total_n}";
    else
      output = "#{nick_e}: (#{string}) ＞ #{output}";
    end
    
    # 連撃増加値と闘技チット
    if(mode)
      bonus_str = '';
      ma_bonus = ((total_n  - 1) / 2).to_i;
      ma_bonus = 7 if(ma_bonus > 7);
      
      bonus_str += "連撃[+#{ma_bonus}]/" if(ma_bonus > 0);
      bonus_str += "闘技[#{ga_ma_chit_table(total_n)}]";
      output += " ＞ #{bonus_str}";
    end
    
    return output;
  end

####################      ゲヘナ・アナスタシス    ########################
  def ga_ma_chit_table(num)
    table = [
             [ 6, '1'],
             [13, '2'],
             [18, '3'],
             [22, '4'],
             [99, '5'],
            ]
    
    return get_table_by_number(num, table);
  end
  
end
