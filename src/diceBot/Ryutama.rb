#--*-coding:utf-8-*--

class Ryutama < DiceBot
  
  def gameType
    "Ryutama"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
ロール判定
　Rx,y>=t（x,y：使用する能力値、t：目標値）
　1ゾロ、クリティカルも含めて判定結果を表示します
　能力値１つでの判定は Rx>=t で行えます
例）
　R8,6>=13
　Ryutama : (R8,6>=13) ＞ 6(8)+6(6) ＞ 12 ＞ クリティカル成功
MESSAGETEXT
  end
  
  def dice_command(string, nick_e)
    debug('Ryutama dice_command begin')
    rollRyutama(string, nick_e);
  end
  
  def rollRyutama(string, name)
    unless( /^R(\d+)(,(\d+))?>=(\d+)/ === string )
      return ''
    end
    
    dice1 = $1.to_i
    dice2 = $3.to_i
    difficulty = $4.to_i
    
    value1 = getRollValue(dice1)
    value2 = getRollValue(dice2)
    total = value1 + value2
    
    result = getResultText(value1, value2, dice1, dice2, difficulty, total)
    
    value1Text = "#{value1}(#{dice1})"
    value2Text = ((value2 == 0) ? "" : "+#{value2}(#{dice2})")
    
    output = "#{name}: (#{string}) ＞ #{value1Text}#{value2Text} ＞ #{total} ＞ #{result}";
    
    return output
  end
  
  def getRollValue(dice)
    return 0 if( dice == 0 )
    
    value = rand(dice) + 1
    return value
  end
  
  def getResultText(value1, value2, dice1, dice2, difficulty, total)
    if( isFamble(value1, value2) )
      return "１ゾロ【１ゾロポイント＋１】"
    end
    
    if( isCritical(value1, value2, dice1, dice2) )
      return "クリティカル成功"
    end
    
    if( total >= difficulty )
      return "成功"
    end
    
    return "失敗"
  end
  
  def isFamble(value1, value2)
    return ((value1 == 1) and (value2 == 1 ))
  end
  
  def isCritical(value1, value2, dice1, dice2)
    return false if( value2 == 0 )
    
    if( ( value1 == 6 ) and (value2 == 6 ) )
      return true
    end
    
    if( (value1 == dice1) and (value2 == dice2) )
      return true
    end
    
    return false
  end
  
end
