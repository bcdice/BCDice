#--*-coding:utf-8-*--

class GeishaGirlwithKatana < DiceBot
  
  def prefixs
    #ダイスボットで使用するコマンドを配列で列挙すること。
    ['GK(#\d+)?', 'GL']
  end
  
  def gameName
    'ゲイシャ・ガール・ウィズ・カタナ'
  end
  
  def gameType
    "GeishaGirlwithKatana"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・判定 (GK#n)
  役やチョムバを含めて1回分のダイスロールを判定します。
　役は　（通常判定）／（戦闘時）　の順で両方出力されます。
  GK のみの場合5%の確率でチョムバます。
  GK#3 の様に #n をつけることによってチョムバの確率をn%にすることができます。
　例）GK　GK#10
・隠しコマンド (GL)
  必ずチョムバします。GMが空気を読んでチョムバさせたいときや、
  GKコマンドを打ち間違えてチョムバするを想定してます。
　例）GL
MESSAGETEXT
  end
 
  def dice_command(string, name)
    secret_flg = false
    
    return '1', secret_flg unless( /(^|\s)(S)?(#{prefixs.join('|')})(\s|$)/i =~ string )
    
    secretMarker = $2
    command = $3.upcase
    
    output_msg = getGGwKResult(command, name)
    
    if( secretMarker )    # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    return output_msg, secret_flg
  end
  
  
  def getGGwKResult(command, name)
    output = "1"
    
    if /^GL$/i =~ command
      return getChombaResultText(name)
    end
    
    unless /^GK(#(\d+))?$/i =~ command
      return output
    end
    
    chomba_counter = $2
    
    if isChomba(chomba_counter)
      return getChombaResultText(name)
    end
    
    total, dice_str = roll(3,6)
    diceList = dice_str.split(/,/).collect{|i|i.to_i}
    diceList.sort!
    
    yakuResult = getYaku(diceList)
    unless( yakuResult.nil? )
      return getResultTextByDice(name, diceList, "【役】#{yakuResult}")
    end
    
    
    deme, zorome = getDemeZorome(diceList)
    if deme == 0
      return getResultTextByDice(name, diceList, "失敗")
    end
    
    
    yp = (zorome == 1 ? " YPが1増加" : "")
    output = getResultTextByDice(name, diceList, "達成値#{deme}#{yp}")
    debug("getGGwKResult(command, name) result", output)
    
    return output
  end
  
  
  def isChomba(chomba_counter)
    chomba_counter ||= 5
    chomba_counter = chomba_counter.to_i 
    
    chomba, chomba_str = roll(1,100)
    
    return (chomba <= chomba_counter)
  end
  
  def getChombaResultText(name)
    getResultText(name, "チョムバ！！")
  end
  
  def getYaku(diceList)
    rule = {
      [1, 2, 3] => "自動失敗／自分の装甲効果無しでダメージを受けてしまう",
      [4, 5, 6] => "自動成功／敵の装甲を無視してダメージを与える",
      [1, 1, 1] => "10倍成功 YPが10増加／10倍ダメージ YPが10増加",
      [2, 2, 2] => "2倍成功／2倍ダメージ",
      [3, 3, 3] => "3倍成功／3倍ダメージ",
      [4, 4, 4] => "4倍成功／4倍ダメージ",
      [5, 5, 5] => "5倍成功／5倍ダメージ",
      [6, 6, 6] => "6倍成功／6倍ダメージ",
    }
    
    yaku = rule[diceList]
    return yaku
  end
  
  def getDemeZorome(diceList)
    deme = 0
    zorome = 0
    
    if diceList[0] == diceList[1]
      deme = diceList[2]
      zorome = diceList[0]
    elsif diceList[1] == diceList[2]
      deme = diceList[0]
      zorome = diceList[1]
    end
    
    return deme, zorome
  end
  
  
  def getResultTextByDice(name, diceList, result)
    getResultText(name, "#{diceList.join(',')} ＞ #{result}")
  end
  
  def getResultText(name, result)
    "#{name}: (3B6) ＞ #{result}"
  end
end

