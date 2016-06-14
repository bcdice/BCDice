# -*- coding: utf-8 -*-

class Dracurouge < DiceBot
  
  def initialize
    super
    @d66Type = 1
  end
  
  
  def prefixs
    ['DR.*', 'RT.*', 'CT\d+'] + @@tables.keys
  end
  
  def gameName
    'ドラクルージュ'
  end
  
  def gameType
    "Dracurouge"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・行い判定（DRx+y）
　x：振るサイコロの数（省略時４）、y：渇き修正（省略時０）
　例） DR　DR6　DR+1　DR5+2
・抗い判定（DRRx）
　x：振るサイコロの数
　例） DRR3
・堕落表（CTx） x：渇き （例） CT3
・堕落の兆し表（CS）
・絆内容決定表（BT）
・反応表（RTxy）x：血統、y：道　xy省略で一括表示
　　血統　D：ドラク、R：ローゼンブルク、H：ヘルズガルド、M：ダストハイム、
　　　　　A：アヴァローム　N：ノスフェラス
　　道　　F：領主、G：近衛、R：遍歴、W：賢者、J：狩人、N：夜獣
　例）RT（一括表示）、RTDF（ドラク領主）、RTAN（アヴァロームの野獣）
・D66ダイスあり
MESSAGETEXT
  end
  
  
  def rollDiceCommand(command)
    debug('rollDiceCommand')
    
    result = getConductResult(command)
    return result unless result.nil?
    
    result = getResistResult(command)
    return result unless result.nil?
    
    result = getReactionResult(command)
    return result unless result.nil?
    
    result = getCorruptionResult(command)
    return result unless result.nil?
    
    result = getTableResult(command)
    return result unless result.nil?
    
    return nil
  end
  
  
  def getConductResult(command)
    return nil unless /^DR(\d*)(\+(\d+))?$/ === command
    
    diceCount = $1.to_i
    diceCount = 4 if diceCount == 0
    thirstyPoint = $3.to_i
    
    diceList = rollDiceList(diceCount)
    
    gloryDiceCount = getGloryDiceCount(diceList)
    gloryDiceCount.times{ diceList << 10 }
    
    diceList, calculationProcess = getThirstyAddedResult(diceList, thirstyPoint)
    thirstyPointMarker = (thirstyPoint == 0 ? "" : "+#{thirstyPoint}")
    
	result = "(#{command}) ＞ #{diceCount}D6#{thirstyPointMarker} ＞ "
	result += "[ #{calculationProcess} ] ＞ " unless calculationProcess.empty?
	result += "[ #{diceList.join(', ')} ]"
    return result
  end
  
  
  def rollDiceList(diceCount)
    dice, str = roll(diceCount, 6)
    diceList = str.split(/,/).collect{|i|i.to_i}.sort
    
    return diceList
  end
  
  
  def getGloryDiceCount(diceList)
    oneCount = countTargetDice(diceList, 1)
    sixCount = countTargetDice(diceList, 6)
    
    gloryDiceCount = (oneCount / 2) + (sixCount / 2)
    return gloryDiceCount
  end
  
  
  def countTargetDice(diceList, target)
    diceList.select{|i|i == target}.count
  end
  
  
  def getThirstyAddedResult(diceList, thirstyPoint)
    return diceList, '' if thirstyPoint == 0 
    
    targetIndex = diceList.rindex{|i| i <= 6}
    return diceList, '' if targetIndex.nil?
    
    textList = []
    
    diceList.each_with_index do |item, index|
      if targetIndex == index
        textList << "#{item}+#{thirstyPoint}"
      else
        textList << item.to_s
      end
    end
    
    diceList[targetIndex] += thirstyPoint
    
    return diceList, textList.join(', ')
  end
  
  
  
  def getResistResult(command)
    return nil unless /^DRR(\d+)$/ === command 
    
    diceCount = $1.to_i
    diceCount = 4 if diceCount == 0
    
    diceList = rollDiceList(diceCount)
    
	result = "(#{command}) ＞ #{diceCount}D6 ＞ [ #{diceList.join(', ')} ]"

  end
  
  
  
  def getReactionResult(command)
    return nil unless /^RT((\w)(\w))?/ === command.upcase
    
    typeText1 = $2
    typeText2 = $3
    
    name = "反応表"
    table = getReactionTable
    tableText, number = get_table_by_d66(table)
    
    type1 = %w{ドラク	ローゼンブルク	ヘルズガルド	ダストハイム	アヴァローム	ノスフェラス}
    type1_indexTexts = %w{D R H M A N}
	type2 = %w{領主	近衛	遍歴	賢者	狩人	夜獣}
    type2_indexTexts = %w{F G R W J N}
    
    tensValue = number.to_i / 10
    isBefore = (tensValue < 4 )
    type = (isBefore ? type1 : type2)
    indexTexts = (isBefore ? type1_indexTexts : type2_indexTexts)
    typeText = (isBefore ? typeText1 : typeText2)
    
    resultText = ''
    if typeText.nil? 
      resultText = getReactionTextFull(type, tableText)
    else
      index = indexTexts.index(typeText)
      return nil if index.nil?
      resultText = getReactionTex(index, type, tableText)
    end
    
    return "#{name}(#{number}) ＞ #{resultText}"
  end
  
  
  def getReactionTextFull(type, tableText)
    resultTexts = []
    
    type.count.times do |index|
      resultTexts << getReactionTex(index, type, tableText)
    end
    
    return resultTexts.join('／')
  end
  
  def getReactionTex(index, type, tableText)
      typeName = type[index]
      texts = tableText.split(/\t/)
      string = texts[index]
      
      return "#{typeName}：#{string}"
  end
  
  
  def getReactionTable
      text = <<TEXT_BLOCK
