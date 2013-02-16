#--*-coding:utf-8-*--

class Elysion < DiceBot
  
  def initialize
    super
  end
  
  
  def prefixs
    ['date.*', 'EL.*']
  end
  #'PCR', 'PSS', 'PCR', 'PSC', 'PDM', 'PLB', 'PRF', 'PLA', 'PPL', 'PIC', 'PSA', 'PDV', 'PGT']
  
  def gameName
    'エリュシオン'
  end
  
  def gameType
    "Elysion"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・判定（ELn+m）
　能力値 n 、既存の達成値 m（アシストの場合）
例）
　EL3　：能力値３で判定。 
　EL5+10：能力値５、達成値が１０の状態にアシストで判定。
・デート表（DATE）
　2人が「DATE」とコマンドをそれぞれ1回ずつ打つと、両者を組み合わせてデート表の結果が表示されます。
・デート表（DATE[PC名1,PC名2]）
　1コマンドでデート判定を行い、デート表の結果を表示します。
MESSAGETEXT
  end
  
  def changeText(string)
    string
  end
  
  def dice_command(string, name)
    string = @@bcdice.getOriginalMessage
    debug('dice_command string', string)
    
    secret_flg = false
    
    prefixsRegText = prefixs.join('|')
    
    unless ( /(^|\s)(S)?(#{prefixsRegText})/i =~ string )
      debug("NOT match")
      return '1', secret_flg
    end
    
    debug("matched.")
    
    secretMarker = $2
    command = $3
    
    output_msg = executeCommand(command)
    
    debug('secretMarker', secretMarker)
    if( secretMarker )
      debug("隠しロール")
      secret_flg = true unless( output_msg.empty? )
    end
    
    unless( output_msg.empty? )
      output_msg = "#{name}: #{output_msg}"
      debug("rating output_msg, secret_flg", output_msg, secret_flg)
    else
      output_msg = '1'
    end
      
    return output_msg, secret_flg
  end
  
  
  def executeCommand(command)
    debug('executeCommand command', command)

    result = ''
    case command
    when /EL(\d*)(\+\d+)?/i
      base = $1
      modify = $2
      result= check(base, modify)
      
    when /DATE\[(.*),(.*)\]/i
      pc1 = $1
      pc2 = $2
      result = getDateBothResult(pc1, pc2)
      
    when /DATE(\d\d)(\[(.*),(.*)\])?/i
      number = $1.to_i
      pc1 = $3
      pc2 = $4
      result =  getDateResult(number, pc1, pc2)
      
    when /DATE/i
      result =  getDateValue
      
=begin
    when /PCR/i
      resutl = getPlaceClassRoom
    when /PSS/i
      result = getPlaceSchoolStore
    when /PCR/i, /PSC/i, /PDM/i, /PLB/i, /PRF/i, /PLA/i, /PPL/i, /PIC/i, /PSA/i, /PDV/i, /PGT/i
=end
      
    else
      result = ''
    end
    
    return '' if result.empty? 
    
    return "#{command} ＞ #{result}"
  end
  
  
  def check(base, modify)
    base = getValue(base)
    modify = getValue(modify)
    
    dice1, dummy = roll(1, 6)
    dice2, dummy = roll(1, 6)
    
    diceTotal = dice1 + dice2
    addTotal = base + modify
    total = diceTotal + addTotal
    
    result = ""
    result << "(2D6#{getValueString(base)}#{getValueString(modify)})"
    
    if dice1 == dice2
      result << " ＞ #{diceTotal}[#{dice1},#{dice2}] ＞ #{diceTotal}"
      result << getSpecialResult(dice1, total)
      return result
    end
    
    result << " ＞ #{diceTotal}[#{dice1},#{dice2}]#{getValueString(addTotal)} ＞ #{total}"
    result << getCheckResult(total)
    
    return result
  end
  
  def getValue(string)
    return 0 if string.nil? 
    return string.to_i
  end
  
  def getValueString(value)
    return "+#{value}" if value > 0
    return "-#{value}" if value < 0
    return ""
  end
  
  
  def getCheckResult(total)
    success = getSuccessRank(total)
    
    return " ＞ 失敗" if success == 0
    return getSuccessResult(success)
  end
  
  def getSuccessResult(success)
    
    result = " ＞ 成功度#{success}"
    result << " ＞ 大成功 《アウル》2点獲得" if success >= @@successMax
    
    return result
  end
  
  @@successMax = 5
  
  def getSuccessRank(total)
    success = ((total - 9) / 5.0).ceil
    success = 0 if success < 0 
    success = @@successMax if success > @@successMax
    return success
  end
  
  
  def getSpecialResult(number, total)
    debug("getSpecialResult", number)
    
    if number == 6
      return getCriticalResult
    end
    
    return getFambleResultText(number, total)
  end
  
  def getCriticalResult
    getSuccessResult(@@successMax)
  end
  
  def getFambleResultText(number, total)
    debug("getFambleResultText number", number)
    
    if number == 1
      return " ＞ 大失敗"
    end
    
    result = getCheckResult(total)
    result << " ／ (#{number -1}回目のアシストなら)大失敗"
    
    debug("getFambleResultText result", result)
    
    return result
  end
  
  def getDateBothResult(pc1, pc2)
    dice1, dummy = roll(1, 6)
    dice2, dummy = roll(1, 6)
    
    result =  "#{pc1}[#{dice1}],#{pc2}[#{dice2}] ＞ "
    
    number = dice1 * 10 + dice2
    
    if( dice1 > dice2 )
      tmp = pc1
      pc1 = pc2
      pc2 = tmp
      number = dice2 * 10 + dice1
    end
    
    result <<  getDateResult(number, pc1, pc2)
    
    return result
  end
  
  def getDateResult(number, pc1, pc2)
    
    name = 'デート'
    
    table = [
             [11, '「こんなはずじゃなかったのにッ！」仲良くするつもりが、ひどい喧嘩になってしまう。この表の使用者のお互いに対する《感情値》が1点上昇し、属性が《敵意》になる。'],
             [12, '「あなたってサイテー!!」大きな誤解が生まれる。受け身キャラの攻め気キャラ以外に対する《感情値》がすべて0になり、その値のぶんだけ攻め気キャラに対する《感情値》が上昇し、その属性が《敵意》になる。'],
             [13, '「ねぇねぇ知ってる…？」せっかく二人きりなのに、他人の話で盛り上がる。この表の使用者は、PCの中からこの表の使用者以外のキャラクター一人を選び、そのキャラクターに対する《感情値》が1点上昇する。'],
             [14, '「そこもっとくわしく！」互いの好きなものについて語り合う。受け身キャラは、攻め気キャラの「好きなもの」一つを選ぶ。受け身キャラは、自分の「好きなもの」一つをそれに変更したうえで、攻め気キャラへの《感情値》が2点上昇し、その属性が《好意》になる。'],
             [15, '「なぁ、オレのことどう思う？」思い切った質問！受け身キャラは、攻め気キャラに対する《感情値》を2上昇させ、その属性を好きなものに変更できる。'],
             [16, '「あなたのこと心配してるんじゃないんだからね！」少し前の失敗について色々と言われてしまう。ありがたいんだけど、少しムカつく。受け身キャラは、攻め気キャラに対する《感情値》が2点上昇する。'],
             [22, '「え、もうこんな時間!?」一休みするつもりが、気がつくとかなり時間がたっている。この表の使用者のお互いに対する《感情値》が1点上昇し、《アウル》1点を獲得する。'],
             [23, '「気になってることがあるんだけど…？」何気ない質問だが、これは難しい。変な答えはできないぞ。攻め気キャラは〔学力〕で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [24, '「なんか面白いとこ連れてって」うーん、これは難しい注文かも？攻め気キャラは、〔政治力〕で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [25, '「うーん、ちょっと困ったことがあってさ」悩みを相談されてしまう。ここはちゃんと答えないと。攻め気キャラは、〔青春力〕で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [26, '「天魔だ。後ろにさがってろ！」何処からとも無く現れた天魔に襲われる。攻め気キャラは好きな能力値で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、互いに1D6点のダメージを受けつつ、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [33, '「ごめん、勘違いしてた」誤解が解ける。この表の使用者のお互いに対する《感情値》が1点上昇し、《好意》になる。'],
             [34, '「これ、キミにしか言ってないんだ。二人だけの秘密」受け身キャラが隠している夢が秘密を攻め気キャラが知ってしまう。受け身キャラの攻め気キャラに対する《感情値》が2点上昇する。'],
             [35, '「これからも、よろしく頼むぜ。相棒」攻め気キャラが快活に微笑む。受け身キャラの攻め気キャラに対する《感情値》が2点上昇する。'],
             [36, '「わ、わたしは、あなたのことが…」受け身キャラの思わぬ告白！受け身キャラの攻め気キャラに対する《感情値》が2点上昇する。'],
             [44, '「大丈夫？痛くないか？」互いに傷を治療しあう。この表の使用者は、お互いの自分に対する[《好意》×1D6]点だけ、自分の《生命力》を回復する事ができる。でちらかの《生命力》が1点以上回復したら、この表の使用者のお互いに対する《感情値》が1点上昇する。'],
             [45, '「この事件が終わったら、伝えたい事が…あるんだ」攻め気キャラの真剣な言葉。え、それって…？受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《好意》になる。エピローグに攻め気キャラが生きていれば、この表の使用者のお互いに対する《感情値》がさらに2点上昇する。ただし、以降このセッションの間、攻め気キャラは「致命傷表」を使用したとき、二つのサイコロを振って低い目を使う。'],
             [46, '「停電ッ!?…って、どこ触ってるんですかッ!?」辺りが不意に暗くなり、思わず変なところを触ってしまう。攻め気キャラの受け身キャラに対する《感情値》が2点上昇し、その属性が《好意》になる。また、受け身キャラの攻め気キャラに対する《感情値》が2点上昇し、その属性が＜敵意＞になる。'],
             [55, '「お前ってそんなやつだったんだ？」意外な一面を発見する。互いに対する《感情値》が1点上昇し、その属性が反転する。'],
             [56, '「え？え？えぇぇぇぇッ?!」ふとした拍子に唇がふれあう。受け身キャラの攻め気キャラ以外に対する《感情値》が全て0になり、その値の分だけ攻め気キャラに対する《感情値》が上昇し、その属性が《好意》になる。'],
             [66, '「…………」気がつくとお互い、目をそらせなくなってしまう。そのまま顔を寄せ合い…。この表の使用者のお互いに対する《感情値》が3点上昇する。'],
            ]
    
    debug("number", number)
    text = get_table_by_number(number, table)
    text = changePcName(text, '受け身キャラ', pc1)
    text = changePcName(text, '攻め気キャラ', pc2)
    
    return "#{name}(#{number}) ＞ #{text}"
  end
    
  def changePcName(text, base, name)
    return text if name.nil? or name.empty?
    
    return text.gsub(/(#{base})/){$1 + "(#{name})"}
  end
  
  
  def getDateValue
    dice1, dummy = roll(1, 6)
    return "#{dice1}"
  end
  
  
  def getPlaceClassRoom
    placeName = '教室休憩表'
    table = [
             '「風紀委員の巡回！」',
             '「引き出しのパン」',
             '「授業の質問」',
             '「先生の依頼」',
             '「誰かの視線」',
             '「遊びの誘い」',
             '「居眠り」',
             '「お腹空いた」',
             '「クラスの噂」',
             '「ラブレター!?」',
             '「笑い声」',
            ]
    getPlaceResult(placeName, table)
  end
  
  def getPlaceSchoolStore
    placeName = '購買'
    table = [
             '「風紀委員の巡回！」',
             '「まとめ買いセール」',
             '「防具セール！」',
             '「武器セール！」',
             '「色々セール！」',
             '「ウィンドウショッピング」',
             '「試食」',
             '「購買での出会い」',
             '「高価買取！」',
             '「デリバリー」',
             '「財布紛失」',
            ]
    getPlaceResult(placeName, table)
  end
  
  def getPlacexxxx
    placeName = ''
    table = [
             '「風紀委員の巡回！」',
             '「」',
             '「」',
             '「」',
             '「」',
             '「」',
             '「」',
             '「」',
             '「」',
             '「」',
             '「」',
            ]
    getPlaceResult(placeName, table)
  end
  
  def getPlaceResult(placeName, table)
    number, dice_dmy = roll(2, 6)
    index = number - 2
    
    text = table[index]
    return '' if( text.nil? )
    
    return "#{placeName}(#{number}) ＞ #{ text }"
  end
  
end
