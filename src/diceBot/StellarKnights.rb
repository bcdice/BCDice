# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "utils/table"
require "utils/d66_grid_table"

class StellarKnights < DiceBot
  # ゲームシステムの識別子
  ID = 'StellarKnights'

  # ゲームシステム名
  NAME = '銀剣のステラナイツ'

  # ゲームシステム名の読みがな
  SORT_KEY = 'きんけんのすてらないつ'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
・判定　nSK[d][,k>l,...]
[]内は省略可能。
n: ダイス数、d: アタック判定における対象の防御力、k, l: ダイスの出目がkならばlに変更（アマランサスのスキル「始まりの部屋」用）
d省略時はダイスを振った結果のみ表示。（nSKはnB6と同じ）

4SK: ダイスを4個振って、その結果を表示
5SK3: 【アタック判定：5ダイス】、対象の防御力を3として成功数を表示
3SK,1>6: ダイスを3個振り、出目が1のダイスを全て6に変更し、その結果を表示
6SK4,1>6,2>6: 【アタック判定：6ダイス】、出目が1と2のダイスを全て6に変更、対象の防御力を4として成功数を表示

・基本
TT：お題表
STA ：シチュエーション表A：時間 (Situation Table A)
STB ：シチュエーション表B：場所 (ST B)
STB2：シチュエーション表B その2：学園編 (ST B 2)
STC ：シチュエーション表C：話題 (ST C)
ALLS ：シチュエーション表全てを一括で（学園編除く）
GAT：所属組織決定 (Gakuen Table)
HOT：希望表 (Hope Table)
DET：絶望表 (Despair Table)
WIT：願い事表 (Wish Table)
YST：あなたの物語表 (Your Story Table)
YSTA：あなたの物語表：異世界 (YST Another World)
PET：性格表 (Personality Table)
    性格表を2回振り、性格を決定する

・霧と桜のマルジナリア
YSTM：あなたの物語表：マルジナリア世界 (YST Marginalia)
STM：シチュエーション表：マルジナリア世界 (ST Marginalia)
YSTL：あなたの物語表：手紙世界 (YST Letter)
YSTR：あなたの物語表：リコレクト・ドール (YST Recollect-doll)
STBR：シチュエーション表B：場所（リコレクト・ドール） (ST B Recollect-doll)
STCR：シチュエーション表C：リコレクト (ST C Recollect)
STBS：シチュエーション表B：シトラセッティング (ST B Sut Tu Real)
STE：シチュエーション表：エクリプス専用 (ST Eclipse)

・紫弾のオルトリヴート
FT：フラグメント表 (Fragment Table)
    フラグメント表を５回振る
