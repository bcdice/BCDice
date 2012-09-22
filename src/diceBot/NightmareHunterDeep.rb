#--*-coding:utf-8-*--

class NightmareHunterDeep < DiceBot
  
  def initialize
    super
    @sendMode = 2;
    @sortType = 1;
  end
  
  def gameName
    'ナイトメアハンター=ディープ'
  end
  
  def gameType
    "NightmareHunterDeep"
  end
  
  def prefixs
     []
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
加算ロール時に６の個数をカウントして、その４倍を自動的に加算します。
(出目はそのまま表示で合計値が6懼��10の読み替えになります)
INFO_MESSAGE_TEXT
  end
  
  def changeText(string)
    debug("parren_killer_add before string", string)
    string = string.sub(/^(.+?)Lv(\d+)(.*)/i) {"#{$1}#{ ($2.to_i * 5 - 1) }#{$3}"}
    string = string.sub(/^(.+?)NL(\d+)(.*)/i) {"#{$1}#{ ($2.to_i * 5 + 5) }#{$3}"}
    debug("parren_killer_add after string", string)
    
    return string
  end
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    return '' unless($signOfInequality == ">=")
    
    if(diff != "?")
      if(total_n >= diff)
        return " ＞ 成功";
      end
      
      return " ＞ 失敗";
    end
    
    #diff == "?"
    sucLv = 1;
    sucNL = 0;
    
    while(total_n >= sucLv*5-1)
      sucLv += 1;
    end
    
    while(total_n >= (sucNL * 5 + 5))
      sucNL += 1
    end
    
    sucLv -= 1;
    sucNL -= 1;
    
    if(sucLv <= 0)
      return " ＞ 失敗";
    else
      return " ＞ Lv#{sucLv}/NL#{sucNL}成功";
    end
  end
  
  
  #ナイトメアハンターディープ用宿命表示
  def getDiceRolledAdditionalText(n1, n_max, dice_max)
    debug('getDiceRolledAdditionalText begin: n1, n_max, dice_max', n1, n_max, dice_max)
    
    if( (n1 != 0) and (dice_max == 6) );
      return " ＞ 宿命獲得"
    end
    
    return ''
  end
  
  #ダイス目による補正処理（現状ナイトメアハンターディープ専用）
  def getDiceRevision(n_max, dice_max, total_n)
    addText = ''
    revision = 0
    
    if( (n_max > 0) and (dice_max == 6) )
      revision = (n_max * 4);
      addText = ("+#{n_max}*4 ＞ #{total_n + revision}");
    end
    
    return addText, revision
  end
  
end
