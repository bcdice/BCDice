#--*-coding:utf-8-*--

class MagicaLogia < DiceBot
  
  def initialize
    super
    @sendMode = 2;
    @sortType = 3;
    @d66Type = 2;
  end
  
  
  def gameType
    "MagicaLogia"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・マギカロギア　変調表　　　　　(WT)
・　　　　　　　シーン表　　　　(ST)
・　　　　　　　ファンブル表　　(FT)
・　　　　　　　事件表　　　　　(AT)
・　　　　　　　運命変転表　　　(FCT)
・　　　　　　　経歴表　　　　　(BGT)
・　　　　　　　初期アンカー表　(DAT)
・　　　　　　　運命属性表　　　(FAT)
・　　　　　　　願い表　　　　　(WIT)
MESSAGETEXT
  end
  
  def changeText(string)
    string
  end
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    return '1', secret_flg unless( /((^|\s)(S)?([SFWAC]|FC|BG|DA|FA|WI|RT)T($|\s))/i =~ string )
    
    secretMarker = $3
    command = $1.upcase
    @nick = nick_e
    output_msg = magicalogia_table(command)
    if( secretMarker )    # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
      
    
    return output_msg, secret_flg
  end
  
  def dice_command_xRn(string, nick_e)
    ''
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    
    debug("total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max", total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    
    return '' unless(signOfInequality == ">=")
    
    output = 
    if(dice_n <= 2)
      " ＞ ファンブル";
    elsif(dice_n >= 12)
      " ＞ スペシャル(魔力1D6点か変調1つ回復)";
    elsif(total_n >= diff)
      " ＞ 成功";
    else
      " ＞ 失敗";
    end
    
    output += getGainMagicElementText()
    
    return output
  end
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    ''
  end
  
  def check_nD10(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)# ゲーム別成功度判定(nD10)
    ''
  end
  
  def check_1D10(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)     # ゲーム別成功度判定(1D10)
    ''
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    ''
  end
  
  

####################          マギカロギア         ########################
#** 表振り分け
  def magicalogia_table(string)
    output = '1';
    
    case string
    when /((\w)*BGT)/i   # 経歴表
      head = getHead(head)
      output = magicalogia_background_table( head )
    when /((\w)*DAT)/i   # 初期アンカー表
      head = getHead(head)
      output = magicalogia_defaultanchor_table( head )
    when /((\w)*FAT)/i   # 運命属性表
      head = getHead(head)
      output = magicalogia_fortune_attribution_table( head )
    when /((\w)*WIT)/i   # 願い表
      head = getHead(head)
      output = magicalogia_wish_table( head )
    when /((\w)*ST)/i  # シーン表
      head = getHead(head)
      output = magicalogia_scene_table( head )
    when /((\w)*FT)/i   # ファンブル表
      head = getHead(head)
      output = magicalogia_fumble_table( head )
    when /((\w)*WT)/i   # 変調表
      head = getHead(head)
      output = magicalogia_wrong_table( head )
    when /((\w)*(FC|C)T)/i   # 運命変転表
      head = getHead(head)
      output = magicalogia_fortunechange_table( head )
    when /((\w)*AT)/i   # 事件表
      head = getHead(head)
      output = magicalogia_accident_table( head )
    when /((\w)*RTT)/i   # ランダム特技決定表
      head = getHead(head)
      output = magicalogia_random_skill_table( head )
    end
    
    return output;
  end
  
  def getHead(head)
    if( head.nil? )
      return nil
    end
    
    return head.upcase
  end

  #** シーン表
  def magicalogia_scene_table(string)
    table = [
            '魔法で作り出した次元の狭間。ここは時間や空間から切り離された、どこでもあり、どこでもない場所だ。',
            '夢の中。遠く過ぎ去った日々が、あなたの前に現れる。',
            '静かなカフェの店内。珈琲の香りと共に、優しく穏やかな雰囲気が満ちている。',
            '強く風が吹き、雲が流されていく。遠く、雷鳴が聞こえた。どうやら、一雨きそうだ。',
            '無人の路地裏。ここならば、邪魔が入ることもないだろう。',
            '周囲で〈断章〉が引き起こした魔法災厄が発生する。ランダムに特技一つを選び、判定を行うこと。成功すると、好きな魔素が一個発生する。失敗すると「運命変転表」を使用する。',
            '夜の街を歩く。暖かな家々の明かりが、遠く見える。',
            '読んでいた本を閉じる。そこには、あなたが知りたがっていたことが書かれていた。なるほど、そういうことか。',
            '大勢の人々が行き過ぎる雑踏の中。あなたを気に掛ける者は誰もいない。',
            '街のはるか上空。あなたは重力から解き放たれ、自由に空を飛ぶ。',
            '未来の予感。このままだと起きるかもしれない出来事の幻が現れる。',
            ]
    
    text, numer = get_table_by_2d6(table)
    return "#{@nick}: シーン表(#{numer}) ＞ #{text}"
  end


#** ファンブル表
  def magicalogia_fumble_table(string)
    table = [
        '魔法災厄が、あなたのアンカーに降りかかる。「運命変転」が発生する。',
        '魔法災厄が、あなたの魔素を奪い取る。チャージしている魔素の中から、好きな組み合わせで2点減少する。',
        '魔法の制御に失敗してしまう。【魔力】が1点減少する。',
        '魔法災厄になり、そのサイクルが終了するまで、行為判定にマイナス1の修正が付く。',
        '魔法災厄が、直接あなたに降りかかる。変調表を振り、その変調を受ける。',
        'ふぅ、危なかった。特に何も起こらない。',
            ]
    
    text, numer = get_table_by_1d6(table)
    return "#{@nick}: ファンブル表(#{numer}) ＞ #{text}"
  end

#** 変調表
  def magicalogia_wrong_table(string)
    table = [
            '『封印』自分の魔法(習得タイプが装備以外)からランダムに一つ選ぶ。選んだ魔法のチェック欄をチェックする。その魔法を使用するには【魔力】を2点消費しなくてはいけない。',
            '『綻び』魔法戦の間、各ラウンドの終了時に自分の【魔力】が1点減少する。',
            '『虚弱』【攻撃力】が1点減少する。',
            '『病魔』【防御力】が1点減少する。',
            '『遮蔽』【根源力】が1点減少する',
            '『不運』1D6→2D6と振ってランダムに特技を一つ選ぶ。選んだ特技のチェック欄をチェックする。その特技が使用不能になり、その分野の特技が指定特技になった判定を行うとき、マイナス1の修正が付く。',
             ]
    
    text, numer = get_table_by_1d6(table)
    return "#{@nick}: 変調表(#{numer}) ＞ #{text}"
  end

  
#** 運命変転表
  def magicalogia_fortunechange_table(string)
    table = [
             '『挫折』そのキャラクターは、自分にとって大切だった夢を諦める。',
             '『別離』そのキャラクターにとって大切な人――親友や恋人、親や兄弟などを失う。',
             '『大病』そのキャラクターは、不治の病を負う。',
             '『借金』そのキャラクターは、悪人に利用され多額の借金を負う。',
             '『不和』そのキャラクターは、人間関係に失敗し深い心の傷を負う。',
             '『事故』そのキャラクターは交通事故にあい、取り返しのつかない怪我を負う。',
            ]
    text, number = get_table_by_1d6(table)
    return "#{@nick}: 運命変転表(#{number}) ＞ #{text}"
  end

  
#** 事件表
  def magicalogia_accident_table(string)
    table = [
             '不意のプレゼント、素晴らしいアイデア、悪魔的な取引……あなたは好きな魔素を1つ獲得するか【魔力】を1D6点回復できる。どちらかを選んだ場合、その人物に対する【運命】が1点上昇する。【運命】の属性は、ゲームマスターが自由に決定できる。',
             '気高き犠牲、真摯な想い、圧倒的な力……その人物に対する【運命】が1点上昇する。【運命】の属性は「尊敬」になる。',
             '軽い口論、殴り合いの喧嘩、魔法戦……互いに1D6を振り、低い目を振った方が、高い目を振った方に対して【運命】が1点上昇する。【運命】の属性は「尊敬」になる。',
             '裏切り、策謀、不幸な誤解……その人物に対する【運命】が1点上昇する。【運命】の属性は「宿敵」になる。',
             '意図せぬ感謝、窮地からの救済、一生のお願いを叶える……その人物に対する【運命】が1点上昇する。【運命】の属性は「支配」になる。',
             '生ける屍の群れ、地獄の業火、迷宮化……魔法災厄に襲われる。ランダムに特技一つを選んで判定を行う。失敗すると、その人物に対し「運命変転表」を使用する。',
             '道路の曲がり角、コンビニ、空から落ちてくる……偶然出会う。その人物に対する【運命】が1点上昇する。【運命】の属性は「興味」になる。',
             '魂のひらめき、愛の告白、怪しい抱擁……その人物に対する【運命】が1点上昇する。【運命】の属性は「恋愛」になる。',
             '師弟関係、恋人同士、すれ違う想い……その人物との未来が垣間見える。たがいに対する【運命】が1点上昇する。',
             '懐かしい表情、大切な思い出、伴侶となる予感……その人物に対する【運命】が1点上昇する。【運命】の属性は「血縁」になる。',
             '献身的な看護、魔法的な祝福、奇跡……その人物に対する【運命】が1点上昇する。【運命】の属性は自由に決定できる。もしも関係欄に疵があれば、その疵を1つ関係欄から消すことができる。',
            ]
    
    text, number = get_table_by_2d6(table)
    return "#{@nick}: 事件表(#{number}) ＞ #{text}"
  end
  
#** 魔素獲得チェック
  def getGainMagicElementText()
    diceList = getDiceList
    debug("getGainMagicElementText diceList", diceList)
    
    return '' if( diceList.empty? )

    dice1 = diceList[0]
    dice2 = diceList[1]
    
    #マギカロギア用魔素取得判定
    return  gainMagicElement(dice1, dice2);
  end
  

  def gainMagicElement(dice1, dice2)
    return "" unless(dice1 == dice2)
    
    # ゾロ目
    table = ['星','獣','力','歌','夢','闇']
    return " ＞ " + table[dice1 - 1] + "の魔素2が発生";
  end
  
  
#** 経歴表
  def magicalogia_background_table(string)
    table = [
        '書警／ブックウォッチ',
        '司書／ライブラリアン',
        '書工／アルチザン',
        '訪問者／ゲスト',
        '異端者／アウトサイダー',
        '外典／アポクリファ',
            ]
    
    text, number = get_table_by_1d6(table)
    return "#{@nick}: 経歴表(#{number}) ＞ #{text}"
  end
  
  
#** 初期アンカー表
  def magicalogia_defaultanchor_table(string)
    table = [
        '『恩人』あなたは、困っているところを、そのアンカーに助けてもらった。',
        '『居候』あなたかアンカーは、どちらかの家や経営するアパートに住んでいる。',
        '『酒友』あなたとアンカーは、酒飲み友達である。',
        '『常連』あなたかアンカーは、その仕事場によくやって来る。',
        '『同人』あなたは、そのアンカーと同じ趣味を楽しむ同好の士である。',
        '『隣人』あなたは、そのアンカーの近所に住んでいる。',
        '『同輩』あなたはそのアンカーと仕事場、もしくは学校が同じである。',
        '『文通』あなたは、手紙やメール越しにそのアンカーと意見を交換している。',
        '『旧友』あなたは、そのアンカーと以前に、親交があった。',
        '『庇護』あなたは、そのアンカーを秘かに見守っている。',
        '『情人』あなたは、そのアンカーと肉体関係を結んでいる。',
            ]
  
    text, number = get_table_by_2d6(table)
    return "#{@nick}: 初期アンカー表(#{number}) ＞ #{text}"
  end
  
  
#** 運命属性表
  def magicalogia_fortune_attribution_table(string)
    table = [
        '『血縁』自分や、自分が愛した者の親類や家族。',
        '『支配』あなたの部下になることが運命づけられた相手。',
        '『宿敵』何らかの方法で戦いあい、競い合う不倶戴天の敵。',
        '『恋愛』心を奪われ、相手に強い感情を抱いている存在。',
        '『興味』とても稀少だったり、不可解だったりして研究や観察をしたくなる対象。',
        '『尊敬』その才能や思想、姿勢に対し畏敬や尊敬を抱く人物。',
            ]
    
    text, number = get_table_by_1d6(table)
    return "#{@nick}: 運命属性表(#{number}) ＞ #{text}"
  end
  
  
#** 願い表
  def magicalogia_wish_table(string)
    table = [
        '自分以外の特定の誰かを助けてあげて欲しい。',
        '自分の大切な人や憧れの人に会わせて欲しい。',
        '自分をとりまく不幸を消し去って欲しい。',
        '自分のなくした何かを取り戻して欲しい。',
        '特定の誰かを罰して欲しい。',
        '自分の欲望（金銭欲、名誉欲、肉欲、知識欲など）を満たして欲しい。',
            ]
    
    text, number = get_table_by_1d6(table)
    return "#{@nick}: 願い表(#{number}) ＞ #{text}"
  end
  
#** 指定特技ランダム決定表
  def magicalogia_random_skill_table(string)
    output = '1';
    type = 'ランダム';
    
    skillTableFull = [
      ['星', ['黄金', '大地', '森', '道', '海', '静寂', '雨', '嵐', '太陽', '天空', '異界']],
      ['獣', ['肉', '蟲', '花', '血', '鱗', '混沌', '牙', '叫び', '怒り', '翼', 'エロス']],
      ['力', ['重力', '風', '流れ', '水', '波', '自由', '衝撃', '雷', '炎', '光', '円環']],
      ['歌', ['物語', '旋律', '涙', '別れ', '微笑み', '想い', '勝利', '恋', '情熱', '癒し', '時']],
      ['夢', ['追憶', '謎', '嘘', '不安', '眠り', '偶然', '幻', '狂気', '祈り', '希望', '未来']],
      ['闇', ['深淵', '腐敗', '裏切り', '迷い', '怠惰', '歪み', '不幸', 'バカ', '悪意', '絶望', '死']],
    ]
    
    skillTable, total_n = get_table_by_1d6(skillTableFull)
    tableName, skillTable = skillTable
    skill, total_n2 = get_table_by_2d6(skillTable)
    
    output = "#{@nick}: #{type}指定特技表(#{total_n},#{total_n2}) ＞ 『#{tableName}』#{skill}"
    
    return output;
  end
  
end
