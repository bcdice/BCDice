#--*-coding:utf-8-*--

class DarkBlaze < DiceBot
  
  def initialize
    super
    @sendMode = 2;
  end
  
  def gameType
    "DarkBlaze"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・ダークブレイズ　判定　　(DBxy#m) (x:能力値, y:技能値, m:修正)
・掘り出し袋表　　　　　　(BTx)　　(x:ダイス数)
MESSAGETEXT
  end
  
  def changeText(string)
    return string unless(string =~ /DB/i)
    
    string = string.gsub(/DB(\d),(\d)/) {"DB#{$1}#{$2}"}
    string = string.gsub(/DB\@(\d)\@(\d)/) {"DB#{$1}#{$2}"}
    string = string.gsub(/DB(\d)(\d)(#([\d][\+\-\d]*))/) {"3R6+#{$4}[#{$1},#{$2}]"}
    string = string.gsub(/DB(\d)(\d)(#([\+\-\d]*))/) {"3R6#{$4}[#{$1},#{$2}]"}
    string = string.gsub(/DB(\d)(\d)/) {"3R6[#{$1},#{$2}]"}
    
    return string
  end
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    return '1', secret_flg unless(/((^|\s)(S)?BT(\d+)?($|\s))/i =~ string )
    
    # 掘り出し袋表

    secretMarker = $3
    dice = 1;
    dice = $4 if($4);
    output_msg = dark_blaze_horidasibukuro_table(dice, nick_e);
    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    return output_msg, secret_flg
  end
  
  def dice_command_xRn(string, nick_e)
    output_msg = dark_blaze_check(string, nick_e);
  end
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    return '' unless(signOfInequality == ">=")
    
    return '' if(diff == "?")
    
    if(total_n >= diff)
      return " ＞ 成功";
    end
    
    return " ＞ 失敗";
  end
  
####################         ダークブレイズ        ########################
  def dark_blaze_check(string, nick_e)
    output = "1";
    
    return '1' unless(/(^|\s)S?(3[rR]6([\+\-\d]+)?(\[(\d+),(\d+)\])(([>=]+)(\d+))?)(\s|$)/i =~ string)
    
    string = $2;
    mod = 0;
    abl = 1;
    skl = 1;
    signOfInequality = "";
    diff = 0;
    
    mod = parren_killer("(0#{$3})").to_i if($3);
    
    if($4)
      abl = $5.to_i;
      skl = $6.to_i;
    end
    
    if($7)
      signOfInequality = marshalSignOfInequality($8);
      diff = $9.to_i;
    end
    
    total, out_str = dark_blaze_dice(mod, abl, skl);
    output = "#{nick_e}: (#{string}) ＞ #{out_str}";
    
    if(signOfInequality != "")  # 成功度判定処理
      output += check_suc(total, 0, signOfInequality, diff, 3, 6, 0, 0);
    end
    
    return output;
  end
                          
  def dark_blaze_dice(mod, abl, skl)
    total = 0;
    crit = 0;
    fumble = 0;
    dice_c = 3 + mod.abs
    
    dummy = roll(dice_c, 6, 1);
    
    dummy.shift
    dice_str = dummy.shift
    
    dice_arr = dice_str.split(/,/).collect{|i|i.to_i}
    
    3.times do |i|
      ch = dice_arr[i];
      
      if(mod < 0)
        ch = dice_arr[dice_c - i - 1] 
      end
      
      total += 1 if(ch <= abl);
      total += 1 if(ch <= skl);
      crit += 1 if(ch <= 2);
      fumble += 1 if(ch >= 5);
    end
    
    
    resultText = "";
    
    if(crit >= 3)
      resultText = " ＞ クリティカル";
      total = 6 + skl;
    end
    
    if(fumble >= 3)
      resultText = " ＞ ファンブル";
      total = 0;
    end
    
    output = "#{total}[#{dice_str}]#{resultText}";
      
    return total, output
  end

####################         ダークブレイズ        ########################
#** 掘り出し袋表
  def dark_blaze_horidasibukuro_table(dice, nick_e)
    output = '1';
    
    material_kind = [   #2D6
      "蟲甲",     #5
      "金属",     #6
      "金貨",     #7
      "植物",     #8
      "獣皮",     #9
      "竜鱗",     #10
      "レアモノ", #11
      "レアモノ", #12
    ]
    
    magic_stone = [ #1D3
      "火炎石",
      "雷撃石",
      "氷結石",
    ]
    
    num1, dmy = roll(2, 6);
    num2, dmy = roll(dice, 6);
    
    debug('dice', dice)
    debug('num1', num1)
    debug('num2', num2)
    
    if(num1 <= 4)
      num2, dmy = roll(1, 6);
      magic_stone_result = (magic_stone[(num2 / 2).to_i - 1])
      output = "《#{magic_stone_result}》を#{dice}個獲得";
    elsif(num1 == 7)
      output = "《金貨》を#{num2}枚獲得";
    else
      type = material_kind[num1 - 5];
      
      if(num2 <= 3)
        output = "《#{type} I》を1個獲得";
      elsif(num2 <= 5)
        output = "《#{type} I》を2個獲得";
      elsif(num2 <= 7)
        output = "《#{type} I》を3個獲得";
      elsif(num2 <= 9)
        output = "《#{type} II》を1個獲得";
      elsif(num2 <= 11)
        output = "《#{type} I》を2個《#{type} II》を1個獲得";
      elsif(num2 <= 13)
        output = "《#{type} I》を2個《#{type} II》を2個獲得";
      elsif(num2 <= 15)
        output = "《#{type} III》を1個獲得";
      elsif(num2 <= 17)
        output = "《#{type} II》を2個《#{type} III》を1個獲得";
      else
        output = "《#{type} II》を2個《#{type} III》を2個獲得";
      end
    end
    
    if(output != '1');
      output = "#{nick_e}: 掘り出し袋表[#{num1},#{num2}] ＞ #{output}"
    end
    
    return output;
  end
  
end
