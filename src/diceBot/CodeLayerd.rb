# -*- coding: utf-8 -*-

class CodeLayerd < DiceBot
  
  def prefixs
    ['\d*CL[@\d]*.*']
  end
  
  def gameName
    'コード：レイヤード'
  end
  
  def gameType
    "CodeLayerd"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・行為判定（nCL@m） クリティカル・ファンブル判定あり
  n個のD10でmを判定値とした行為判定を行う。mは省略可能。（@6扱い）
  例）7CL>=5 ：サイコロ7個で判定値6のロールを行い、目標値5に対して判定
  例）4CL@7  ：サイコロ4個で判定値7のロールを行い達成値を出す
MESSAGETEXT
  end
  
  def isGetOriginalMessage
    true
  end
  
  def rollDiceCommand(command)
    debug('rollDiceCommand command', command)
    
    result = ''
    
    case command
    when /(\d+)?CL(\@?(\d))?(>=(\d+))?/i
      base  = ($1 || 1).to_i
      judge = ($3 || 6).to_i
      diff  = $5.to_i
      result= checkRoll(base, judge, diff)
    end
    
    return nil if result.empty? 
    
    return "#{command} ＞ #{result}"
  end
  
  
  def checkRoll(base, judge, diff = 0)
    result = ""
    
    base  = getValue(base)
    judge = getValue(judge)
    
    return result if( base < 1 )
    
    judge = 10 if( judge > 10 )
    
    result << "(#{base}d10)"
    
    _, diceText = roll(base, 10)
    
    diceList = diceText.split(/,/).collect{|i|i.to_i}.sort
    
    result << " ＞ [#{diceList.join(',')}] ＞ "
    result << getRollResultString(diceList, judge, diff)
    
    return result 
  end
  
  
  def getRollResultString(diceList, judge, diff)
    
    successnum,critnum = getSuccessInfo(diceList, judge)
    
    successsum = successnum + critnum
    result = ""

    if(critnum > 0)
      result << "判定値[#{judge}] 達成値[#{successnum}+#{critnum}=#{successsum}]"
    else
      result << "判定値[#{judge}] 達成値[#{successnum}]"
    end

    if( diff != 0 )
      if( successsum >= diff )
        result << " ＞ 成功"
      elsif( successsum == 0 )
        result << " ＞ ファンブル！"
      else
        result << " ＞ 失敗"
      end
    else
      result << " ＞ #{successsum}"
    end
    
    return result
  end
  
  
  def getSuccessInfo(diceList, judge)
    debug("checkSuccess diceList, judge", diceList, judge)
    
    num  = 0
    crit = 0
    successDiceList = []
    
    diceList.each do |dice|
      if( dice <= judge )
        successDiceList << dice
        num += 1
      end
      if( dice == 1 )
        crit += 1
      end
    end
    
    debug("successDiceList", successDiceList)
    
    return num,crit
  end
  

  def getValue(number)
    return 0 if( number > 100 )
    return number
  end
  
end
