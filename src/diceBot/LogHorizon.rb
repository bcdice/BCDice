#--*-coding:utf-8-*--

class LogHorizon < DiceBot
  
  def initialize
    super
    @d66Type = 1;
  end
  
  def prefixs
    ['\d+LH.*', 'PCT.*', 'ECT.*', 'GCT.*', 'MCT.*']
  end
  
  def gameName
    'ログ・ホライズン'
  end
  
  def gameType
    "LogHorizon"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・判定(xLH±y>=z)
 xD6のダイスを振る判定。
 クリティカル、ファンブルの自動判定を行います。
 x:xに振るダイス数を入力。
 ±y:yに修正値を入力。±の計算に対応。省略可能。
 >=z:zに目標値を入力。±の計算に対応。省略可能。
・各種表
 ・消耗表(tCTx±y)
   各種消耗表。tに種類を入力。
   PCT 体力消耗表 / ECT 気力消耗表
   GCT 物品消耗表 / MCT 金銭消耗表
   x:xにCRを入力。
   ±y:yに修正値を入力。
・D66ダイスあり
MESSAGETEXT
  end
  
  
  def rollDiceCommand(command)
    
    #ダイスロールコマンド
    result = checkRoll( command )
    return result unless( result.nil? )
	
    #消耗表
    result = getConsumptionResult( command )
    return result unless( result.nil? )
	
	return nil
  end
  
  
  def checkRoll(command)
    
    return nil unless(/(\d+)LH([\+\-\d]*)(>=([\+\-\d]*))?/i === command)
    
    diceCount = $1.to_i
    modifyText = ($2 || '')
    difficultyText = $4
      
	#修正値の計算
	modify = getValue( modifyText, 0 )
    
	#目標値の計算
    difficulty = getValue( difficultyText, nil )
	
	#ダイスロール
	dice, dice_str = roll(diceCount, 6)
    diceList = dice_str.split(/,/).collect{|i|i.to_i}.sort
    
	total = dice + modify
	
	#出力用ダイスコマンドを生成
	command =  "#{diceCount}LH#{modifyText}"
	command += ">=#{difficulty}" unless(difficulty.nil?)
	
    
	#出力文の生成
	result = "(#{command}) ＞ #{dice}[#{dice_str}]#{modifyText} ＞ #{total}"
    
    
	#クリティカル・ファンブルチェック
	if( isCritical(diceList) )
	  result += " ＞ クリティカル！"
	elsif( isFamble(diceList, diceCount) )
	  result += " ＞ ファンブル！"
    else
      result += getJudgeResult(difficulty, total)
    end
    
    return result
    
  end
  
  
  #成否判定
  def getJudgeResult(difficulty, total)
    return '' if(difficulty.nil?)
    
    if(total >= difficulty)
      return " ＞ 成功"
    else
      return " ＞ 失敗"
    end
  end
  
  
  def getValue(text, defaultValue)
    return defaultValue if( text == nil or text.empty? ) 
    
    parren_killer("(0" + text + ")").to_i 
  end
  
  
  def isCritical(diceList)
	(diceList.select{|i| i == 6 }.size >= 2)
  end
  
  def isFamble(diceList, diceCount)
    (diceList.select{|i| i == 1 }.size >= diceCount)
  end
  
  
  #消耗表
  def getConsumptionResult( command )

    return nil unless(/(P|E|G|M)CT(\d+)([\+\-]\d)?/ === command)
    type = $1
    rank = $2.to_i
    modify  = $3.to_i
    
    
    tableName = ""
    table = []
    
    case type
	  when "P"
	    tableName = "体力消耗表"
		table = [
		         [0, '消耗なし'],
		         [1, '[疲労:5]を受ける'],
		         [2, '[疲労:8]を受ける'],
		         [3, '[疲労:10]を受ける'],
		         [4, '[疲労:13]を受ける'],
		         [5, '[疲労:15]を受ける'],
		         [6, '[疲労:18]を受ける'],
		         [7, '[疲労:20]を受ける'],
		        ]
	  
	  when "E"
	    tableName = "気力消耗表"
		table = [
		         [0, '消耗なし'],
		         [1, '【因果力】を1点失う'],
		         [2, '【因果力】を1点失う'],
		         [3, '【因果力】を1点失う'],
		         [4, '【因果力】を1点失う'],
		         [5, '【因果力】を2点失う'],
		         [6, '【因果力】を2点失う'],
		         [7, '【因果力】を2点失う'],
		        ]
	  
	  when "G"
	    tableName = "物品消耗表"
		table = [
		         [0, '消耗なし'],
		         [1, '[消耗品]アイテムを1個失う'],
		         [2, '[消耗品]アイテムを1個失う'],
		         [3, '[消耗品]アイテムを1個失う'],
		         [4, '[消耗品]アイテムを2個失う'],
		         [5, '[消耗品]アイテムを2個失う'],
		         [6, '[消耗品]アイテムを2個失う'],
		         [7, '[消耗品]アイテムを2個失う'],
		        ]
	  
	  when "M"
	    tableName = "金銭消耗表"
		table = [
		         [0, '消耗なし'],
		         [1, '所持金を10G失う'],
		         [2, '所持金を15G失う'],
		         [3, '所持金を20G失う'],
		         [4, '所持金を25G失う'],
		         [5, '所持金を30G失う'],
		         [6, '所持金を35G失う'],
		         [7, '所持金を40G失う'],
		        ]
	  
	  else
	    return nil
	end
	
	number, = roll(1, 6)
	number += modify
    
    adjustNumber = getAdjustNumber(number, table)
    
	result = get_table_by_number(adjustNumber, table)
	
	text = "#{tableName}(#{number})：#{result}"
    return text
  end
  
  def getAdjustNumber(number, table)
    
    min = table.first.first
	return min if(number < min)
    
    max = table.last.first
	return max if(number > max)
    
    return number
  end
  
end
