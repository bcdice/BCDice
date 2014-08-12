#--*-coding:utf-8-*--

class LogHorizon < DiceBot
  
  def initialize
    super
    @d66Type = 1;
  end
  
  def prefixs
    ['\d+LH.*', 'PCT.*', 'ECT.*', 'GCT.*', 'CCT.*', 'CTRS.*', 'MTRS.*', 'ITRS.*', 'PTAG']
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
　xD6の判定。クリティカル、ファンブルの自動判定を行います。
　x：xに振るダイス数を入力。
　±y：yに修正値を入力。±の計算に対応。省略可能。
  >=z：zに目標値を入力。±の計算に対応。省略可能。
　例） 3LH　2LH>=8　3LH+1>=10
・各種表
・消耗表(tCTx±y)
　PCT 体力消耗表／ECT 気力消耗表／GCT 物品消耗表／CCT 金銭消耗表
　x:xにCRを入力。CR11以上の場合はCR6-10の表を参照します。
　±y:yに修正値を入力。±の計算に対応。省略可能。
　例） PCT1　ECT2+1　GCT3-1
・財宝表(tTRSx±y)
　CTRS 金銭財宝表／MTRS 魔法素材財宝表／ITRS 換金アイテム財宝表
　x：xにCRを入力。
　±y：yに修正値を入力。±の計算に対応。省略可能。
　達成値が87を超えた場合は87に補正されます。
　例） CTRS1　MTRS2+1　ITRS3-1
・パーソナリティタグ表(PTAG)
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
	
	#財宝表
	result = getTresureResult( command )
    return result unless( result.nil? )
	
	#パーソナリティタグ表
	result = getPersonalityTagResult(command)
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
    
    return nil unless(/(P|E|G|C)CT(\d+)([\+\-\d]*)?/ === command)
    
    type = $1
    rank = $2.to_i
	modifyText = $3
    modify  = getValue(modifyText, 0)
	
    tableName = ""
    tables = nil
    
    case type
    when "P"
      tableName, tables = getPhysicalConsumptionResult()
    when "E"
      tableName, tables = getEnergyConsumptionResult()
    when "G"
      tableName, tables = getGoodsConsumptionResult()
    when "C"
      tableName, tables = getCashConsumptionResult()
    else
      return nil
	end
    
    table = getTableByRank(rank, tables)
	
	number, dice_str = roll(1, 6)
	number += modify
    
    adjustedNumber = getAdjustNumber(number, table)
    
	result = get_table_by_number(adjustedNumber, table)
	
	text = "#{tableName}(#{number}[#{dice_str}])：#{result}"
    return text
  end
  
  
  def getPhysicalConsumptionResult()
    tableName = "体力消耗表"
    tables = [[
                 [0, '消耗なし'],
                 [1, '[疲労:5]を受ける'],
                 [2, '[疲労:8]を受ける'],
                 [3, '[疲労:10]を受ける'],
                 [4, '[疲労:13]を受ける'],
                 [5, '[疲労:15]を受ける'],
                 [6, '[疲労:18]を受ける'],
                 [7, '[疲労:20]を受ける'],
                ],
                [
                 [0, '消耗なし'],
                 [1, '[疲労:10]を受ける'],
                 [2, '[疲労:15]を受ける'],
                 [3, '[疲労:20]を受ける'],
                 [4, '[疲労:25]を受ける'],
                 [5, '[疲労:30]を受ける'],
                 [6, '[疲労:35]を受ける'],
                 [7, '[疲労:40]を受ける'],
                ],
               ]
    
    return tableName, tables
  end


  def getEnergyConsumptionResult()
    tableName = "気力消耗表"
    tables = [[
                 [0, '消耗なし'],
                 [1, '【因果力】を1点失う'],
                 [2, '【因果力】を1点失う'],
                 [3, '【因果力】を1点失う'],
                 [4, '【因果力】を1点失う'],
                 [5, '【因果力】を2点失う'],
                 [6, '【因果力】を2点失う'],
                 [7, '【因果力】を2点失う'],
                ],
                [
                 [0, '消耗なし'],
                 [1, '【因果力】を1点失う'],
                 [2, '【因果力】を1点失う'],
                 [3, '【因果力】を1点失う'],
                 [4, '【因果力】を2点失う'],
                 [5, '【因果力】を2点失う'],
                 [6, '【因果力】を2点失う'],
                 [7, '【因果力】を3点失う'],
                ],
               ]
    
    return tableName, tables
  end
  
  def getGoodsConsumptionResult()
    tableName = "物品消耗表"
    tables = [[
                 [0, '消耗なし'],
                 [1, '[消耗品]アイテムを1個失う'],
                 [2, '[消耗品]アイテムを1個失う'],
                 [3, '[消耗品]アイテムを1個失う'],
                 [4, '[消耗品]アイテムを2個失う'],
                 [5, '[消耗品]アイテムを2個失う'],
                 [6, '[消耗品]アイテムを2個失う'],
                 [7, '[消耗品]アイテムを2個失う'],
                ],
                [
                 [0, '消耗なし'],
                 [1, '[消耗品]アイテムを1個失う'],
                 [2, '[消耗品]アイテムを1個失う'],
                 [3, '[消耗品]アイテムを2個失う'],
                 [4, '[消耗品]アイテムを2個失う'],
                 [5, '[消耗品]アイテムを3個失う'],
                 [6, '[消耗品]アイテムを3個失う'],
                 [7, '[消耗品]アイテムを4個失う'],
                ],
               ]
    
    return tableName, tables
  end
  
  def getCashConsumptionResult()
    tableName = "金銭消耗表"
    tables = [[
                 [0, '消耗なし'],
                 [1, '所持金を10G失う'],
                 [2, '所持金を15G失う'],
                 [3, '所持金を20G失う'],
                 [4, '所持金を25G失う'],
                 [5, '所持金を30G失う'],
                 [6, '所持金を35G失う'],
                 [7, '所持金を40G失う'],
                ],
                [
                 [0, '消耗なし'],
                 [1, '所持金を25G失う'],
                 [2, '所持金を35G失う'],
                 [3, '所持金を50G失う'],
                 [4, '所持金を60G失う'],
                 [5, '所持金を75G失う'],
                 [6, '所持金を90G失う'],
                 [7, '所持金を100G失う'],
                ],
               ]
    
    return tableName, tables
  end
  
  
  def getTableByRank(rank, tables)
	index = (rank - 1) / 5
    
	index = [0, index].max
	index = [index, (tables.size - 1)].min
    
    return tables[index]    
  end
  
  
  def getAdjustNumber(number, table)
    number = getAdjustNumberMin(number, table)
    number = getAdjustNumberMax(number, table)
    return number
  end
  
  #最少値の調整（値が小さすぎるなら表の最小値に）
  def getAdjustNumberMin(number, table)
    value = table.first.first
    return [number, value].max
  end
  
  #最大値の調整（値が大きすぎるなら表の最大値に）
  def getAdjustNumberMax(number, table)
    value = table.last.first
    return [number, value].min
  end
  
  
  
  #財宝表
  def getTresureResult(command)
    
    return nil unless(/(C|M|I)TRS(\d+)([\+\-\d]*)/ === command)
    
	type = $1
	rank = $2.to_i
	modifyText = $3
	modify  = getValue(modifyText, 0)
	
    tableName = ""
    table = []
	
	case type
    when "C"
	  tableName, table = getCashTresureResultTable
    when "M"
	  tableName, table = getMagicTresureResultTable
    when "I"
	  tableName, table = getItemTresureResultTable
    else
      return nil
	end
	
	number, dice_str = roll(2, 6)
	number += (rank * 5) + modify
    
    number = getAdjustNumberMin(number, table)
    number = [number, 87].min
    
    case number
      
    when 63 .. 72
      result  = get_table_by_number(number - 10, table)
      result += '&80G'
      
    when 73 .. 82
      result  = get_table_by_number(number - 20, table)
      result += '&160G'
      
    when 83 .. 87
      result  = get_table_by_number(number - 30, table)
      result += '&260G'
      
	else
	  result  = get_table_by_number(number, table)
	end
	
	text = "#{tableName}(#{number}[#{dice_str}])：#{result}"
    return text
  end
  
  
  def getCashTresureResultTable
    tableName = "金銭財宝表"
      table = [
               [ 7, '39G'],
               [ 8, '40G'],
               [ 9, '42G'],
               [10, '43G'],
               [11, '45G'],
               [12, '46G'],
               [13, '48G'],
               [14, '50G'],
               [15, '52G'],
               [16, '54G'],
               [17, '57G'],
               [18, '59G'],
               [19, '61G'],
               [20, '64G'],
               [21, '67G'],
               [22, '70G'],
               [23, '72G'],
               [24, '75G'],
               [25, '79G'],
               [26, '82G'],
               [27, '85G'],
               [28, '89G'],
               [29, '92G'],
               [30, '96G'],
               [31, '100G'],
               [32, '104G'],
               [33, '108G'],
               [34, '112G'],
               [35, '117G'],
               [36, '121G'],
               [37, '126G'],
               [38, '130G'],
               [39, '135G'],
               [40, '140G'],
               [41, '145G'],
               [42, '150G'],
               [43, '155G'],
               [44, '161G'],
               [45, '166G'],
               [46, '172G'],
               [47, '178G'],
               [48, '183G'],
               [49, '189G'],
               [50, '195G'],
               [51, '201G'],
               [52, '208G'],
               [53, '214G'],
               [54, '221G'],
               [55, '227G'],
               [56, '234G'],
               [57, '241G'],
               [58, '248G'],
               [59, '255G'],
               [60, '262G'],
               [61, '269G'],
               [62, '277G'],
              ]
    
    return tableName, table
  end
  
  def getMagicTresureResultTable
      tableName = "魔法素材財宝表"
      table = [
               [ 7, '魔触媒2[魔触媒2](20G)x2'],
               [ 8, '魔触媒2[魔触媒2](20G)x2'],
               [ 9, '魔触媒1[魔触媒1](15G)x3'],
               [10, '魔触媒1[魔触媒1](15G)x3'],
               [11, '魔触媒1[魔触媒1](15G)x3'],
               [12, '腐銀の小片[コア素材](30G)&鉱石のサンプル[換金](15G)'],
               [13, '新緑の若芽[コア素材](30G)&小さな花の種[換金](20G)'],
               [14, '命の葉[コア素材](40G)&強靭なツタ[換金](10G)'],
               [15, '鋭い牙[コア素材](40G)&使い込まれたナイフ[換金](10G)'],
               [16, '魔触媒3[魔触媒3](25G)x2'],
               [17, '古びた髑髏[コア素材](40G)&黒い詩集[換金](15G)'],
               [18, '黒睡蓮の花弁[コア素材](40G)&水キセル[換金](20G)'],
               [19, '純白の羽根[コア素材](40G)&小さなゴーグル[換金](20G)'],
               [20, '真紅の爪[コア素材](50G)&小さな鏡[換金](15G)'],
               [21, '赤熱の小爪[コア素材](50G)&細工物の暖炉[換金](20G)'],
               [22, '自戒の茨[コア素材](50G)&焦げた竜革[換金](20G)'],
               [23, '流星のかけら[コア素材](50G)&質素な指輪[換金](10G)x2'],
               [24, '聖なる繊維[コア素材](50G)&傷ついたメダル[換金](25G)'],
               [25, '折れたシャフト[コア素材](60G)&ガラクタの山[換金](5G)x4'],
               [26, '巨人の髭[コア素材](50G)&小さな櫛[換金](20G)'],
               [27, '精密な歯車[コア素材](60G)&工具鋼の破片[換金](25G)'],
               [28, 'とがった爪[コア素材](60G)&刺繍の飾り帯[換金](30G)'],
               [29, '触媒のフラスコ[コア素材](60G)&小さな肖像画[換金](30G)'],
               [30, '液化魔晶[コア素材](60G)&精密な人形[換金](35G)'],
               [31, '魔触媒5[魔触媒5](40G)&魔触媒4[魔触媒4](30G)x2'],
               [32, 'やわらかい石[コア素材](80G)&小型の蒸留器[換金](20G)'],
               [33, '謎めいた毛皮[コア素材](80G)&奇妙な頭骨[換金](30G)'],
               [34, '星屑の銀糸[コア素材](80G)&錫引きの星見盤[換金](30G)'],
               [35, '魔触媒5[魔触媒5](40G)x3'],
               [36, '小型錬成陣[コア素材](100G)&奇妙なオブジェ[換金](20G)'],
               [37, '魔触媒6[魔触媒6](50G)&魔触媒5[魔触媒5](40G)x2'],
               [38, '呪紋の種[コア素材](100G)&砕けた宝石[換金](30G)'],
               [39, '銀の円環[コア素材](100G)&純白のコサージュ[換金](30G)'],
               [40, '常眠りの種子[コア素材](100G)&庭師の飾り紐[換金](40G)'],
               [41, '飴色の粘液[コア素材](1210G)&極彩色の粒[換金](5G)x5'],
               [42, '魔触媒6[魔触媒6](50G)x3'],
               [43, '銀色の甲殻[コア素材](120G)&乏しいつぼみ[換金](10G)x4'],
               [44, '魔触媒7[魔触媒7](60G)&魔触媒6[魔触媒6](50G)x2'],
               [45, '大きな魔力結晶[コア素材](120G)&妖精のラクガキ[換金](40G)'],
               [46, '拳士の魄片[コア素材](140G)&白紙の巻物[換金](40G)'],
               [47, '魔触媒7[魔触媒7](60G)x3'],
               [48, '蒼い鉱石[コア素材](140G)&天然ガラスの塊[換金](25G)x2'],
               [49, '巨大な風切り羽[コア素材](140G)&分厚い卵殻[換金](50G)'],
               [50, '魔触媒8[魔触媒8](70G)x2&魔触媒7[魔触媒7](60G)'],
               [51, '絶えない火種[コア素材](180G)&漆黒のスス[換金](20G)'],
               [52, '魔触媒8[魔触媒8](70G)x3'],
               [53, '魔導錠[コア素材](180G)&つくりかけの錠前[換金](10G)x3'],
               [54, '七色の透明捻子[コア素材](180G)&開かない細工箱[換金](40G)'],
               [55, '偏属性魔法結晶[コア素材](220G)&レポートの束[換金](10G)'],
               [56, '魔触媒9[魔触媒9](90G)&魔触媒8[魔触媒8](70G)x2'],
               [57, '魔触媒9[魔触媒9](90G)&魔触媒8[魔触媒8](70G)x2'],
               [58, '派手な羽根飾り[コア素材](220G)&空想動物図鑑[換金](30G)'],
               [59, '砂のバラ[コア素材](220G)&棘のような水晶[換金](10G)x5'],
               [60, '魔触媒9[魔触媒9](90G)x3'],
               [61, '頑丈な胃袋[コア素材](220G)&奇妙な標本[換金](50G)'],
               [62, '魔触媒10[魔触媒10](110G)&魔触媒9[魔触媒9](90G)x2'],
              ]
    
    return tableName, table
  end
  
  def getItemTresureResultTable
      tableName = "換金アイテム財宝表"
      table = [
               [ 7, '陶器の絵付きマグカップ[換金](40G)'],
               [ 8, '木製の騎士像[換金](40G)'],
               [ 9, '小さな風景画[換金](50G)'],
               [10, '奇妙な抽象画[換金](50G)'],
               [11, '夜会の仮面[換金](50G)'],
               [12, '錫の食器セット[換金](50G)'],
               [13, '古い詩集[換金](50G)'],
               [14, '鮮やかな刺繍のハンカチ[換金](50G)'],
               [15, '陶器の大皿[換金](60G)'],
               [16, '絵巻物[換金](60G)'],
               [17, '陶器の水盤[換金](60G)'],
               [18, '細工物のイヤリング[換金](60G)'],
               [19, '淑女の肖像画[換金](70G)'],
               [20, '小さな宝石箱[換金](70G)'],
               [21, '真鍮の燭台[換金](70G)'],
               [22, '貴族の古い日記[換金](70G)'],
               [23, '騎士の肖像画[換金](80G)'],
               [24, '塗り下駄[換金](80G)'],
               [25, '精緻なゲーム盤[換金](80G)'],
               [26, '精緻な静物画[換金](90G)'],
               [27, '樫の椅子[換金](90G)'],
               [28, '古いビスクドール[換金](90G)'],
               [29, 'きらびやかな仮面[換金](100G)'],
               [30, 'ウサギのぬいぐるみ[換金](100G)'],
               [31, '真鍮の子鬼像[換金](100G)'],
               [32, '地方の歴史書[換金](110G)'],
               [33, '夜会の手袋[換金](110G)'],
               [34, 'ハイヒール[換金](120G)'],
               [35, 'おとぎ話の本[換金](120G)'],
               [36, '少女の肖像画[換金](130G)'],
               [37, '小さなコケシ[換金](130G)'],
               [38, '藤の椅子[換金](130G)'],
               [39, 'イヌとネコのパペット[換金](140G)'],
               [40, '掛け軸[換金](G140)'],
               [41, 'クマのぬいぐるみ[換金](150G)'],
               [42, 'ネコのかぶりもの[換金](150G)'],
               [43, '学術書[換金](160G)'],
               [44, 'タカの剥製[換金](170G)'],
               [45, '大理石の賢者像[換金](170G)'],
               [46, '刺繍をあしらったクッション[換金](180G)'],
               [47, 'イヌのかぶりもの[換金](180G)'],
               [48, '樫の大テーブル[換金](190G)'],
               [49, '彫金の指輪[換金](190G)'],
               [50, '花鳥画の掛け軸[換金](200G)'],
               [51, '最上質の毛布[換金](210G)'],
               [52, '上質の白粉[換金](210G)'],
               [53, '磁器の茶器[換金](220G)'],
               [54, '簡素なティアラ[換金](230G)'],
               [55, '彫金のイヤリング[換金](230G)'],
               [56, '豪華なネックレス[換金](240G)'],
               [57, '上質の香水[換金](250G)'],
               [58, '山水画の掛け軸[換金](250G)'],
               [59, '手の込んだドレス/礼服[換金](260G)'],
               [60, '陶器の絵皿[換金](270G)'],
               [61, 'キツネのぬいぐるみ[換金](270G)'],
               [62, '古い歴史書[換金](280G)'],
              ]
    
    return tableName, table
  end
  
  
  
  #パーソナリティタグ表
  def getPersonalityTagResult(command)
    return nil unless("PTAG" === command)
	tableName = "パーソナリティタグ表"
	
	table = [
	         '[おませさん]',
	         '[好奇心旺盛]',
	         '[寂しがりや]',
	         '[生真面目]',
	         '[食いしん坊]',
	         '[やんちゃ]または[おてんば]',
			 
	         '[お人よし]',
	         '[情熱家]',
	         '[世話好き]',
	         '[理知的]',
	         '[頑固者]',
	         '[兄貴肌]または[姉御肌]',
			 
	         '[義理堅い]',
	         '[気まぐれ]',
	         '[職人気質]',
	         '[熱血漢]',
	         '[努力家]',
	         '[男好き]または[女好き]',
			 
	         '[家庭的]',
	         '[負けず嫌い]',
	         '[純真]',
	         '[朴念仁]',
	         '[慈悲深い]',
	         '[マイペース]',
			 
	         '[楽天家]',
	         '[仲間思い]',
	         '[誇り高い]',
	         '[社交的]',
	         '[冷静沈着]',
	         '[ロマンチスト]',
			 
	         '[学者肌]',
	         '[内向的]',
	         '[苦労人]',
	         '[派手好き]',
	         '[勇猛果敢]',
	         '[ミステリアス]',
	        ]
	
	result, number = get_table_by_d66(table)
	
	text = "#{tableName}(#{number})：#{result}"
    return text
  end
  
end
