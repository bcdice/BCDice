# -*- coding: utf-8 -*-

class RecordOfLodossWar < DiceBot
  setPrefixes(['LW.*'])

#
# Auther DOH(Vistraid)
# Version 0.1 20200329
#　開発開始　大成功と自動成功の識別　1d100
#

  def initialize
    super
  end

  def gameName
    'ロードス島戦記RPG'
  end

  def gameType
    "RecordOfLodossWar"
  end

  def rollDiceCommand(command)
    debug('rollDiceCommand')
    m = /^LW.*/.match(command)
    unless m
      return ''
    end

    return analyzeDiceCommandResultMethod(command)
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
●判定
　LW<=(目標値)で判定。
　達成値が目標値の1/10以下であれば大成功。1～10であれば自動成功。
　91～100であれば自動失敗となります。

●回避判定
　LWD<=(目標値)で回避判定。この時出目が51以上で自動失敗となります。

　判定と回避判定は、どちらもコマンドだけの場合、出目の表示と自動成功と自動失敗の判定のみを行います。
　
INFO_MESSAGE_TEXT
  end

  def getRollDiceCommandResult(command)
    debug('RollDiceCommand Start')

	#valuables initialize
    autoFailure = 91;
    compare_enabled = false;
	comparisonTargetValue = 0
	result_dice_message = ""

	#comparisonTargetValue　比較の有無と比較値の取得
	command =~ %r{<=[\d]+}
	if $~ != nil
		comparisonTargetValue = $~[0].gsub(%r{[^\d]},'').to_i
		compare_enabled = true
	end


	#防御フラグの取得　あったとき自動失敗の閾値が91から51となる
    command =~ %r{[D]}
    if $~ != nil
		case $~ [0]
			when 'D'
                autoFailure = 51;
            end
    end


	#ダイス判定
	diceValue, _, _ = roll(1, 100)

	#ダイス値が0の場合100として扱う。
    if(diceValue == 0)
        diceValue = 100
    end

	if compare_enabled
		result_dice_message = format('(1d100<=%02d)  ＞ %s ',comparisonTargetValue,diceValue)
	else
		result_dice_message = format('(1d100)  ＞ %s ',diceValue)
	end

	if compare_enabled
        result_dice_message << getCriticalOrFumble(getSuccessfulMessage(comparisonTargetValue,diceValue), diceValue,comparisonTargetValue,autoFailure)
    else
        result_dice_message << getCriticalOrFumble("", diceValue,comparisonTargetValue,autoFailure)
	end

    return result_dice_message
  end

#大成功と自動失敗、自動成功の判定。これらが発生するときgetSuccessfulMessageの取得結果は上書きされる
  def getCriticalOrFumble(source,dicevalue,comparisonTargetValue,autoFailure)

    critical = (comparisonTargetValue.to_f / 10).ceil
	returnMessage = source

    if dicevalue >= autoFailure
        returnMessage =  format("＞ 自動失敗(%d)",autoFailure)
    elsif dicevalue <= critical
        returnMessage =  format("＞ 大成功(%d)",critical)
    elsif dicevalue <= 10
        returnMessage =  "＞ 自動成功"
    end

    return returnMessage
  end

#比較時の結果を表示
  def getSuccessfulMessage(comparisonTargetValue, total)
    if comparisonTargetValue.to_i >= total.to_i
      return "＞ 成功"
    end

    return "＞ 失敗"
  end

end