FTx：フラグメント表をx回振る
YSTB：あなたの物語表：ブリンガー (YST Bringer)
YSTF：あなたの物語表：フォージ (YST Forge)
STAL：シチュエーション表：オルトリヴート (ST Alt-Levoot)
MESSAGETEXT

  def initialize
    super

    @sortType = 2 # バラバラロール（Bコマンド）でソート有
    @d66Type = 1
  end

  def rollDiceCommand(command)
    command = command.upcase

    if (table = TABLES[command])
      return table.roll(bcdice)
    elsif (m = /(\d+)SK(\d)?((,\d>\d)+)?/.match(command))
      return resolute_action(m[1].to_i, m[2] && m[2].to_i, m[3], command)
    elsif command == "PET"
      return roll_personality_table()
    elsif (m = /FT(\d+)?/.match(command))
      num = (m[1] || 5).to_i
      return roll_fragment_table(num)
    end

    return analyzeDiceCommandResultMethod(command)
  end

  def getThemeTableDiceCommandResult(command)
    return unless command == "TT"

    tableName = "お題表"
    table = %w{
      未来 占い 遠雷 恋心 歯磨き 鏡
      過去 キス ささやき声 黒い感情 だっこ 青空
      童話 決意 風の音 愛情 寝顔 鎖
      ふたりの秘密 アクシデント！ 小鳥の鳴き声 笑顔 食事 宝石
      思い出 うとうと 鼓動 嫉妬 ベッド 泥
      恋の話 デート ため息 内緒話 お風呂 小さな傷
    }

    text, index = get_table_by_d66(table)

    result = "#{tableName}(#{index}) ＞ #{text}"
    return result
  end

  def getSituationTableDiceCommandResult(command)
    return unless command == "STA"

    tableName = "シチュエーション表A：時間"
    table = %w{
      朝、誰もいない
      騒がしい昼間の
      寂しい夕暮れの横たわる
      星の瞬く夜、
      静謐の夜更けに包まれた
      夜明け前の
    }
    text, index = get_table_by_1d6(table)

    result = "#{tableName}(#{index}) ＞ #{text}"
    return result
  end

  def getPlageTableDiceCommandResult(command)
    return unless command == "STB"

    tableName = "シチュエーション表B：場所"

    table_1_2 = [
      "教室 　小道具：窓、机、筆記用具、チョークと黒板、窓の外から聞こえる部活動の声",
      "カフェテラス　小道具：珈琲、紅茶、お砂糖とミルク、こちらに手を振っている学友",
      "学園の中庭　小道具：花壇、鳥籠めいたエクステリア、微かに聴こえる鳥の囁き",
      "音楽室　小道具：楽器、楽譜、足踏みオルガン、壁に掛けられた音楽家の肖像画",
      "図書館　小道具：高い天井、天井に迫る程の本棚、無数に収められた本",
      "渡り廊下　小道具：空に届きそうな高さ、遠くに別の学園が見える、隣を飛び過ぎて行く鳥",
    ]

    table_3_4 = [
      "花の咲き誇る温室　小道具：むせ返るような花の香り、咲き誇る花々、ガラス越しの陽光",
      "アンティークショップ　小道具：アクセサリーから置物まで、見慣れない古い機械は地球時代のもの？",
      "ショッピングモール　小道具：西欧の街並みを思わせるショッピングモール、衣類に食事、お茶屋さんも",
      "モノレール　小道具：車窓から覗くアーセルトレイの街並み、乗客はあなたたちだけ",
      "遊歩道　小道具：等間隔に並ぶ街路樹、レンガ造りの街並み、微かに小鳥のさえずり",
      "おしゃれなレストラン　小道具：おいしいごはん、おしゃれな雰囲気、ゆったりと流れる時間",
    ]
    table_5_6 = [
      "何処ともしれない暗がり　小道具：薄暗がりの中、微かに見えるのは互いの表情くらい",
      "寂れた喫茶店　小道具：姿を見せないマスター、その孫娘が持ってくる珈琲、静かなひととき",
      "階段の下、秘密のお茶会　小道具：知る人ぞ知る階段下スペースのお茶会、今日はあなたたちだけ",
      "学生寮の廊下　小道具：滅多に人とすれ違わない学生寮の廊下、窓の外には中庭が見える",
      "ふたりの部屋　小道具：パートナーと共に暮らすあなたの部屋、内装や小物はお気に召すまま",
      "願いの決闘場　小道具：決闘の場、ステラナイトたちの花章が咲き誇る場所",
    ]

    table = [table_1_2, table_1_2,
             table_3_4, table_3_4,
             table_5_6, table_5_6,].flatten

    text, index = get_table_by_d66(table)

    result = "#{tableName}(#{index}) ＞ #{text}"
    return result
  end

  def getSchoolTableDiceCommandResult(command)
    return unless command == "STB2"

    tables =
      [
        {:tableName => "アーセルトレイ公立大学",
         :table => %w{
           地下のだだっぴろい学食
           パンの種類が豊富な購買の前
           本当は進入禁止の屋上
           キャンプ部が手入れしている中庭
           共用の広いグラウンド
           使い古された教室
         }},

        {:tableName => "イデアグロリア芸術総合大学",
         :table => %w{
           （美術ｏｒ音楽）準備室
           美しく整備された中庭
           音楽室
           格調高いカフェテラス
           誰もいない大型劇場
           完璧な調和を感じる温室
         }},

        {:tableName => "シトラ女学院",
         :table => %w{
           中庭の神殿めいた温室
           質素だが美しい会食室
           天井まで届く本棚の並ぶ図書館
           誰もいない学習室
           寮生たちの秘密のお茶会室
           寮の廊下
         }},

        {:tableName => "フィロソフィア大学",
         :table => %w{
           遠く聞こえる爆発音
           学生のアンケート調査を受ける
           空から降ってくるドローン
           膨大な蔵書を備えた閉架書庫
           鳴らすと留年するという小さな鐘の前
           木漏れ日のあたたかな森
         }},

        {:tableName => "聖アージェティア学園",
         :table => %w{
           おしゃれなカフェテラス
           小さなプラネタリウム
           ローマの神殿めいた屋内プール
           誰もいない講堂
           謎のおしゃれな空き部屋
           花々の咲き乱れる温室
         }},

        {:tableName => "スポーン・オブ・アーセルトレイ",
         :table => %w{
           人気のない教室
           歴代の寄せ書きの刻まれた校門前
           珍しく人気のない学食
           鍵の外れっぱなしの屋上
           校舎裏
           外周環状道路へ繋がる橋
         }},
      ]

    result = ''

    tables.each_with_index do |table, i|
      tableName = table[:tableName]
      table = table[:table]

      text, index = get_table_by_1d6(table)

      result += "\n" unless i == 0
      result += "#{tableName}(#{index}) ＞ #{text}"
    end

    return result
  end

  def getTpicTableDiceCommandResult(command)
    return unless command == "STC"

    tableName = "シチュエーション表C：話題"

    table_1_3 = [
      "未来の話：決闘を勝ち抜いたら、あるいは負けてしまったら……未来のふたりはどうなるのだろう。",
      "衣服の話：冴えない服を着たりしていないか？　あるいはハイセンス過ぎたりしないだろうか。よぉし、私が選んであげよう!!",
      "ステラバトルの話：世界の未来は私たちにかかっている。頭では分かっていても、まだ感情が追いつかないな……。",
      "おいしいごはんの話：おいしいごはんは正義。１００年前も６４０５年前も異世界だろうと、きっと変わらない真理なのだ。おかわり！",
      "家族の話：生徒たちは寮生活が多い。離れて暮らす家族は、どんな人たちなのか。いつかご挨拶に行きたいと言い出したりしても良いだろう。",
      "次の週末の話：週末、何をしますか？　願いをかけた決闘の合間、日常のひとときも、きっと大切な時間に違いない。",
    ]

    table_4_6 = [
      "好きな人の話：……好きな人、いるんですか？　これはきっと真剣な話。他の何よりも重要な話だ。",
      "子供の頃の話：ちいさな頃、パートナーはどんな子供だったのだろうか。どんな遊びをしたのだろうか。",
      "好きなタイプの話：パートナーはどんな人が好みなのでしょうか……。気になります、えぇ。",
      "思い出話：ふたりの思い出、あるいは出会う前の思い出の話。",
      "願いの話：叶えたい願いがあるからこそ、ふたりは出会った。この戦いに勝利したら、どんな形で願いを叶えるのだろうか。",
      "ねぇ、あの子誰？：この前見かけたパートナーと一緒にいた子。あの子誰？だーれー!?　むー!!"
    ]

    table = [table_1_3, table_1_3, table_1_3,
             table_4_6, table_4_6, table_4_6, ].flatten

    text, index = get_table_by_d66(table)

    result = "#{tableName}(#{index}) ＞ #{text}"
    return result
  end

  def getAllSituationTableDiceCommandResult(command)
    return unless command == "ALLS"

    commands = ['STA', 'STB', 'STC']

    result = ""

    commands.each_with_index do |cmd, i|
      result += "\n" unless i == 0
      result += analyzeDiceCommandResultMethod(cmd)
    end

    return result
  end

  private

  D6 = 6

  # num_dices: Integer, defence: Integer/NilClass, dice_change_text: String/NilClass, command: String
  def resolute_action(num_dices, defence, dice_change_text, command)
    _, dice_text, _ = roll(num_dices, D6, @sortType)
    output = "(#{command}) ＞ #{dice_text}"

    dices = dice_text.split(',').map(&:to_i)
    if !dice_change_text.nil?
      dice_maps = dice_change_text[1..-1].split(',').map { |text| text.split('>').map(&:to_i) }
      dices.map! { |dice| dice_maps.inject(dice) { |dice, dice_map| dice == dice_map[0] ? dice_map[1] : dice } }.sort!
      output += " ＞ [#{dices.join(',')}]"
    end

    if !defence.nil?
      success = dices.size - dices.bsearch_index { |dice| dice >= defence }
      output += " ＞ 成功数: #{success}"
    end

    output
  end

  def roll_personality_table()
    value1, index1 = get_table_by_d66(PERSONALITY_TABLE)
    value2, index2 = get_table_by_d66(PERSONALITY_TABLE)
    return "性格表(#{index1},#{index2}) ＞ #{value1}にして#{value2}"
  end

  def roll_fragment_table(num)
    if num <= 0
      return nil
    end

    results = Array.new(num) { get_table_by_d66(FRAGMENT_TABLE) }
    values = results.map { |r| r[0] }
    indexes = results.map { |r| r[1] }

    return "フラグメント表(#{indexes.join(',')}) ＞ #{values.join(',')}"
  end

  GAKUEN_TABLE = [
    "アーセルトレイ公立大学",
    "イデアグロリア芸術総合大学",
    "シトラ女学院",
    "フィロソフィア大学",
    "聖アージェティア学園",
    "スポーン・オブ・アーセルトレイ",
  ].freeze

  HOPE_TABLE_1_2_3 = [
    "より良き世界：世界はもっとステキになる。きっと、ずっと、もっと。",
    "まだまだ物足りない：もっと上へ、もっと強く、あなたの未来は輝いている。",
    "立ち止まっている暇はない!：止まっている時間がもったいない。もっともっと世界を駆けるのだ!",
    "私が守るよ：君を傷つける全てから、私が絶対守ってあげる。",
    "未来は希望に満ちている：生きていないと、素敵なことは起きないんだ!",
    "慈愛の手：届く限り、あなたは手を差し伸べ続ける。",
  ].freeze

  HOPE_TABLE_4_5_6 = [
    "自分を犠牲にしてでも：世界はもっときらきらしているんだよ。それを伝える為に、あなたは自分すら犠牲にする。",
    "右手を伸ばす：救いたいもの、助けたいもの、大事なもの、なにひとつ見捨てるつもりはない!",
    "無限の愛：愛を注ごう。この胸に溢れんばかりのこの愛を!",
    "あなたを王に：絶望を知ったパートナーこそ、世界の王に相応しい。私があなたを王にする!",
    "救世主：私はきっと、世界を救える。誰だって、救ってみせる。",
    "大好きな人のために!：世界は希望に満ちている。あなたをもっと幸せにしたいの!",
  ].freeze

  HOPE_TABLE = [
    HOPE_TABLE_1_2_3,
    HOPE_TABLE_1_2_3,
    HOPE_TABLE_1_2_3,
    HOPE_TABLE_4_5_6,
    HOPE_TABLE_4_5_6,
    HOPE_TABLE_4_5_6,
  ].freeze

  DESPAIR_TABLE_1_2_3 = [
    "理不尽なる世界：あなたは世界が如何に理不尽であるか思い知った。",
    "この手は届かない：あなたにも目標はあった。しかし、もうこの手は届かないのだ。",
    "停滞した世界：どんなにあがこうと、世界は変わらない。この絶望は救われない。",
    "どうして僕をいじめるの：あなたは虐げられて生きてきた。守ってくれる者など、どこにもいなかった。",
    "過去は絶望に満ちている：ずっとずっと、悪いことばかり、辛いことばかりだった。",
    "周囲の視線：世界があなたを見る目は、限りなく冷たいものだった。",
  ].freeze

  DESPAIR_TABLE_4_5_6 = [
    "大事故：それは壮絶な事故、いいや、それは事故なんて優しいものですらなかった。",
    "目の前で消えたモノ：あなたの目の前で、大切なものは消えてしまった。",
    "喪失：何よりも大事にしていたものは、もう二度と、この手には戻らない。",
    "没落：あなたか、あなたの親か、ともかくあなたはかつての栄華を一瞬にして失った。",
    "救いはない：底の底へと沈んでしまった。もう、誰も、俺を救ってくれる人は……。",
    "偽物だった：あなたは幸せだった。そう思っていた。でもそれは全て作り物で、あなたは騙されていたのだ。",
  ].freeze

  DESPAIR_TABLE = [
    DESPAIR_TABLE_1_2_3,
    DESPAIR_TABLE_1_2_3,
    DESPAIR_TABLE_1_2_3,
    DESPAIR_TABLE_4_5_6,
    DESPAIR_TABLE_4_5_6,
    DESPAIR_TABLE_4_5_6,
  ].freeze

  YOUR_STORY_TABLE_1_2 = [
    "熟練ステラナイト：あなたは既に何度もステラバトルを征してきた熟練者で ある。【勲章：3~7の間の好きな値】【歪みの共鳴：1】",
    "権力者の血筋：統治政府や企業の上層部、あるいは学園組織の運営者の家系である。",
    "天才：あなたは紛うことなき天才だ。",
    "天涯孤独：あなたに両親はいない。促成培養槽で造られた者なのか、あるいは両親を失ったのか……。",
    "救いの手：あなたは誰かに助けてもらった。だから、ここにいるのだ。",
    "欠損：心や身体、大切な宝物、家族、あなたは何かを失って、そのまま今に至った。",
  ].freeze

  YOUR_STORY_TABLE_3_4 = [
    "大切なもの：大事にしているものがある。",
    "お気に入りの場所：好きな場所がある。秘密の場所、あるいは誰かと来たい場所。",
    "メイド or バトラー：あなたには仕えるべき相手がいる。金銭の関係か、家柄か、恩義故かは自由に決めて良い。",
    "パートナー大好き!!!!!!：私はー!! パートナーがー!! 大好きだー!!!",
    "目指せ理想のタイプ：パートナーの理想のタイプ目指してー、ファイトー!!",
    "世界への不満：こんな世界はダメダメだ! 私が絶対に創り変えてやる!!",
  ].freeze

  YOUR_STORY_TABLE_5_6 = [
    "停滞：何もかもがつまらない。満たされない。動かない世界に嫌気が差している。",
    "願いの奴隷：願いを叶える為なら、手段は選ばない。願いの為だけに私は生きている。",
    "犯罪者の子：あなたの親は何らかの犯罪に手を染めた。その悪評は、子である君にも影響を及ぼしている。",
    "探求者：世界の真実、隠された真実、万物の真理……あなたが追い求めるものはどこまでも尽きない。",
    "正義：困った人を見捨てられない、悪は許せない、この胸に宿るのは正義の心。",
    "誓約生徒会(カヴェナンター)：あなたは一度、エクリプスと化し、討伐された者だ。しかし願いを諦めることは出来ない。だから、あなたはこの仮面を受け取り、戦い続けているのだ。【勲章：0~5の間の好きな値】【歪みの共鳴：0~2の間の好きな値】",
  ].freeze

  YOUR_STORY_TABLE = [
    YOUR_STORY_TABLE_1_2,
    YOUR_STORY_TABLE_1_2,
    YOUR_STORY_TABLE_3_4,
    YOUR_STORY_TABLE_3_4,
    YOUR_STORY_TABLE_5_6,
    YOUR_STORY_TABLE_5_6,
  ].freeze

  YOUR_STORY_TABLE_ANOTHER_WORLD_1_2 = [
    "終わりなき戦場：あなたは果ての見えない戦場の世界からここへ流れ着いた。",
    "滅びの世界：戦争、あるいは環境汚染か、滅びた後の世界から、あなたはここへ流れ着いた。",
    "獣人たちの世界：人とは、獣の特徴を備えた者を指す言葉だった――あなたの世界では。あなたは獣の特徴を備えており、それはアーセルトレイでは奇異の目で見られることだろう。",
    "箱庭の世界：都市か、屋敷か、あなたの住んでいた世界は極狭いものだった。大好きな姉妹や家族と、ただ平穏に暮らすだけの日々。永遠に続くと思っていたそれは、ある日突然に崩壊して、あなたはこの世界へと辿り着いた。",
    "永遠なる迷宮の世界：無限に広がる迷宮の世界、人々はそこを旅する探索者だった。旧世界の遺産とも称される星まるごとが迷宮の世界、心躍る冒険――そんな日々は、ある日突然に終わってしまった。あなたが辿り着いたのは、アーセルトレイと呼ばれるこの場所だった。",
    "巡礼者の世界：広大な自然と石造りの都の世界を、誰もが旅をし続ける世界からあなたはここへ流れ着いた。アーセルトレイに存在する文明は、どれもあなたにとって未知のものだろう。だが、広大なるあの世界へ、戻ることはもう出来ないのだ。",
  ].freeze

  YOUR_STORY_TABLE_ANOTHER_WORLD_3_4 = [
    "永遠のヴィクトリア：200年にわたるヴィクトリア女王の統治が続く常闇の世界。蒸気の霧が街を覆い、夜な夜な怪人が闊歩する世界から、あなたはここへ流れ着いた。あなたからすれば、ここは平和な世界だ。しかし、ステラバトルの願いがぶつかる華やかさだけは、あの頃を思い出させる。",
    "剣撃乱舞する世界：我々からすれば戦国と呼ばれた極東の一時代を、永遠に繰り返していた世界からあなたはここへ流れ着いた。あなたの剣技は、ステラバトルを切り抜けるのに十分に役立つことだろう。",
    "薄暗き森の世界：広大にして永遠に続く森に包まれた世界、霧と風、獣の鳴き声に満ちた世界から、あなたはここへ流れ着いた。あなたの姿を見て、エルフだとか、妖精だとか呼ぶものもいるかもしれないが、あなたには関係のないことだ。",
    "人類の瀬戸際：ここも、故郷も、大して変わらない。あなたの故郷は、地球に先んじてロアテラに滅ぼされた世界だ。ここを守護することに躊躇いはない。しかしそれよりも、あなたにとってはここで出会った唯一のパートナーの方が大切なのだ。",
    "人形劇の世界：あなたの世界に生きる人々は、元々は人間と呼ばれていたらしい。全ての住人が人形と化したあなたの故郷は、それなりに平和で、楽しいものだったはずだ。しかしそんな日々は、ある日突然終わってしまった。人形そのものであるあなたの姿は、時に奇異の目で見られることだろう。",
    "怪獣迎撃の世界：巨大な怪獣が存在し、それを迎え撃つ戦いを繰り返していた世界から、あなたはここへ流れ着いた。そして今も、アーセルトレイは異世界からの侵略者、ロアテラに狙われていると、あなたは理解している。",
  ].freeze

  YOUR_STORY_TABLE_ANOTHER_WORLD_5_6 = [
    "蒸気機関の世界：蒸気機関技術が異様に発達した世界から、あなたはここへ流れ着いた。アーセルトレイの技術レベルはそれらに匹敵するものだが、あなたからすると使い方の分からない不思議な技術だ。",
    "極東幻想の世界：我々の知る旧地球時代の日本、その国にて語られた鬼や妖怪が実在した世界からあなたはここへ流れ着いた。あなたからすれば、ステラナイトの強さはそれらをも超えるものかもしれない。",
    "異端生物の世界：バイオ技術か、交配の結果か、様々な生物と人類が融合した世界から、あなたはここへ辿り着いた。獣や鳥、海棲生物の特徴をあなたは備えている。",
    "異端科学の世界：人と機械の境界が曖昧な世界、個と全が曖昧な世界から、あなたはここへ流れ着いた。",
    "先進科学の世界：地球の科学がどこまでも真っ直ぐに育った世界から、あなたはここへ流れ着いた。美しく磨きあげられた街並み、道行く人の誰もが笑顔で、万人が幸せな世界から。",
    "草花の世界：植物と人が融合した世界から、あなたはここへ流れ着いた。あなたの身体は植物そのものかもしれないし、あるいは眼窩から花が咲いているかもしれない。",
  ].freeze

  YOUR_STORY_TABLE_ANOTHER_WORLD = [
    YOUR_STORY_TABLE_ANOTHER_WORLD_1_2,
    YOUR_STORY_TABLE_ANOTHER_WORLD_1_2,
    YOUR_STORY_TABLE_ANOTHER_WORLD_3_4,
    YOUR_STORY_TABLE_ANOTHER_WORLD_3_4,
    YOUR_STORY_TABLE_ANOTHER_WORLD_5_6,
    YOUR_STORY_TABLE_ANOTHER_WORLD_5_6,
  ].freeze

  WISH_TABLE_1_2 = [
    "未知の開拓者：誰も知らない世界、誰も知らない宇宙、誰も知らない星に旅立つんだ!【願いの階梯：4】",
    "故郷の復興：あなたの故郷である異世界、あるいは地球を復興する。【願いの階梯：4(階層規模の場合)】【願いの階梯：7(惑星規模の場合)】",
    "復讐：絶対にこの復讐を果たすのだ。【願いの階梯：2】",
    "誰にも傷つけられない世界：誰も私たちを傷つけない。そんな世界であればいい。【願いの階梯：7(惑星規模)】【願いの階梯：8(宇宙規模)】",
    "きらめく世界：世界を明るく楽しくしたい。私が光になるんだ!【願いの階梯：3(自分の変革)】【願いの階梯：7(世界そのものの変革)】",
    "おいしいごはん：ふたりで美味しいご飯を食べよう。それが世界で、一番大切なことなんだよ!【願いの階梯：2(おいしいごはんを食べるだけ)】【願いの階梯：4(ふたりの置かれた状況の改善)】",
  ].freeze

  WISH_TABLE_3_4 = [
    "私だけのもの：独り占めしたいモノがある。【願いの階梯：5】",
    "新たなる存在：この世に存在しないけれど、存在してほしいと願うモノ。私はそれが欲しいんだ。【願いの階梯：6】",
    "欲しいもの：どうしても手に入れたいものがある。【願いの階梯：1~10(欲しいものの種類によって変動)】",
    "取り戻す：あなたたちは何かを奪われた。それを取り戻すのが、唯一の願いだ。【願いの階梯：4(努力次第でいつか手に届く範囲)】【願いの階梯：6(通常は取り戻せないもの)】",
    "誰よりも、高く、遠くへ!：こんな鳥籠は嫌だ。空の果てを目指すんだ!【願いの階梯：4(積層都市内)】【願いの階梯：8(宇宙規模の場合)】",
    "あなたを自由に：大切なものは囚われ、縛られている。私のちからで、それを解き放つんだ!【願いの階梯：4(努力次第でいつか叶う範囲)】【願いの階梯：6(奇跡の領域)】",
  ].freeze

  WISH_TABLE_5_6 = [
    "誰かの笑顔：誰かの笑顔の為に戦っても、いいだろう?【願いの階梯：1~6(対象の状況によって変動する)】",
    "別の世界へ：……この世界ではない、別の世界へ行きたい。【願いの階梯：7(惑星規模)】【願いの階梯：8(宇宙規模)】",
    "世界を平和に：平穏な日々を願っても許されるような世界に、この世界をやすらぎに満ちた場所に……。【願いの階梯：7】",
    "世界を再誕させる：世界は根本から創り直す必要がある!【願いの階梯：8】",
    "世界を征服する：私たちが王になってやる!【願いの階梯：7】",
    "契約者：あなたの願いは既に叶えられた。今も戦い続けている理由は、女神との契約があるからだ。【願いの階梯：なし】",
  ].freeze

  WISH_TABLE = [
    WISH_TABLE_1_2,
    WISH_TABLE_1_2,
    WISH_TABLE_3_4,
    WISH_TABLE_3_4,
    WISH_TABLE_5_6,
    WISH_TABLE_5_6,
  ].freeze

  PERSONALITY_TABLE = %w{
    可憐 冷静 勇敢 楽観主義 負けず嫌い コレクター気質
    クール 癒やし系 惚れやすい 悲観主義 泣きやすい お嬢様
    純粋 頑固 辛辣 まじめ 落ち込みやすい 謙虚
    スマート ゆるふわ 好奇心旺盛 はらぺこ 華麗 狭いところが好き
    冷徹 朴念仁 王子様 目立ちたがり 過激 マゾヒスト
    ダンディ あらあらうふふ 過保護 死にたがり 強い自尊心 サディスト
  }.freeze

  YOUR_STORY_TABLE_MARGINALIA_1_2 = [
    "パブ/カフェー店員：あなたは霧の帝都に無数に存在するパブ、あるいは桜の帝都で増え始めたカフェーの店員です。",
    "屋台の店員：― 屋台とは戦いだ。あなたは霧の帝都の至る所に存在する、屋台の店員です。商売敵は数え切れないくらい存在します。目指せ、ナンバーワン屋台!!",
    "商人：がっぽがっぽ。お空に都市がやってきて、販路が増えたぞがっぽがっぽ。あなたは様々な商品を扱う商人です。小売からもうひとつの世界を股にかける交易商人まで、商いの道は果てしなく広がっています。",
    "飛行船・船長：あなたはふたつの都市をつなぐ交通の要、飛行船の船長です! ところで最近、船長の間で変な噂がたっています。ふたつの世界のちょうど狭間を通過する瞬間に、怪物と戦う騎士の幻が見えるのだとかなんとか……。",
    "飛行船駅員：あなたは飛行船発着場で働く駅員です。管制員から売店の職員まで、数多の人々によって飛行船は運航されています。",
    "図書館司書/博物館学芸員：あなたは文化の保護、知識の継承を担っています。霧の帝都、桜の帝都のどちらにも、立派な図書館、博物館が存在します。有名なのは桜の帝都「桜花書籍館」と霧の帝都「図書博物館」でしょう。",
  ].freeze

  YOUR_STORY_TABLE_MARGINALIA_3_4 = [
    "帝都警察：あなたは帝都警察に所属し、都市の平和を守っています。帝都警察は市民の憧れの職業であり、皆誇りをもって職務に励んでいます。",
    "警察軍：あなたは都市の有事の際に出動するべく、日々訓練に励む軍人です。災害や大規模な犯罪が発生した時こそ、あなたの出番です。",
    "寡黙なる霧(クラブ・マイクロフト)：霧の女王に仕える秘密の騎士団。いわゆる諜報機関、スパイ組織の構成員です。あなたは日々、怪物の発生や犯罪組織の暗躍に目を光らせています。",
    "桜機関(ブロッサムエンジン)：あなたはこの世界を、ロアテラに喰われる前に滅ぼすことを決意し、桜機関に所属したエージェントです。しかし、まだメモリィズを使用していないのは、迷いがあるからなのか、何らかの思惑があるからなのかもしれません。",
    "桜花教神官：「万物には桜が宿っています。我らの誇りたる桜を傷つけることがないように」あなたは桜花教の神官です。神官は日々大変忙しい生活を送っています。毎日の祭事に祭りの準備、そしてふらりと現れる桜の皇帝への対応……頑張ってくださいね?",
    "妖精教神官：「妖精は、いつもあなたの行いを見守っています」あなたは妖精教の神官です。週に一度のお祈りの日、毎日の貧民街への炊き出し、迷子の保護、霧の宮殿から抜け出していった霧の女王の捜索等、大忙しの日々が待っています。",
  ].freeze

  YOUR_STORY_TABLE_MARGINALIA_5_6 = [
    "流浪の民：あなたの祖先は、この世界に「都市の外側」があった時代に、この場所へ流れ着いてきた者です。この都市ではあまり見かけない髪、肌、目の色をしていたり、顔つきが少々異なっていたりします。",
    "イーストエンド：あなたは霧の帝都の貧民街で暮らしています。何故か伝統的に、貧民街は「イーストエンド」と呼ばれており、その地名がそのまま「貧民」を意味する言葉にもなっています。",
    "貴族：あなたは貴族として、民を守り、国を守ってきた一族の末裔です。遥かな空に、もうひとつの世界が現れても、異世界の騎士を交えた戦いが起きたとしても、あなたの使命は変わらず民と国を守ることなのです。",
    "職人：あなたは何らかの技術を身に付けた職人です。時計職人から傘張り職人まで、あなたの技術がふたつの世界を支えているのです。",
    "メイド/バトラー：あなたは貴族の屋敷や、宮殿、御所で働くメイド/バトラーや、その見習いです。ご主人さまのため、今日も職務に励むのです。",
    "バックアップ：あなたはかつて桜の皇帝、霧の女王のバックアップとして作成された人造生命体です。うりふたつの容姿をしていますが、その記憶は厳重に封印されており、あなたを含め、誰もその真実を知る者はいません。",
  ].freeze

  YOUR_STORY_TABLE_MARGINALIA = [
    YOUR_STORY_TABLE_MARGINALIA_1_2,
    YOUR_STORY_TABLE_MARGINALIA_1_2,
    YOUR_STORY_TABLE_MARGINALIA_3_4,
    YOUR_STORY_TABLE_MARGINALIA_3_4,
    YOUR_STORY_TABLE_MARGINALIA_5_6,
    YOUR_STORY_TABLE_MARGINALIA_5_6,
  ].freeze

  SITUATION_TABLE_MARGINALIA_1_2_3 = [
    "表のお仕事：生きていくにはお金がかかる。霧の女王様や総帥に頼ってばかりじゃいられない! さぁ今日も元気に出勤だ! パートナーと一緒に、どんなお仕事をしているか描写してみよう!",
    "カフェーでのんびり：とてものんびりした時間。おいしい紅茶とあまーいお菓子。……滅びそうな世界だなんて、思えないよね。",
    "路面電車：道路を電車が走るなんて不思議な気分。最新鋭の路面電車をご堪能あれ。さて、今日はどこへ行こうかな?",
    "参拝：霧の帝都なら妖精教会、桜の帝都なら桜花教神社。お参りをすると、ちょっと自分の考えがまとまるような気がする。",
    "アパルトメント：アーセルトレイと比べると、どうしても時代を感じてしまうアパルトメント。でもパートナーがいれば関係ない! せっかくだし、この世界でも思い出を作っていこう!",
    "桜の皇帝に遭遇：すごく意味深な質問をされた後、皇帝陛下は答えを聞くことなく、にっこりと微笑んで去っていった。えっ、あれ本物だよね? 本物の皇帝だよね!?",
  ].freeze

  SITUATION_TABLE_MARGINALIA_4_5_6 = [
    "暗闇会議：路地裏か、真夜中の私室か、夢の中か、ふとした瞬間に訪れた暗闇。「君たちは、永遠に続く苦しみを生きるか、その前に死ぬか、どちらが正しいと思う?」そんな声が聞こえた気がする。",
    "東部暗黒街：霧の帝都で最も治安の悪い場所。けれど誰もが好きでそうなったわけじゃない。人によっては、ここの方が居心地が良いのかも。",
    "帝都劇場：どちらの帝都にも、立派な劇場がある。最近では電気館なる、アーセルトレイでいう映画館もできてきたらしいよ? ちょっと行ってみない?",
    "飛行船内：帝都の間を結ぶ飛行船。アーセルトレイのモノレールにも少し似ているけれど、もっとレトロな感じ。船内販売の美味しいアイスクリンは絶対食べておこう!",
    "パブが私を呼んでいる：パブりに行こうぜ、バディ。愉快な音楽と、美味しい飲み物と、ちょっと癖の強い料理が私たちを待っている! 今夜も派手に騒ごうぜ!",
    "霧の女王からの呼び出し：霧の女王陛下に呼び出され、宮殿へ向かう道中の会話。いったい何の用事なんだろう? 確か先週は、アーセルトレイの話をいっぱいしながら、美味しいお茶をごちそうになったなぁ。",
  ].freeze

  SITUATION_TABLE_MARGINALIA = [
    SITUATION_TABLE_MARGINALIA_1_2_3,
    SITUATION_TABLE_MARGINALIA_1_2_3,
    SITUATION_TABLE_MARGINALIA_1_2_3,
    SITUATION_TABLE_MARGINALIA_4_5_6,
    SITUATION_TABLE_MARGINALIA_4_5_6,
    SITUATION_TABLE_MARGINALIA_4_5_6,
  ].freeze

  YOUR_STORY_TABLE_LETTER_1_2_3 = [
    "旅に出ていた：あなたが旅先にいる時に、世界の滅びはおとずれた。旅にでなければ、あの人と離れ離れにはならなかったのに。",
    "生き別れの――：パートナーとは生き別れの兄弟姉妹、親子のような、親密な関係だった。",
    "双子：あなたとパートナーは双子だった。どこにいても、きっとこの想いと鼓動は同じだ。",
    "幼馴染：あなたとパートナーは幼馴染だった。",
    "親友：きっとそれは、恋人や親子よりも深い友情だった。",
    "隠しきれない本音：本当は隠すつもりだった本音が、手紙となるとどうしても漏れ出してしまう。",
  ].freeze

  YOUR_STORY_TABLE_LETTER_4_5_6 = [
    "愛している：あなたはパートナーを愛している。何よりも、誰よりも、世界よりも。",
    "パズル：あなたは手紙に本音を隠す。縦読みだったり、暗号だったり……きっとそれは照れ隠しなのだ。",
    "恥ずかしい!!：かつて言葉では言えたのに、手紙となると素直になれない! どうしてだー!",
    "インク、筆跡：インクの色、筆跡を見るだけで、その手紙の主が誰だかわかる。――もちろん、君だろう？",
    "心の支え：心の支えにしているものがある。それはきっと、パートナーがくれたものだ。",
    "共犯者：ふたりはかつて、何らかの共犯者だった。内容は、自分自身が知っているだろう?",
  ].freeze

  YOUR_STORY_TABLE_LETTER = [
    YOUR_STORY_TABLE_LETTER_1_2_3,
    YOUR_STORY_TABLE_LETTER_1_2_3,
    YOUR_STORY_TABLE_LETTER_1_2_3,
    YOUR_STORY_TABLE_LETTER_4_5_6,
    YOUR_STORY_TABLE_LETTER_4_5_6,
    YOUR_STORY_TABLE_LETTER_4_5_6,
  ].freeze

  YOUR_STORY_TABLE_RECOLLECT_DOLL_1_2_3 = [
    "大好き：本当は、世界のことなんてどうでもいい。パートナーの方が大切。ずっとずっと大切なんだから。",
    "いつか人間に：あなたはリコレクト・ドールではなく、人間になりたいと思っている。",
    "永遠の命：遥かな未来を見てみたい。願わくば、パートナーと一緒に。",
    "ふたりきり：あなたはパートナーと一緒にいることだけを大切なことだと考えている。",
    "私は人形：……感情? それは必要なもの?",
    "探検隊：あなたは荒廃したこの世界をどこまでも探検したいと思っている。",
  ].freeze

  YOUR_STORY_TABLE_RECOLLECT_DOLL_4_5_6 = [
    "退屈な日々：あなたはこの荒廃した世界を退屈に思っている。",
    "理想の私：あなたは、あなたの考えうる限り最高で完璧で理想的なリコレクト・ドールだ。",
    "思弁的ドール：あなたは正直どこにもでかけたくない。いいじゃーん、ここからでも色々分かるって、あっ、ひっぱらないでー、あー。",
    "使命の徒：あなたはリコレクト・ドールとしての使命を第一に思っている。",
    "未知なる創造主：あなたはいつか人間に会ってみたいと思っている。",
    "漠然とした不安：旅も、戦いも、その先に待つのが終わりの日々なら……。みんなはどうして、不安に思わないの……?",
  ].freeze

  YOUR_STORY_TABLE_RECOLLECT_DOLL = [
    YOUR_STORY_TABLE_RECOLLECT_DOLL_1_2_3,
    YOUR_STORY_TABLE_RECOLLECT_DOLL_1_2_3,
    YOUR_STORY_TABLE_RECOLLECT_DOLL_1_2_3,
    YOUR_STORY_TABLE_RECOLLECT_DOLL_4_5_6,
    YOUR_STORY_TABLE_RECOLLECT_DOLL_4_5_6,
    YOUR_STORY_TABLE_RECOLLECT_DOLL_4_5_6,
  ].freeze

  SITUATION_TABLE_B_RECOLLECT_DOLL_1_2_3 = [
    "教室：かつて学校の教室だった場所。椅子と机が散乱している。",
    "劇場：かつて大きな劇場だった場所。天井が崩落し、ステージは瓦礫に埋もれている。",
    "遊園地：かつて遊園地と呼ばれていた場所。錆びついた骨組み、朽ちたステージ、観覧車の支柱は曲がって、今にも倒れそう。",
    "民家：扉や窓が無い家屋。埃が積もった室内には、錆びた家具がそのままになっている。",
    "音楽室：折れた譜面台や朽ちたピアノが放置された学校の一室。かつて音楽室と言われていた場所。",
    "喫茶店：食器と家具が散乱し、埃が積もった飲食店跡。かつては喫茶店だった場所。",
  ].freeze

  SITUATION_TABLE_B_RECOLLECT_DOLL_4_5_6 = [
    "図書館：ぼろぼろになった本と、倒れた本棚が放置された施設。かつて図書館だった場所。",
    "高層ビル：壁面が崩れ、骨格だけになった高層建築。上層階からは荒廃都市全体が見渡せる。かつてはオフィスビルだった場所。",
    "ショッピングモール：商店跡が建ち並ぶ施設。かつて大型ショッピングモールだった場所。",
    "荒野：都市周辺に、地平線の果てまで広がる灰色の荒野。かつてはのどかな田園地帯だった。",
    "駅：崩れた駅舎と、所々欠損した線路。かつて鉄道の駅だった場所。",
    "公園：石化した木々と、朽ちたベンチが点在する公園跡。かつては人々のいこいの場所だった。",
  ].freeze

  SITUATION_TABLE_B_RECOLLECT_DOLL = [
    SITUATION_TABLE_B_RECOLLECT_DOLL_1_2_3,
    SITUATION_TABLE_B_RECOLLECT_DOLL_1_2_3,
    SITUATION_TABLE_B_RECOLLECT_DOLL_1_2_3,
    SITUATION_TABLE_B_RECOLLECT_DOLL_4_5_6,
    SITUATION_TABLE_B_RECOLLECT_DOLL_4_5_6,
    SITUATION_TABLE_B_RECOLLECT_DOLL_4_5_6,
  ].freeze

  SITUATION_TABLE_C_RECOLLECT_DOLL_1_2_3 = [
    "仲良し：友達なのか、家族なのか。楽しそうによりそう2人の姿。",
    "けんか：顔を真っ赤にしてにらみ合う2人の姿。どうやらけんかしてしまったらしい。",
    "ダンス：手を取り、笑いながら、くるくると踊る2人の姿。",
    "食事：美味しそうに食事を摂る人の姿。あーん。",
    "読書：何かの本を熱心に読みふける人の姿。あの分厚い本は何?",
    "おしゃべり：楽しそうにおしゃべりする人々の姿。楽しそう、うぅん、幸せそう、なのかな?",
  ].freeze

  SITUATION_TABLE_C_RECOLLECT_DOLL_4_5_6 = [
    "イベント：笑顔で乾杯する人々の姿。誕生会? 結婚式? 何のイベントだろう?",
    "家族：連れ添い歩く家族の姿。パパとママ……家族って、どんなもの?",
    "友達：楽しそうに連れだって歩く、少年少女たちの姿。私たちは、友達……なのかな……?",
    "恋人：人目を忍んで手を繋ぎ見つめ合う、2人の姿。わ、わわ、わー! これは見ちゃだめー!! ",
    "別れ：涙を流しながら、別々の方向へ歩いて行く2人の姿。",
    "怪物：身の丈の倍ほどもある竜のような怪物と、逃げ惑う人々の姿。",
  ].freeze

  SITUATION_TABLE_C_RECOLLECT_DOLL = [
    SITUATION_TABLE_C_RECOLLECT_DOLL_1_2_3,
    SITUATION_TABLE_C_RECOLLECT_DOLL_1_2_3,
    SITUATION_TABLE_C_RECOLLECT_DOLL_1_2_3,
    SITUATION_TABLE_C_RECOLLECT_DOLL_4_5_6,
    SITUATION_TABLE_C_RECOLLECT_DOLL_4_5_6,
    SITUATION_TABLE_C_RECOLLECT_DOLL_4_5_6,
  ].freeze

  SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_1_2_3 = [
    "長い廊下：お喋りをしながら歩いていると、いつまで経っても目的地につかないながーい廊下。時々遭難者がでるの。",
    "迷子の女の子発見：迷子の女の子に遭遇してしまった。道案内してあげよう。……でも、やけに古い形の制服だなぁ。",
    "中庭のお茶会：お散歩していたらお茶会に招かれちゃった。みんなふたりの馴れ初めを聞きたいらしいぞ?",
    "誰もいない教室：あれ? さっきまでみんないたのに……。今はふたりしかいないみたい。",
    "学生寮：第3階層、シトラ女学院学生寮。まるで鳥籠のようだけれど、暮らしてみれば居心地は抜群。",
    "音楽室：昼間なら合唱部の歌声が、夜ならとても静かな夜の風が聞こえる場所。",
  ].freeze

  SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_4_5_6 = [
    "シトラ女学院旧校舎：地球時代からあったとされる、まるで神殿のような白く美しい旧校舎。立入禁止。でも内緒話にはうってつけ。",
    "輝紡の塔：塔とは名ばかりの、各委員会が部屋を構える大きなお屋敷。よく迷子が出るという噂あり。",
    "地下談話室：良く晴れた日の温室を、絵画と錯視で再現した談話室。雨の日でもぽかぽか。",
    "中庭のさくら：第1階層、シトラ女学院の中庭には、とても美しいさくらが咲いています。これは地球時代からあるものなのだとか……。",
    "約束の館：静かに祈りを捧げる場所。昔は礼拝堂と呼ばれていたとか。ここで愛の告白をすると、永遠の愛が得られるという噂も!",
    "星詠の間：輝紡の塔、最上階の小さな一室。地球があった頃の星空を再現する、星空投影機が設置されています。",
  ].freeze

  SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL = [
    SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_1_2_3,
    SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_1_2_3,
    SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_1_2_3,
    SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_4_5_6,
    SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_4_5_6,
    SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL_4_5_6,
  ].freeze

  SITUATION_TABLE_ECLIPSE_1_2_3 = [
    "道行く人々、その全ての視線が、まるで俺達を値踏みしているようだ……。",
    "かけられる言葉、その全てに何か裏があるように思える。俺達を騙そうとしているんじゃないか?",
    "部屋から出たくない。世界の全てが俺を殺そうとしている。早く、早くステラバトルの夜を……。",
    "何故こいつは、俺の顔を見て笑っているんだ?不快だ……殺してしまいたい……。",
    "俺をひとりにしないでくれ、どこにも行かないでくれ、頼む、俺を孤独にしないでくれ……。",
    "誰も俺達を信じない、誰も俺達を必要としない。俺には、お前だけいればいいんだ。",
  ].freeze

  SITUATION_TABLE_ECLIPSE_4_5_6 = [
    "世界の全てがおかしくなってしまった。もはや、世界を救えるのは俺達だけだ。",
    "ふたりの女神め、お前たちが黒幕だったのか。ステラバトルを終えたら、次はお前たちを殺してやる。",
    "俺の願いは……何だったか……。ああ、いや、すまない。大丈夫だ、俺は冷静だ。本当に……ああ……。",
    "風景のコントラストが、やけに強く見える。趣味の悪い絵画のようで気持ち悪い……。",
    "何を食べても味が感じられない。ロアテラの力が、世界の法則にまで侵食したのだろうか……。",
    "世界の全てがモノクロに見える。なんだこれは、ロアテラの力によるものなのか? 早く、早く世界を救わねば……。",
  ].freeze

  SITUATION_TABLE_ECLIPSE = [
    SITUATION_TABLE_ECLIPSE_1_2_3,
    SITUATION_TABLE_ECLIPSE_1_2_3,
    SITUATION_TABLE_ECLIPSE_1_2_3,
    SITUATION_TABLE_ECLIPSE_4_5_6,
    SITUATION_TABLE_ECLIPSE_4_5_6,
    SITUATION_TABLE_ECLIPSE_4_5_6,
  ].freeze

  FRAGMENT_TABLE = %w{
    出会い 水族館 動物園 絵本 童話 神話
    怒った 笑った 泣いた 好き 愛情 憎悪
    寒い 暑い 甘い 苦い お菓子 路地
    部屋 身体 ぬくもり 毛布 空想 願い
    笑顔 味覚 映画 朗読 うた 音楽
    視力 肌の色 聴力 声 痛覚 触覚
  }.freeze

  YOUR_STORY_TABLE_BRINGER_1_2_3 = [
    "肉親を失った：ブライトによる事件であなたは肉親を失った。",
    "恋人を失った： ブライトによる事件であなたは恋人や伴侶を失った。",
    "八つ当たり：あなたはやり場のない怒りを、ブリンガーとしての職務にぶつけている。",
    "正義感：あなたがブライトを狩れば、助かる人がいる。",
    "スカウト：あなたは何らかの才能を見出され、ブリンガーとなった。",
    "冷徹なる者：あなたはフォージの生命を、冷徹に切り捨てられると見込まれスカウトされた。本当に?",
  ].freeze

  YOUR_STORY_TABLE_BRINGER_4_5_6 = [
    "復讐：あなたはブライトという存在に復讐するために生きている。",
    "ノブリス・オブリージュ：あなたはブリンガーであることを義務だと考えている。",
    "世界を取り戻す：ラストヴライトを目指そう。君となら、世界を救えるはずだ。",
    "愛情：あなたはフォージを愛してしまった。",
    "歴戦のブリンガー：あなたのパートナーはフォージのフラグメントを1~3個失った状態で作成する。",
    "他階層出身：あなたは他の階層から第753層へ来た折に、世界の崩壊に巻き込まれた。",
  ].freeze

  YOUR_STORY_TABLE_BRINGER = [
    YOUR_STORY_TABLE_BRINGER_1_2_3,
    YOUR_STORY_TABLE_BRINGER_1_2_3,
    YOUR_STORY_TABLE_BRINGER_1_2_3,
    YOUR_STORY_TABLE_BRINGER_4_5_6,
    YOUR_STORY_TABLE_BRINGER_4_5_6,
    YOUR_STORY_TABLE_BRINGER_4_5_6,
  ].freeze

  YOUR_STORY_TABLE_FORGE_1_2_3 = [
    "信頼：あなたはパートナーを信頼している。あなたとなら大丈夫。",
    "愛情：あなたはパートナーを愛している。自分はフォージなのに、こんな感情を抱いても良いのだろうか。",
    "利用：あなたはパートナーを利用して、何かを成そうとしている。",
    "正義感：あなたが戦い続ければ、世界は維持される。",
    "気になる：パートナーが気になる。気になるの。す、好きとかじゃないし。気になるだけ。",
    "人形：あなたは無感情に、ただ任務を遂行し続ける。",
  ].freeze

  YOUR_STORY_TABLE_FORGE_4_5_6 = [
    "失敗作：あなたは製造段階で問題が発生している。あなたはフラグメントを1個失う。",
    "ノブリス・オブリージュ：あなたはフォージであることを義務だと考えている。",
    "世界を取り戻す：ラストヴライトを目指そう。パートナーとなら、世界を救えるはずだ。",
    "戦いたくない：あなたは戦いが嫌いだ。でもパートナーのためなら……。",
    "自傷癖：どうせ死ぬなら、今傷ついても同じでしょ?",
    "過去の記憶：あなたの元になった魂の輝き、その記憶をあなたは持っている。",
  ].freeze

  YOUR_STORY_TABLE_FORGE = [
    YOUR_STORY_TABLE_FORGE_1_2_3,
    YOUR_STORY_TABLE_FORGE_1_2_3,
    YOUR_STORY_TABLE_FORGE_1_2_3,
    YOUR_STORY_TABLE_FORGE_4_5_6,
    YOUR_STORY_TABLE_FORGE_4_5_6,
    YOUR_STORY_TABLE_FORGE_4_5_6,
  ].freeze

  SITUATION_TABLE_ALT_LEVOOT_1_2_3 = [
    "張り込み中：パートナーがあんぱんとコーヒーを買ってきた。ひとまず腹ごしらえだ!",
    "張り込み中：被疑者の部屋の窓にはカーテンがかかっている。薄暗いし、眠っているのかもしれない。はぁ、こっちも眠いぞ……。",
    "追走劇：ブライト被疑者が逃走している。逃げるということは何かやましいことがあるのだろう。行くぞ!",
    "追走劇：日常会話の最後に、他のステラナイトから被疑者確保の救援依頼が入る。手を貸してやるとしましょうか。",
    "引き渡し後：大人しくつかまったブライト被疑者を引き渡した後。さて、何か食べに行こうか。",
    "引き渡し後：被疑者を引き渡した後。逮捕の為に色々壊したりしてしまったので、報告書を書かねば。手伝ってくれよぉ……。",
  ].freeze

  SITUATION_TABLE_ALT_LEVOOT_4_5_6 = [
    "非番：今日は何もなければこのまま休みだ。たまにはどこかに出かけるか?",
    "非番：何か良い匂いがする。……パートナーが手料理を作ってくれた!?",
    "殺人現場：ブライトの凶行の現場。現場検証に立ち会うことになったが……。",
    "殺人現場：ブライトに殺されたのは、あなたの懇意にしていた情報屋だった。許さねぇぞ……。",
    "寿命を数える：あと、パートナーは何日生きられるのか。その日になったら、俺はこいつを殺せるのか。",
    "記念日：フォージとの記念日は毎月ある。一周年がないから、毎月なんだ。",
  ].freeze

  SITUATION_TABLE_ALT_LEVOOT = [
    SITUATION_TABLE_ALT_LEVOOT_1_2_3,
    SITUATION_TABLE_ALT_LEVOOT_1_2_3,
    SITUATION_TABLE_ALT_LEVOOT_1_2_3,
    SITUATION_TABLE_ALT_LEVOOT_4_5_6,
    SITUATION_TABLE_ALT_LEVOOT_4_5_6,
    SITUATION_TABLE_ALT_LEVOOT_4_5_6,
  ].freeze

  TABLES = {
    "GAT" => Table.new(
      "所属組織決定",
      "1D6",
      GAKUEN_TABLE
    ),
    "HOT" => D66GridTable.new(
      "希望表",
      HOPE_TABLE
    ),
    "DET" => D66GridTable.new(
      "絶望表",
      DESPAIR_TABLE
    ),
    "WIT" => D66GridTable.new(
      "願い事表",
      WISH_TABLE
    ),
    "YST" => D66GridTable.new(
      "あなたの物語表",
      YOUR_STORY_TABLE
    ),
    "YSTA" => D66GridTable.new(
      "あなたの物語表：異世界",
      YOUR_STORY_TABLE_ANOTHER_WORLD
    ),
    "YSTM" => D66GridTable.new(
      "あなたの物語表：マルジナリア世界",
      YOUR_STORY_TABLE_MARGINALIA
    ),
    "STM" => D66GridTable.new(
      "シチュエーション表：マルジナリア世界",
      SITUATION_TABLE_MARGINALIA
    ),
    "YSTL" => D66GridTable.new(
      "あなたの物語表：手紙世界",
      YOUR_STORY_TABLE_LETTER
    ),
    "YSTR" => D66GridTable.new(
      "あなたの物語表：リコレクト・ドール",
      YOUR_STORY_TABLE_RECOLLECT_DOLL
    ),
    "STBR" => D66GridTable.new(
      "シチュエーション表B：場所（リコレクト・ドール）",
      SITUATION_TABLE_B_RECOLLECT_DOLL
    ),
    "STCR" => D66GridTable.new(
      "シチュエーション表C：リコレクト",
      SITUATION_TABLE_C_RECOLLECT_DOLL
    ),
    "STBS" => D66GridTable.new(
      "シチュエーション表B：シトラセッティング",
      SITUATION_TABLE_B_RECOLLECT_SUT_TU_REAL
    ),
    "STE" => D66GridTable.new(
      "シチュエーション表：エクリプス専用",
      SITUATION_TABLE_ECLIPSE
    ),
    "YSTB" => D66GridTable.new(
      "あなたの物語表：ブリンガー",
      YOUR_STORY_TABLE_BRINGER
    ),
    "YSTF" => D66GridTable.new(
      "あなたの物語表：フォージ",
      YOUR_STORY_TABLE_FORGE
    ),
    "STAL" => D66GridTable.new(
      "シチュエーション表：オルトリヴート",
      SITUATION_TABLE_ALT_LEVOOT
    ),
  }.freeze

  setPrefixes(['\d+SK\d?(,\d>\d)*', 'TT', 'STA', 'STB', 'STB2', 'STC', 'ALLS', 'PET', 'FT\d*'] + TABLES.keys)
end
