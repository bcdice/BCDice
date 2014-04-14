#--*-coding:utf-8-*--

class KanColle < DiceBot
  
  def initialize
    super
    @sendMode = 2
    @sortType = 3
    @d66Type = 2
  end
  def gameName
    '艦これRPG'
  end
  
  def gameType
    "KanColle"
  end
  
  def prefixs
     ['ET', 'ACT',  
      'EVNT', 'EVKT', 'EVAT', 'EVET', 'EVENT', 'EVST', 
      'DVT', 'DVTM', 'WP1T', 'WP2T', 'WP3T', 'WP4T', 'ITT', 'MHT', 'SNT',
      'KTM', 'BT', 'KHT', 'KMT', 'KST', 'KSYT', 'KKT', 'KSNT', 'SNZ',
      ]
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
例) 2D6 ： 単純に2D6した値を出します。
例) 2D6>=7 ： 行為判定。2D6して目標値7以上出れば成功。
例) 2D6+2>=7 ： 行為判定。2D6に修正+2をした上で目標値7以上になれば成功。

2D6での行為判定時は1ゾロでファンブル、6ゾロでスペシャル扱いになります。
天龍ちゃんスペシャルは手動で判定してください。

・各種表
　・感情表　ET／アクシデント表　ACT
　・日常イベント表　EVNT／交流イベント表　EVKT／遊びイベント表　EVAT
　　演習イベント表　EVET／遠征イベント表　EVENT／作戦イベント表　EVST
　・開発表　DVT／開発表（一括）DVTM
　　　装備１種表　WP1T／装備２種表　WP2T／装備３種表　WP3T／装備４種表　WP4T
　・アイテム表　ITT／目標表　MHT／戦果表　SNT
　・ランダム個性選択：一括　KTM／分野　BT
　　　背景　KHT／魅力　KMT／性格　KST／趣味　KSYT／航海　KKT／戦闘　KSNT
　・戦場表　SNZ