空に輝く紅い月を仰ぐ	鼻で笑う	自粛を呼びかける咳払いをする	眉を寄せて考え込む	欠伸を噛み殺す	冥王領の方角を睨む
小さくため息をつく	前髪をかき上げる	眉をひそめる	周りを値踏みする目で見る	頭をかく	舌打ちをする
相手を見下すように見る	己の髪をいじる	小言を言う	手元に本を具現化し書き込む	手元に生じた果実を食べる	俯いて床や地面を睨む
じっと目を合わせ語りかける	一人小さく笑う	無表情で相手を観察する	つまらなそうに眺める	人懐っこい笑みを浮かべる	無意識に涙が伝う
かすかに微笑んで見せる	ハミングで歌を口ずさむ	足元に小さな地獄門が生じる	落ち着いた歩調で近づく	夜鳥が肩にとまって来る	唇を噛む
懐から蝙蝠が飛び立つ	片足を軸に、くるりと回る	周囲にわずかな怨嗟の声が響く	目を閉じ、過去に想いを馳せる	黒猫が足元にじゃれて来る	胸を押さえじっと考える
頭上を蝙蝠が渦巻くように飛ぶ	花弁を具現化し散らす	咎めるような目を向ける	歩む跡、かすかな霧が舞う	周囲を妖精の光が舞う	首を打ち振って邪念を払う
眉を寄せると共に、目が紅く光る	衣装や鎧の色や装飾を変える	直立不動の姿勢で立つ	苦笑を浮かべて歩み寄る	瞬時に相手の側に現れる	内心の怒りに険しい貌となる
手の中のワインを一口すする	己に酔い、目を閉じる	呆れた様子でため息をつく	現状を分析する独り言を言う	瞬時に相手から離れる	毅然とした態度で立ち向かう
全身から薄紅色のオーラを発する	具現化した華を手の中で弄ぶ	突然、振り返って睨む	興味深そうに質問する	虫や植物に気を取られる	渇いた笑い声を漏らす
不敵な笑みを浮かべる	気になる相手を口説こうとする	周囲の空気が凍りつく	目の前の様式に文句を言う	無垢な笑みを見せる	己の血族を貶める言葉を紡ぐ
風もなく髪が舞う	肩をすくめる	胸に手を当て、己を落ち着かせる	無感動に会釈をする	うっかり誰かを巻き込んでころぶ	静かな怒りと共に目が青白く光る
飽きた目で相手を見据える	己の武器に口づけをする	手の中に具現化した鎖を弄ぶ	手の中に具現化したペンを弄ぶ	誰かに甘えるようにもたれかかる	野の花に触れ、それを枯らす
足元に小さなつむじ風が起こる	誘うように誰かの手を取る	周囲を厳しい目で見渡す	目を見開き、感心する	笑みを浮かべながら頷く	疲れた様子で淡く光る吐息を吐く
激情や緊張感に髪が逆立つ	楽器を具現化し音を奏でる	仲間に疑いの視線を向ける	本、袖、マントなどで口元を隠す	小さく首をかしげる	己の紋章をぼんやりと見つめる
紅い月の光を浴び、目を閉じる	相手にウィンクする	感情に合わせ周囲に鎖が具現化	宙に浮かび、すべるように進む	無数の黒い鳥の羽根が宙を舞う	自嘲的に小さく笑う
武器を掲げ、誓いの音頭を取る	衣装についた埃を払う	堕落について忠告する	無感情に状況を検分する	果実を取り出して食べる	疲れた目でぼんやりと他を見る
己の紋章をじっと見つめる	マントから無数の蝶が飛び立つ	冷たい視線で相手を一瞥する	一瞬、姿が霧に包まれぼやける	思わせぶりな言葉や仕草をする	何か決心したように顔を上げる
領主	近衛	遍歴	賢者	狩人	夜獣
相手の目を覗き心を探る	主の傍にそっと寄り添う	かつての戦いについて語る	相手を推し測るように見つめる	“敵”を思い出し険しい目になる	獣のような荒い呼吸をする
己の領地に想いを馳せる	紋章の刻まれた盾を掲げる	風に髪をなびかせる	メガネを具現化してかける	唾を吐く	潤んだ上目遣いで相手を見る
従者を侍らせる	武器を構えて上品に一礼する	具現化した乗騎を撫でる	わずかな点に目を留める	具現化した武器を撫でる	俯いて深呼吸する
従者の世話を受ける	己の盾の紋章を指でなぞる	仲間の肩を叩く、あるいは抱く	大げさにため息をついて見せる	陰鬱な目で虚空を睨む	壁や床に爪を立てて引っかく
好ましい相手を手招きする	他の騎士に寄り添う	爽やかに笑う	目を閉じて思索にふける	裾から現れた蛇か蜘蛛を撫でる	己に言い聞かせる独り言を言う
憂いに満ちた物思いにふける	主の背後から相手を睨む	高らかに名乗りをあげる	他の騎士に助言する	思いつめた目で夜空を見る	堕落の兆しをじっと見る
重々しく頷く	主の前、または傍らにひざまずく	周囲に積極的に話しかける	ごまかすように咳払いする	己の武器を舐めて見せる	他の騎士から目をそらす
優しげな微笑を浮かべる	きまり悪そうに顔を赤く染める	己の名に誓い、約束をする	わずかな会釈をする	暗い笑みを浮かべる	他の騎士の機嫌を窺う
ちらりと己の紋章を示す	誰かの前に立ちはだかる	大げさに誰かを褒めたたえる	他の騎士に目で合図をする	物陰に隠れる	相手を睨み唸る
ワインの杯を他の騎士に渡す	落ち着かなげに歩き回る	他の騎士に手合わせを乞う	謎めいた笑みを浮かべる	他の騎士の紋章を観察する	己の指先をちろりと舐め上げる
じっと風景を眺める	はにかんだ笑みを浮かべる	マントを大げさにひるがえす	空に浮かぶ星々を眺める	空気を読まない発言をする	他の騎士から距離を取り離れる
手の中にチェスの駒を具現化する	緊張した視線を周囲に巡らす	相手を褒めそやし口づけを求める	深い知識で詳しい説明をする	突然振り向いて背後に警戒する	獰猛な笑みを浮かべる
胸を張り、自信を持って発言する	心の中で他の騎士と試合をする	己の故郷を思い出す	未来について占ってみる	過去の無念に血涙を流す	己の肌を、爪などで傷つける
速やかに謝罪する	じっと動かず控えている	己の紋章について語る	ささやかな予言をする	鮫のように笑う	こっそり舌なめずりをする
他の騎士を正面から褒める	主をじっと見つめる	他の騎士と世間話をする	噂の類を他の騎士に囁く	その場にいない騎士を嘲笑う	妖しい流し目を送る
他の騎士の髪や頬を撫でる	主を褒めたたえる	困ったように小さく唸る	ふとした品を興味深く観察する	他の騎士とのへだたりを感じる	哀しげな目で己の紋章を見る
重々しく名乗りを上げる	主の袖を握りしめる	格上の前に跪いて礼を尽くす	月を見上げドラクルを褒め讃える	ぼそりと名乗りをあげる	獲物を狙う目で、他の騎士を見る
口元を隠しつつ上品に笑う	主に対する、周囲の態度を咎める	格下や人間に微笑みかける	他の騎士の感情をいさめる	格下を見下した目で見る	自虐的な言葉をつぶやく
TEXT_BLOCK
    
    return text.split(/\n/)
  end
  

  def getCorruptionResult(command)
    
    return nil unless /^CT(\d+)$/ === command.upcase
    
    modify = $1.to_i
    
    name = "堕落表"
    table = 
    [
     [ 0, "あなたは完全に堕落した。この時点であなたは［壁の華］となり、人狼、黒山羊、夜獣卿のいずれかとなる。その［幕］の終了後にセッションから退場する。247ページの「消滅・完全なる堕落」も参照すること。"],
     [ 1, "あなたの肉体は精神にふさわしい変異を起こす……。「堕落の兆し表」を2回振って特徴を得る。このセッション終了後、【道】を「夜獣」にすること。（既に「夜獣」なら【道】は変わらない）"],
     [ 3, "あなたの肉体は精神にふさわしい変異を起こす……。「堕落の兆し表」を1回振って特徴を得る。このセッション終了後、【道】を「夜獣」にすること。（既に「夜獣」なら【道】は変わらない）"],
     [ 5, "気高き心もやがて堕ちる。あなたが今、最も多くルージュを持つ対象へのルージュを全て失い、同じだけのノワールを得る。ノワールを得た結果【渇き】が3点以上になった場合は、再度堕落表を振ること。"],
     [ 6, "内なる獣の息遣い……あなたが今【渇き】を得たノワールの対象へ、任意のノワール2点を獲得する。"],
     [ 7, "内なる獣の息遣い……あなたが今【渇き】を得たノワールの対象へ、任意のノワール1点を獲得する。"],
     [ 8, "荒ぶる心を鎮める……幸いにも何も起きなかった。"],
     [99, "あなたは荒れ狂う感情を抑え、己を律した！　【渇き】が1減少する！"],
    ]
    
    number, number_text = roll(2, 6)
    index = (number - modify)
    debug('index', index)
    text = get_table_by_number(index, table)
    
    return "2D6[#{number_text}]-#{modify} ＞  #{name}(#{index}) ＞ #{text}"
  end
  
  def getTableResult(command)
  
    info = @@tables[command.upcase]
    return nil if info.nil?
    
    name = info[:name]
    type = info[:type]
    table = info[:table]
    
    text, number = 
      case type
      when '2D6'
        get_table_by_2d6(table)
      when '1D6'
        get_table_by_1d6(table)
      else
        nil
      end
    
    return nil if( text.nil? )
    
    return "#{name}(#{number}) ＞ #{text}"
  end
  
  def getCorruptionTable
  end
  
  
    @@tables =
    {
    'CS' => {
      :name => "堕落の兆し表",
      :type => '2D6',
      :table => %w{
あなたは完全に堕落した。この時点であなたは［壁の華］となり、人狼、黒山羊、夜獣卿のいずれかとなる。その［幕］の終了後にセッションから退場する。247ページの「消滅・完全なる堕落」も参照すること。
獣そのものの頭（狼、山羊、蝙蝠のいずれか）
夜鳥の翼
コウモリの翼
鉤爪ある異形の腕
ねじれた二本角
狼の耳と尾
青ざめた肌
異様な光を宿す目
突き出した犬歯
目に見える変化はない……
},},
    
    'BT' => {
      :name => "絆内容決定表：ルージュ／ノワール",
      :type => '1D6',
      :table => %w{
憐(Pity)　相手を憐れみ、慈しむ。／侮(Contempt)　相手を侮り、軽蔑する。
友(Friend)　相手に友情を持つ。／妬(Jealousy)　相手を羨望し、妬む。
信(Trust)　相手を信頼する。／欲(Desire)　相手を欲し、我がものにしたいと思う。
恋(Love)　相手に恋し、愛する。／怒(Anger)　相手に怒りを感じる。
敬(Respect)　相手の実力や精神を敬う。／殺(Kill)　相手に殺意を持ち、滅ぼそうと思う。
主(Obey)　相手を主と仰ぎ、忠誠を誓う。／仇(Vendetta)　相手を怨み、仇と狙う。
},},
  }
  
  
end
