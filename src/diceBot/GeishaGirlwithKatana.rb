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
  GGwK専用のコマンドです。
  "GK"でロールします。3B6に読替されます。
  ただし、5%の確率でチョムバし、失敗します。
  また、#nをつけることによってチョムバの確率をn%にすることができます。
・隠しコマンド (GL)
  必ずチョムバします。GMが空気を読んでチョムバさせたいときや、
  GKコマンドを打ち間違えてチョムバするを想定してます。
MESSAGETEXT
  end
 
  def dice_command(string, nick_e)
    unless /((^|\s)(S)?GK(#(\d+))?|GL)($|\s)/i =~ string
      return ['1', false]
    end
    
    secretMarker = $3
    command = $1.upcase

    output_msg = getGGwKResult(command, nick_e)
    return output_msg
  end

  def getGGwKResult(command, name)
    output = "1"
    if /((^|\s)GL)($|\s)/i =~ command
      return getChombaResultText(name)
    end

    unless /((^|\s)GK(#(\d+))?)($|\s)/i =~ command
      return output
    end
    
    #チョムバ、役、成功失敗の順に判定
    #役に当てはまるものは成功失敗判定の処理でエラーを出すため
    #順番を変えてはいけない

    chomba_counter = $4
    chomba_counter ||= 5
    chomba_counter = chomba_counter.to_i 
    
    return output if chomba_counter > 100
    
    chomba, chomba_str = roll(1,100)
      
    if chomba <= chomba_counter 
      return getChombaResultText(name)
    end
    
    total, dice_str = roll(3,6)
    diceList = dice_str.split(/,/).collect{|i|i.to_i}
 
    deme = 0
    zoro = 0
    yp = ""
    rule = {
      [1, 2, 3] => " ＞ 自動失敗",
      [4, 5, 6] => " ＞ 自動成功",
      [1, 1, 1] => " ＞ 10倍成功 YPが10増加",
      [2, 2, 2] => " ＞ 2倍成功",
      [3, 3, 3] => " ＞ 3倍成功",
      [4, 4, 4] => " ＞ 4倍成功",
      [5, 5, 5] => " ＞ 5倍成功",
      [6, 6, 6] => " ＞ 6倍成功"
    }
    if rule[diceList.sort] =~ /＞/ 
      output = getResultText(name, "#{dice_str}#{rule[diceList.sort]}")
      return output
    end
    unless diceList.group_by{|i| i}.detect{|i| i.last.size > 1}.nil?
      deme = diceList.group_by{|i| i}.detect{|i| i.last.size == 1}.first
      zoro = diceList.group_by{|i| i}.detect{|i| i.last.size > 1}.first
    end
    if deme != 0
      yp = "YPが1増加" if zoro == 1
      output = getResultText(name, "#{dice_str} ＞ 達成値#{deme}#{yp}")
      return output
    else
      output = getResultText(name, "#{dice_str} ＞ 失敗")
      return output
    end
  end

  def getChombaResultText(name)
    getResultText(name, "チョムバ！！")
  end
  
  def getResultText(name, result)
    "#{name}: (3B6) ＞ #{result}"
  end
end

