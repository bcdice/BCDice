#--*-coding:utf-8-*--

class HarnMaster < DiceBot
  
  def initialize
    super
    
    # @sendMode = @@DEFAULT_SEND_MODE #(0=結果のみ,1=0+式,2=1+ダイス個別)
    # @sortType = 0;      #ソート設定(1 = ?, 2 = ??, 3 = 1&2　各値の意味が不明です懼�ｦ）
    # @sameDiceRerollCount = 0;     #ゾロ目で振り足し(0=無し, 1=全部同じ目, 2=ダイスのうち2個以上同じ目)
    # @sameDiceRerollType = 0;   #ゾロ目で振り足しのロール種別(0=判定のみ, 1=ダメージのみ, 2=両方)
    # @d66Type = 0;        #d66の差し替え
    # @isPrintMaxDice = false;      #最大値表示
    # @upplerRollThreshold = 0;      #上方無限
    # @unlimitedRollDiceType = 0;    #無限ロールのダイス
    # @rerollNumber = 0;      #振り足しする条件
    # @defaultSuccessTarget = "";      #目標値が空欄の時の目標値
    # @rerollLimitCount = 0;    #振り足し回数上限
    # @fractionType = "omit";     #端数の処理 ("omit"=切り捨て, "roundUp"=切り上げ, "roundOff"=四捨五入)
  end
  
  
  def prefixs
    #ダイスボットで使用するコマンドを配列で列挙すること。
    ['SHK\d+.*', 'AP', 'APU', 'APD', ]
  end
  
  def gameName
    'ハーンマスター'
  end
  
  def gameType
    "HarnMaster"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・判定
　1D100<=XX の判定時に致命的失敗・決定的成功を判定
・命中部位表 (AP)／上段命中部位 (APU)／上段命中部位 (APD)
MESSAGETEXT
  end
  
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless(signOfInequality == "<=")
    
    result = getCheckResult(total_n, diff)
    return "＞ #{result}"
  end
  
  def getCheckResult(total, diff)
    return getFailResult(total) if total > diff
    return getSuccessResult(total)
  end
  
  def getFailResult(total)
    return "致命的失敗" if (total % 5) == 0
    return "失敗"
  end
  
  def getSuccessResult(total)
    return "決定的成功" if (total % 5) == 0
    return "成功"
  end
  
  
  def rollDiceCommand(command)
    result = nil
    
    case command
    when /^SHK(\d*),(\d+)/i
      damage = $1.to_i
      toughness = $1.to_i
      result = getCheckShockResult(damage, toughness)
    when /AP(U|D)?/i
      type = $1
      result = getAtackHitPart(type)
    else
      result = nil
    end
    
    return result
  end
  
  def getCheckShockResult(damage, toughness)
    dice, = roll(damage, 6)
    
    return 'ショック判定：失敗' if( dice > toughness )
    return 'ショック判定成功'
  end
  
  
  def getAtackHitPart(type)
    
    typeName = ''
    table = nil
    
    case type
    when 'U'
      typeName = "上段"
      table = getAtackHitPartUpperTable()
    when 'D'
      typeName = "下段"
      table = getAtackHitPartDownTable()
    when nil
      typeName = ""
      table = getAtackHitPartNormalTable()
    else
      raise "unknow atak type #{type}"
    end
    
    number, = roll(1, 100)
    part = get_table_by_number(number, table)
    part = getPartSide(part, number)
    part = getFacePart(part)
    
    result = "#{typeName}命中部位：(#{number})#{part}"
    
    return result
  end
  
  def getPartSide(part, number)
    unless /^\*/ === part
      debug("part has NO side", part)
      return part
    end
    
    debug("part has side", part)
    
    side = (((number % 2) == 1) ? "左" : "右")
    
    part.sub!(/\*/, side)
  end
  
  def getFacePart(part)
    debug("getFacePart part", part)
    
    unless /\+$/ === part
      debug("is NOT Face")
      return part
    end
    
    debug("is Face")
    
    table = [
             [ 15, "顎"],
             [ 30, "*目"],
             [ 64, "*頬"],
             [ 80, "鼻"],
             [ 90, "*耳"],
             [100, "口"],
            ]
    
    number, = roll(1, 100)
    facePart = get_table_by_number(number, table)
    debug("facePart", facePart)
    debug("number", number)
    facePart = getPartSide(facePart, number)
    
    result = part.sub(/\+$/, " ＞ (#{number})#{facePart}")
    return result
  end
  
  def getAtackHitPartUpperTable()
    table = [
             [ 15, "頭部"],
             [ 30, "顔+"],
             [ 45, "首"],
             [ 57, "*肩"],
             [ 69, "*上腕"],
             [ 73, "*肘"],
             [ 81, "*前腕"],
             [ 85, "*手"],
             [ 95, "胸部"],
             [100, "腹部"],
            ]
    return table
  end
  
  def getAtackHitPartNormalTable()
    table = [
             [  5, "頭部"],
             [ 10, "顔+"],
             [ 15, "首"],
             [ 27, "*肩"],
             [ 33, "*上腕"],
             [ 35, "*肘"],
             [ 39, "*前腕"],
             [ 43, "*手"],
             [ 60, "胸部"],
             [ 70, "腹部"],
             [ 74, "股間"],
             [ 80, "*臀部"],
             [ 88, "*腿"],
             [ 90, "*膝"],
             [ 96, "*脛"],
             [100, "*足"],
            ]
    return table
  end
  
  def getAtackHitPartDownTable()
    table = [
             [  6, "*前腕"],
             [ 12, "*手"],
             [ 19, "胸部"],
             [ 29, "腹部"],
             [ 35, "股間"],
             [ 49, "*臀部"],
             [ 70, "*腿"],
             [ 78, "*膝"],
             [ 92, "*脛"],
             [100, "*足"],
            ]
    return table
  end
  
end