・D66ダイス(D66S相当=低い方が10の桁になる)
INFO_MESSAGE_TEXT
  end
  
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    return '' unless( signOfInequality == ">=")
    
    if(dice_n <= 2)
      return " ＞ ファンブル（判定失敗。アクシデント表を自分のＰＣに適用）"
    elsif(dice_n >= 12)
      return " ＞ スペシャル（判定成功。【行動力】が１Ｄ６点回復）"
    elsif(total_n >= diff)
      return " ＞ 成功"
    else
      return " ＞ 失敗"
    end
  end
  
  def rollDiceCommand(command)
    output = '1'
    type = ""
    total_n = ""

    case command
    when 'ET'
      type='感情表'
      output, total_n =  get_emotion_table
    when 'ACT'
      type='アクシデント表'
      output, total_n =  get_accident_table

    when 'EVNT'
      type='日常イベント表'
      output, total_n =  get_nichijyou_event_table
    when 'EVKT'
      type='交流イベント表'
      output, total_n =  get_kouryu_event_table
    when 'EVAT'
      type='遊びイベント表'
      output, total_n =  get_asobi_event_table
    when 'EVET'
      type='演習イベント表'
      output, total_n =  get_ensyuu_event_table
    when 'EVENT'
      type='遠征イベント表'
      output, total_n =  get_ensei_event_table
    when 'EVST'
      type='作戦イベント表'
      output, total_n =  get_sakusen_event_table

    when 'DVT'
      type='開発表'
      output, total_n =  get_develop_table
    when 'DVTM'
      type='開発表（一括）'
      output, total_n =  get_develop_matome_table
    when 'WP1T'
      type='装備１種表'
      output, total_n =  get_weapon1_table
    when 'WP2T'
      type='装備２種表'
      output, total_n =  get_weapon2_table
    when 'WP3T'
      type='装備３種表'
      output, total_n =  get_weapon3_table
    when 'WP4T'
      type='装備４種表'
      output, total_n =  get_weapon4_table
    when 'ITT'
      type='アイテム表'
      output, total_n =  get_item_table
    when 'MHT'
      type='目標表'
      output, total_n =  get_mokuhyou_table
    when 'SNT'
      type='戦果表'
      output, total_n =  get_senka_table
    
    when 'KTM'
      type='個性：一括'
      output, total_n =  get_kosei_table
    when 'BT'
      type='個性：分野表'
      output, total_n =  get_bunya_table
    when 'KHT'
      type='個性：背景表'
      output, total_n =  get_kosei_haikei_table
    when 'KMT'
      type='個性：魅力表'
      output, total_n =  get_kosei_miryoku_table
    when 'KST'
      type='個性：性格表'
      output, total_n =  get_kosei_seikaku_table
    when 'KSYT'
      type='個性：趣味表'
      output, total_n =  get_kosei_syumi_table
    when 'KKT'
      type='個性：航海表'
      output, total_n =  get_kosei_koukai_table
    when 'KSNT'
      type='個性：戦闘表'
      output, total_n =  get_kosei_sentou_table

    when 'SNZ'
      type='戦場表'
      output, total_n =  get_senzyou_table


    end
        
    return "#{type}(#{total_n}) ＞ #{output}"
    
  end
  
  # 感情表
  def get_emotion_table
    table = [
        'かわいい（プラス）／むかつく（マイナス）',
        'すごい（プラス）／ざんねん（マイナス）',
        'たのしい（プラス）／こわい（マイナス）',
        'かっこいい（プラス）／しんぱい（マイナス）',
        'いとしい（プラス）／かまってほしい（マイナス）',
        'だいすき（プラス）／だいっきらい（マイナス）',
    ]
    
    return get_table_by_1d6(table)
  end

  # アクシデント表
  def get_accident_table
    table = [
        'よかったぁ。何もなし。',
        '意外な手応え。その判定に使った個性の属性（【長所】と【弱点】）が反対になる。自分が判定を行うとき以外はこの効果は無視する。',
        'えーん。大失態。このキャラクターに対して【感情値】を持っているキャラクター全員の声援欄にチェックが入る。',
        '奇妙な猫がまとわりつく。サイクルの終了時、もしくは、艦隊戦の終了時まで、自分の行う行為判定にマイナス１の修正がつく（この効果は、マイナス２まで累積する）。',
        'いててて。損傷が一つ発生する。もしも艦隊戦中なら、自分と同じ航行序列にいる味方艦にも損傷が一つ発生する。',
        'ううう。やりすぎちゃった！自分の【行動力】が１Ｄ６点減少する。',
    ]
    
    return get_table_by_1d6(table)
  end
  
    
  # 日常イベント表
  def get_nichijyou_event_table
      table = [
				'何もない日々：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は、《待機／航海７》で判定。',
				'ティータイム：《外国暮らし／背景１２》で判定。',
				'釣り：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《おおらか／性格３》で判定。',
				'お昼寝：《寝る／趣味２》で判定。',
				'綺麗におそうじ！：《衛生／航海１１》で判定。',
				'海軍カレー：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《食べ物／趣味６》で判定。',
				'銀蝿／ギンバイ：《規律／航海５》で判定。',
				'日々の訓練：《素直／魅力２》で判定。',
				'取材：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《名声／背景３》で判定。',
				'海水浴：《突撃／戦闘６》で判定。',
				'マイブーム：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《口ぐせ／背景６》で判定。',
			]
    table.each{|i| i.gsub!(/$/, '（P220）')}
    return get_table_by_2d6(table)
  end
  
  # 交流イベント表
  def get_kouryu_event_table
      table = [
      			'一触即発！：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《笑顔／魅力７》で判定。',
      			'手取り足取り：自分以外の好きなＰＣ１人を選んで、《えっち／魅力１１》で判定。',
      			'恋は戦争：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《恋愛／趣味１２》で判定。',
      			'マッサージ：自分以外の好きなＰＣ１人を選んで、《けなげ／魅力６》で判定。',
      			'裸のつきあい：《入浴／趣味１１》で判定。',
      			'深夜のガールズトーク：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《おしゃべり／趣味７》で判定。',
      			'いいまちがえ：《ばか／魅力８》で判定。',
      			'小言百より慈愛の一語：自分以外の好きなＰＣ１人を選んで、《面倒見／性格４》で判定。',
      			'差し入れ：自分以外の好きなＰＣ１人を選んで、提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《優しい／魅力４》で判定。',
      			'お手紙：自分以外の好きなＰＣ１人を選んで、《古風／背景５》で判定。',
      			'昔語り：自分以外の好きなＰＣ１人を選んで、提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《暗い過去／背景４》で判定。',
      ]
    table.each{|i| i.gsub!(/$/, '（P221）')}
    return get_table_by_2d6(table)
  end
  
  
  # 遊びイベント表
  def get_asobi_event_table
      table = [
				'遊びのつもりが……：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《さわやか／魅力９》で判定。',
				'新しい遊びの開発：《空想／趣味３》で判定。',
				'宴会：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《元気／性格７》で判定。',
				'街をぶらつく：《面白い／魅力１０》で判定。',
				'ガールズコーデ：《おしゃれ／趣味１０》で判定。',
				'○○大会開催！：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《大胆／性格１２》で判定。',
				'チェス勝負：自分以外の好きなＰＣ１人を選んで、《クール／魅力３》で判定。',
				'熱唱カラオケ大会：《芸能／趣味９》で判定。',
				'アイドルコンサート：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《アイドル／背景８》で判定。',
				'スタイル自慢！：《スタイル／背景１１》で判定。',
				'ちゃんと面倒みるから！：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《生き物／趣味４》で判定。',
			]
    table.each{|i| i.gsub!(/$/, '（P222）')}
    return get_table_by_2d6(table)
  end

  # 演習イベント表
  def get_ensyuu_event_table
        table = [
				'大げんか！：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《負けず嫌い／性格６》で判定。',
				'雷撃演習：《魚雷／戦闘１０》で判定。',
				'座学の講義：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《マジメ／性格５》で判定。',
				'速力演習：《機動／航海８》で判定。',
				'救援演習：《支援／戦闘９》で判定。シーンプレイヤーのＰＣは、経験点を１０点獲得する。残念：ＰＣ全員の【行動力】が１Ｄ６点減少する。',
				'砲撃演習：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《砲撃／戦闘７》で判定。',
				'艦隊戦演習：《派手／魅力１２》で判定。',
				'整備演習：《整備／航海１２》で判定。',
				'夜戦演習：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《夜戦／戦闘１２》で判定。',
				'開発演習：《秘密兵器／背景９》で判定。',
				'防空射撃演習：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《対空戦闘／戦闘５》で判定。',
			]
    table.each{|i| i.gsub!(/$/, '（P223）')}
    return get_table_by_2d6(table)
  end
  
  # 遠征イベント表
  def get_ensei_event_table
        table = [
				'謎の深海棲艦：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《退却／戦闘８》で判定。',
				'資源輸送任務：《買い物／趣味８》で判定。',
				'強行偵察任務：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《索敵／航海４》で判定。',
				'航空機輸送作戦：《航空戦／戦闘４》で判定。',
				'タンカー護衛任務：《丁寧／性格９》で判定。',
				'海上護衛任務：提督が選んだ（キーワード）に対応した指定能力で判定。思いつかない場合は《不思議／性格２》で判定。',
				'観艦式：《おしとやか／魅力５》で判定。',
				'ボーキサイト輸送任務：《補給／航海６》で判定。',
				'社交界デビュー？：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《お嬢様／背景１０》で判定。',
				'対潜警戒任務：《対潜戦闘／戦闘１１》で判定。',
				'大規模遠征作戦、発令！：提督の選んだ（キーワード）に対応した指定能力値で判定。思いつかな場合は《指揮／航海１０》で判定。',
			]
    table.each{|i| i.gsub!(/$/, '（P224）')}
    return get_table_by_2d6(table)
  end

  # 作戦イベント表
  def get_sakusen_event_table
        table = [
				'電子の目：提督が選んだ(キーワード)に対応した指定個性で判定。思いつかない場合は《電子戦／戦闘２》で判定。',
				'直掩部隊：《航空戦／戦闘４》で判定。',
				'噂によれば：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《通信／航海３》で判定。',
				'資料室にて：《海図／航海９》で判定。',
				'守護天使：《幸運／背景７》で判定。',
				'作戦会議！：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《自由奔放／性格１１》で判定。',
				'暗号解読：《暗号／航海２》で判定。',
				'一か八か？：《楽観的／性格８》で判定。',
				'特務機関との邂逅：提督が選んだ（キーワード）に対応した指定個性で判定。思いつかない場合は《人脈／背景２》で判定。',
				'クイーンズ・ギャンビット：《いじわる／性格１０》で判定。',
				'知彼知己者、百戦不殆：《読書／趣味５》で判定。',

			]
    table.each{|i| i.gsub!(/$/, '（P225）')}
    return get_table_by_2d6(table)
  end
  
  def get_develop_table
    table = [
        '装備１種表（WP1T）',
        '装備１種表（WP1T）',
        '装備２種表（WP2T）',
        '装備２種表（WP2T）',
        '装備３種表（WP3T）',
        '装備４種表（WP4T）',
            ]
    return get_table_by_1d6(table)
  end
  
  def get_develop_matome_table
    output1 = '1'
    output2 = '2'
    total_n1 = ""
    total_n2 = ""

    dice, diceText = roll(1, 6)

	case dice
		when 1
			output1 = '装備１種表'
			output2, total_n2 =  get_weapon1_table
		when 2
			output1 = '装備１種表'
			output2, total_n2 =  get_weapon1_table
		when 3
			output1 = '装備２種表'
			output2, total_n2 =  get_weapon2_table
		when 4
			output1 = '装備２種表'
			output2, total_n2 =  get_weapon2_table
		when 5
			output1 = '装備３種表'
			output2, total_n2 =  get_weapon3_table
		when 6
			output1 = '装備４種表'
			output2, total_n2 =  get_weapon4_table
	end
    result = "#{output1}：#{output2}"
    number = "#{dice},#{total_n2}"
	return result, number
  end

  def get_weapon1_table
    table = [
        '小口径主砲（P249）',
        '１０ｃｍ連装高角砲（P249）',
        '中口径主砲（P249）',
        '１５．２ｃｍ連装砲（P249）',
        '２０．３ｃｍ連装砲（P249）',
        '魚雷（P252）',
            ]
    return get_table_by_1d6(table)
  end

  def get_weapon2_table
    table = [
        '副砲（P250）',
        '８ｃｍ高角砲（P250）',
        '大口径主砲（P249）',
        '４１ｃｍ連装砲（P250）',
        '４６ｃｍ三連装砲（P250）',
        '機銃（P252）',
            ]
    return get_table_by_1d6(table)
  end

  def get_weapon3_table
    table = [
        '艦上爆撃機（P250）',
        '艦上攻撃機（P251）',
        '艦上戦闘機（P251）',
        '偵察機（P251）',
        '電探（P252）',
        '２５ｍｍ連装機銃（P252）',
            ]
    return get_table_by_1d6(table)
  end

  def get_weapon4_table
    table = [
        '彗星（P250）',
        '天山（P251）',
        '零式艦戦５２型（P251）',
        '彩雲（P251）',
        '６１ｃｍ四連装（酸素）魚雷（P252）',
        '改良型艦本式タービン（P252）',
            ]
    return get_table_by_1d6(table)
  end
  
  def get_item_table
    table = [
        'アイス',
        '羊羹',
        '開発資材',
        '高速修復剤',
        '応急修理要員',
        '思い出の品',
            ]
    table.each{|i| i.gsub!(/$/, '（P241）')}
    return get_table_by_1d6(table)
  end

  def get_mokuhyou_table
    table = [
        '敵艦の中で、もっとも航行序列の高いＰＣ',
        '敵艦の中で、もっとも損傷の多いＰＣ',
        '敵艦の中で、もっとも【装甲力】の低いＰＣ',
        '敵艦の中で、もっとも【回避力】の低いＰＣ',
        '敵艦の中で、もっとも【火力】の高いＰＣ',
        '敵艦の中から完全にランダムに決定',
            ]
    return get_table_by_1d6(table)
  end

  def get_senka_table
    table = [
        '燃料／１Ｄ６＋[敵艦隊の人数]個',
        '弾薬／１Ｄ６＋[敵艦隊の人数]個',
        '鋼材／１Ｄ６＋[敵艦隊の人数]個',
        'ボーキサイト／１Ｄ６＋[敵艦隊の人数]個',
        '任意の資材／１Ｄ６＋[敵艦隊の人数]個',
        '感情値／各自好きなキャラクターへの【感情値】＋１',
            ]
    return get_table_by_1d6(table)
  end

  def get_kosei_table
    output1 = '1'
    output2 = '2'
    total_n1 = ""
    total_n2 = ""

    output1, total_n1 = get_bunya_table

	case total_n1
		when 1
			output2, total_n2 =  get_kosei_haikei_table
		when 2
			output2, total_n2 =  get_kosei_miryoku_table
		when 3
			output2, total_n2 =  get_kosei_seikaku_table
		when 4
			output2, total_n2 =  get_kosei_syumi_table
		when 5
			output2, total_n2 =  get_kosei_koukai_table
		when 6
			output2, total_n2 =  get_kosei_sentou_table
	end
    result = "《#{output2}／#{output1}#{total_n2}》"
    number = "#{total_n1},#{total_n2}"
	return result, number
  end

  def get_bunya_table
    table = [
        '背景',
        '魅力',
        '性格',
        '趣味',
        '航海',
        '戦闘',
            ]
    return get_table_by_1d6(table)
  end

  def get_kosei_haikei_table
    table = [
        '人脈',
        '名声',
        '暗い過去',
        '古風',
        '口ぐせ',
        '幸運',
        'アイドル',
        '秘密兵器',
        'お嬢様',
        'スタイル',
        '外国暮らし',
            ]
    return get_table_by_2d6(table)
  end
  
  def get_kosei_miryoku_table
    table = [
        '素直',
        'クール',
        '優しい',
        'おしとやか',
        'けなげ',
        '笑顔',
        'ばか',
        'さわやか',
        '面白い',
        'えっち',
        '派手',
            ]
    return get_table_by_2d6(table)
  end

  def get_kosei_seikaku_table
    table = [
        '不思議',
        'おおらか',
        '面倒見',
        'マジメ',
        '負けず嫌い',
        '元気',
        '楽観的',
        '丁寧',
        'いじわる',
        '自由奔放',
        '大胆',
            ]
    return get_table_by_2d6(table)
  end

  def get_kosei_syumi_table
    table = [
        '寝る',
        '空想',
        '生き物',
        '読書',
        '食べ物',
        'おしゃべり',
        '買い物',
        '芸能',
        'おしゃれ',
        '入浴',
        '恋愛',
            ]
    return get_table_by_2d6(table)
  end

  def get_kosei_koukai_table
    table = [
        '暗号',
        '通信',
        '索敵',
        '規律',
        '補給',
        '待機',
        '機動',
        '海図',
        '指揮',
        '衛生',
        '整備',
            ]
    return get_table_by_2d6(table)
  end

  def get_kosei_sentou_table
    table = [
        '電子戦',
        '航空打撃戦',
        '航空戦',
        '対空戦闘',
        '突撃',
        '砲撃',
        '退却',
        '支援',
        '魚雷',
        '対潜戦闘',
        '夜戦',
            ]
    return get_table_by_2d6(table)
  end


  def get_senzyou_table
    table = [
		'同航戦',
		'反航戦',
		'Ｔ字有利',
		'Ｔ字不利',
		'悪天候',
		'悪海象（あくかいしょう）',
            ]
    table.each{|i| i.gsub!(/$/, '（P231）')}
    return get_table_by_1d6(table)
  end

end
