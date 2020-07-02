
# -*- coding: utf-8 -*-

class SteamPunkers < DiceBot
  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes(['sp\d+.*'])


#
# Auther DOH(Vistraid)
# Version 0.1 20200620 
#　とりあえずやっつけ作成。失敗数を参照する振り直しがあるので成功数と失敗数の明示を追加。
# Version 0.2 20200702 
#　投稿のため最低限恥ずかしいところを修正
#  一瞥して必要な要件は成功数と結果のみのため
#　＞ [内訳] ＞ [成功数] [判定結果] (失敗数：[失敗数])
# の形式で出力するものと変更

  def initialize
    super
  end

  def gameName
    'スチームパンカーズ'
  end

  def gameType
    'SteamPunkers'
  end

  def getHelpMessage
    return <<MESSAGETEXT
SP(判定ダイス数)>=(目標値)
SP4>=3のように入力し、5が出たらヒット数1，6が出たらヒット数2として成功数を数えます。
≪スチームパンク！≫による振り直しのため、出力には失敗ダイス数を表示します。
例：(SP4>=3) ＞ [3,4,1,6] ＞ 成功数:2 ＞ 失敗 (失敗数:3)
MESSAGETEXT
  end

  def rollDiceCommand(command)


    return analyzeDiceCommandResultMethod(command)
  end

  def getRollDiceCommandResult(command)
    debug('RollDiceCommand Start')

	#valuables initialize
	success_count = 0
	failed_dice = 0
	failure_message = ""
	funble_flag = true			#ファンブルしているかどうかの判定
    diff_enabled = false
	comparison_Target_Value = 0

	#ダイス数取得
	command =~ %r{SP[\d]+}
	if $~ != nil
		diceCount = $~[0].gsub(%r{[^\d]},'').to_i
	else
		return ''
	end
	
	#比較の有無と比較値の取得
	command =~ %r{>=[\d]+}
	if $~ != nil
		comparison_Target_Value = $~[0].gsub(%r{[^\d]},'').to_i
		compare_enabled = true
	end

    total, diceText, _ = roll(diceCount, 6)
    
    dicearray = diceText.split(',')
    dicearray.each { |dicevalue|
    	if '6' == dicevalue
    		success_count += 2
    	elsif '5' == dicevalue
    		success_count += 1
    	else
    		failed_dice += 1
    	end
    	if '1' != dicevalue
			funble_flag = false
    	end
    }
	success_result = format("成功数:%d",success_count)
	failure_message = format(" (失敗数:%d)",failed_dice)


	result_message = ""
    if(compare_enabled)
	    result_message = (success_count >= comparison_Target_Value ? " ＞ 成功" : " ＞ 失敗")
	end
	
    if(funble_flag)
    	result_message = " ＞ ファンブル"
	end

    return "(#{command}) ＞ [#{diceText}] ＞ #{success_result}#{result_message}#{failure_message}"
  end


end
