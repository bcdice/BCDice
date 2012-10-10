#--*-coding:utf-8-*--

class CrashWorld < DiceBot
  def gameType
    "CrashWorld"
  end

  def gameName
    '墜落世界'
  end
  
  def prefixs
     ['CW\d+']
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
・判定 CWn
初期目標値n (必須)
例・CW8
INFO_MESSAGE_TEXT
  end
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    return '1', secret_flg unless( /(^|\s)(S)?(#{prefixs.join('|')})(\s|$)/i =~ string )
    
    secretMarker = $2
    targetNum = $3.to_i
    
    output_msg = getCrashWorldResult(targetNum, nick_e);
    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    return output_msg, secret_flg
  end

  def getCrashWorldResult(targetNum, nick_e)
    output = "("
    endFlag = false
    target = targetNum
    successness = 0
    num = 0
    
    while(!endFlag)
      num, dummy = roll(1, 12)
      
      # 振った数字を出力へ書き足す
      if(output == "(")
        output = "(#{num}"
      else
        output = "#{output}, #{num}"
      end

      if(num <= target || num == 11)
        # 成功/クリティカル(11)。 次回の目標値を変更して継続
        target = num
        successness = successness + 1
      elsif(num == 12)
        # ファンブルなら終了。
        endFlag = true
      else
        # target < num < 11で終了
        endFlag = true
      end
    end

    if(num == 12)
      # ファンブルの時、成功度は0
      successness = 0
    end
    output = "#{output})  成功度 : #{successness}"
    if(num == 12)
      output = "#{output} ファンブル"
    end

    return "：#{output}"
  end
end

