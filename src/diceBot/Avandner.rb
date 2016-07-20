# -*- coding: utf-8 -*-

class Avandner < DiceBot

  def initialize
    super
    @sortType = 1 #ダイスのソート有
  end


  def prefixs
    ['\d+AV\d+((x|\*)\d+(\+\d+)?)?(c\d+)?']
  end

  def gameName
    '黒絢のアヴァンドナー'
  end

  def gameType
    "Avandner"
  end

  def getHelpMessage
    return <<MESSAGETEXT
・調査判定：nAVm[Cx]
・命中判定：nAVm*p[+t][Cx]
[]内は省略可能。

クリティカルヒットの分だけ、自動で振り足し処理を行います。0
「n」でダイス数を指定。
「m」で目標値を指定。省略は出来ません。
「Cx」でクリティカル値を指定。省略時は「1」、最大値は「2」、「0」でクリティカル無し。
「p」で攻撃力を指定。「*」は「x」でも可。
「+t」でクリティカルトリガーを指定。省略可能です。
攻撃力指定で命中判定となり、成功数ではなく、ダメージを結果表示します。

【書式例】
・5AV3 → 5d6で目標値3。
・6AV2C0 → 6d6で目標値2。クリティカル無し。
・4AV3*5 → 4d6で目標値3、攻撃力5の命中判定。
・7AV2x10 → 7d6で目標値2、攻撃力10の命中判定。
・8av4*7+10 → 8d6で目標値4、攻撃力7、クリティカルトリガー10の命中判定。
MESSAGETEXT
  end


  def rollDiceCommand(command)
    
    # AVコマンド：調査判定, 成功判定
    if /(\d+)AV(\d+)((x|\*)(\d+))?(\+(\d+))?(C(\d+))?$/i === command
      diceCount = $1.to_i
      target = $2.to_i
      damage = ($5 || 0).to_i
      criticalTrigger = ($7 || 0).to_i
      criticalNumber = ($9 || 1).to_i
      criticalNumber = 2 if( criticalNumber > 3 )
      return checkRoll(diceCount, target, damage, criticalTrigger, criticalNumber)
    end
    
    return nil
  end
  
  def checkRoll(diceCount, target, damage, criticalTrigger, criticalNumber)
    totalSuccessCount = 0
    totalCriticalCount = 0
    text = ""
    
    rollCount = diceCount
    
    while rollCount > 0
      dice, diceText = roll(rollCount, 6, @sortType)
      diceArray = diceText.split(/,/).collect{|i|i.to_i}
      
      successCount = 0
      criticalCount = 0
      
      diceArray.each do |i|
        if(i <= target)
          successCount += 1
        end
        
        if(i <= criticalNumber)
          criticalCount += 1
        end
      end
      
      totalSuccessCount += successCount
      totalCriticalCount += criticalCount unless criticalCount == 0
      
      text += "+" unless( text.empty? )
      text += "#{successCount}[#{diceText}]"
      
      rollCount = criticalCount
    end
    
    isDamage = (damage != 0)
    
    if( isDamage )
      totalDamage = totalSuccessCount * damage + totalCriticalCount * criticalTrigger
      
      result = "(#{diceCount}D6\<\=#{target}) ＞ #{text} ＞ Hits：#{totalSuccessCount}*#{damage}"
      result += " + Trigger：#{totalCriticalCount}*#{criticalTrigger}" if( criticalTrigger > 0 )
      result += " ＞ #{totalDamage}ダメージ"
      result += " / #{totalCriticalCount}クリティカル" if( totalCriticalCount > 0 )
    else
      result = "(#{diceCount}D6\<\=#{target}) ＞ #{text} ＞ 成功数：#{totalSuccessCount}"
      result += " / #{totalCriticalCount}クリティカル" if( totalCriticalCount > 0 )
    end

    return result
  end
  
end
