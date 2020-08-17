# -*- coding: utf-8 -*-

class RyuTuber < DiceBot
  # ゲームシステムの識別子
  ID = 'RyuTuber'

  # ゲームシステム名
  NAME = 'リューチューバーとちいさな奇跡'

  # ゲームシステム名の読みがな
  SORT_KEY = 'りゆうちゆうばあとちいさなきせき'

  HELP_MESSAGE = <<MESSAGETEXT
◆判定
　・判定　nB6<=1
　　※　n:サイコロの数　例）12B6<=1　サイコロの数12個の場合
　・判定ルールを表示する　RTB
◆職業　（カッコ内は使えそうな技能）
　・職業表　JT
　・学生表　JST
　・技術・専門職表　JTPT
　・事務・サービス職表　JOST
　・エンタメ職表　JET
◆趣味　（カッコ内は使えそうな技能）
　・趣味表　HT
　・多人数でできる趣味表　HGT
　・一人でできるインドア趣味表Ａ　HIAT
　・一人でできるインドア趣味表Ｂ　HIBT
　・一人でできるアウトドア趣味表Ａ　HOAT
　・一人でできるアウトドア趣味表Ｂ　HOBT
◆奇跡の演目を表示する
　・幸運の風が吹いている MPW
　・困った時はお互い様 MPT
　・悪い予感は的中する MPF
　・ついていい嘘もある MPL
　・私には星が見えている MPS
　・心は竜と共にあり MPD
　・人は石垣、人は城 MPH
MESSAGETEXT

  setPrefixes(['RTB','JT','JST','JTPT','JOST','JET','HT','HGT','HIAT','HIBT','HOAT','HOBT','MPW','MPT','MPF','MPL','MPS','MPD','MPH'])

  def rollDiceCommand(command) # ダイスロールコマンド

  # 表示テキスト
  show_checkrule = "①枠主が判定内容を宣言、判定参加者が行動宣言\n②サイコロは竜の巫女なら６個、技能レベルか指定魅力の値個、奇跡の演目を１つ以上クリアで＋６個、スパの消費数個\n③振ったサイコロの「１の目」の数が目標値以上なら華麗に成功、目標値未満ならちょっと残念な結果"
  show_mpluckywind = "奇跡　以降ゲーム終了まで、サイコロ＋１\n①健気に頑張る姿を見せる。\n②報われることはなく、さらに最悪の展開に。\n③それでも健気なところを見せる。"
  show_mptroubledtime = "奇跡　そのプレイヤーの判定サイコロを１回振り直しできる\n①けちな様子を見せる。\n②困っている人に施しをする姿を見られる。\n③窮地に陥る。"
  show_mpbadfeeling = "奇跡　１判定だけ、サイコロ＋３\n①犠牲者が悪い噂を耳にする。\n②犠牲者が悪い冗談を言う。\n③犠牲者が悪い予感に心さざめき、誰かに悪い予感を話す。"
  show_mpexpedient = "奇跡　ついた（ささやかな）嘘が本当になる　枠主判断でいつか発動する。\n①嘘を言う。\n②嘘によって窮地に立つ。\n③嘘を嘘にしないためにあがく。"
  show_mpstarseer = "奇跡　指定したキャラクターの次の行動がわかる\n①少し先のことを言い当てる。\n②気味が悪いと噂になる。\n③言い当てる力を人間観察に用いる。"
  show_mpwiththedragon = "奇跡　起こりうる不幸を阻止する\n①心清いひとに助けられる。\n②自分の性根悪さを悲しむ。\n③自分なりのやり方で心清い行いをする。"
  show_mphumanbond = "奇跡　感化された周りの人が手伝うようになる\n①人々の不幸を見て、親切にしてしまう。\n②けなげに頑張る姿を見られる。\n③見ていた人々が集まってくる。"
 
    # 表示
    type = ""
    result = '0'
    total_n = "\n"
    
    case command.upcase #大文字にしてチェックする
    when 'RTB'
      type = '判定ルール表示'
      result = show_checkrule
    when 'MPW'
      type = '幸運の風が吹いている'
      result = show_mpluckywind
    when 'MPT'
      type = '困った時はお互い様'
      result = show_mptroubledtime
    when 'MPF'
      type = '悪い予感は的中する'
      result = show_mpbadfeeling
    when 'MPL'
      type = 'ついていい嘘もある'
      result = show_mpexpedient
    when 'MPS'
      type = '私には星が見えている'
      result = show_mpstarseer
    when 'MPD'
      type = '心は竜と共にあり'
      result = show_mpwiththedragon
    when 'MPH'
      type = '人は石垣、人は城'
      result = show_mphumanbond
    when 'JT'
      type = '職業表'
      result, total_n = get_job_table
    when 'JST'
      type = '学生表'
      result, total_n = get_jobstudent_table
    when 'JTPT'
      type = '技術・専門職表'
      result, total_n = get_jobtechpro_table
    when 'JOST'
      type = '事務・サービス職表'
      result, total_n = get_jobofficeservice_table
    when 'JET'
      type = 'エンタメ職表'
      result, total_n = get_jobentertainment_table
    when 'HT'
      type = '趣味表'
      result, total_n = get_hobby_table
    when 'HGT'
      type = '多人数でできる趣味表'
      result, total_n = get_hobbygroup_table
    when 'HIAT'
      type = '一人でできるインドア趣味表Ａ'
      result, total_n = get_hobbyindoora_table
    when 'HIBT'
      type = '一人でできるインドア趣味表Ｂ'
      result, total_n = get_hobbyindoorb_table
    when 'HOAT'
      type = '一人でできるアウトドア趣味表Ａ'
      result, total_n = get_hobbyoutdoora_table
    when 'HOBT'
      type = '一人でできるアウトドア趣味表Ｂ'
      result, total_n = get_hobbyoutdoorb_table
    end
    return "#{type} #{total_n} ＞ #{result}"
 end

  # 職業表
  def get_job_table
    table = [
      '学生表へ',
      '技術・専門職表へ',
      '技術・専門職表へ',
      '事務・サービス職表へ',
      '事務・サービス職表へ',
      'エンタメ職表へ'
    ]
    return get_table_by_1d6(table)
  end

  # 学生表
  def get_jobstudent_table
    table = [
      '中学生　（ゲーム　運動する）',
      '高校生（文系）　（仲良くする　文章を書く）',
      '高校生（理系）　（仲良くする　科学の知識）',
      '専門学校生　（ものづくり　設計する）',
      '大学生（文系）　（社会の仕組み　外国語）',
      '大学生（理系）　（すごい技術　科学の知識）'
    ]
    return get_table_by_1d6(table)
  end

  # 技術・専門職表
  def get_jobtechpro_table
    table = [
      '勝負師・山師　（洞察力　精神力）',
      '漁師/猟師　（自然の知識　料理する）',
      '建築家、大工　（設計する　運転する）',
      '料理人　（料理する　ものづくり）',
      '職人　（ものづくり　丁寧）',
      '農家　（自然の知識　育てる）',
      '医療・福祉関係（医師、薬剤師、介護職）　（治す　科学の知識）',
      '美容、スタイリスト　（見た目を整える　仲良くする）',
      'プログラマー　（プログラム　設計する）',
      '士業（税理士、弁護士、行政書士等）　（社会の仕組み　事務仕事）',
      '研究者　（教える　すごい技術）'
    ]
    return get_table_by_2d6(table)
  end

  # 事務・サービス職表
  def get_jobofficeservice_table
    table = [
      '宗教関係（巫女、僧侶など）　（お祈りする　地元知識）',
      '観光、旅行　（外国語　地元知識）',
      '教師、保育士　（教える　育てる）',
      '運転手、配達員　（運転する　地元知識）',
      '自宅警備員　（ゲーム　想像力）',
      'サラリーマン　（事務仕事　仲良くする）',
      '店員　（丁寧　商品知識）',
      '公務員　（事務仕事　地元知識）',
      '警察、自衛隊、消防士　（社会の仕組み　戦う）',
      '投資家、金融業、不動産　（プレゼンする　事務仕事）',
      '経営者　（社会の仕組み　仲良くする）'
    ]
    return get_table_by_2d6(table)
  end

  # エンタメ職表
  def get_jobentertainment_table
    table = [
      'ゲーム制作　（プログラム　ものづくり）',
      '写真家　（自然の知識　絵を描く）',
      'デザイナー　（設計する 見た目を整える）',
      'ライター　（文章を書く　想像力）',
      'イラストレーター　（絵を描く　見た目を整える）',
      '専業配信者　（プレゼンする　カリスマ）',
      '声優　（声を出す　演技する）',
      'ミュージシャン　（声を出す　音楽）',
      'アイドル・芸能人　（演技する　カリスマ）',
      'プロゲーマー　（ゲーム　戦う）',
      'プロスポーツ選手　（運動する　精神力）'
    ]
    return get_table_by_2d6(table)
  end

  # 趣味表
  def get_hobby_table
    table = [
      '多人数でできる趣味表へ',
      '多人数でできる趣味表へ',
      '一人でできるインドア趣味表Ａへ',
      '一人でできるインドア趣味表Ｂへ',
      '一人でできるアウトドア趣味表Ａへ',
      '一人でできるアウトドア趣味表Ｂへ'
    ]
    return get_table_by_1d6(table)
  end

  # 多人数でできる趣味表
  def get_hobbygroup_table
    table = [
      '家族サービス　（仲良くする　育てる）',
      '野球・フットサル　（仲良くする　運動する）',
      'ボードゲーム／ＴＲＰＧ／囲碁／将棋　（ゲーム　想像する）',
      'ボランティア　（忍耐力　カリスマ）',
      'サバイバルゲーム　（戦う　隠れる）',
      'バンド　（音楽　見た目を整える）'
    ]
    return get_table_by_1d6(table)
  end

  # 一人でできるインドア趣味表Ａ
  def get_hobbyindoora_table
    table = [
      '工芸　（ものづくり　想像力）',
      '編み物　（丁寧　見た目を整える）',
      '陶芸　（ものづくり　想像力）',
      'プラモ　（ものづくり　見た目を整える）',
      '同人　（絵を描く　文章を書く）',
      '読書　（外国語　社会の仕組み）'
    ]
    return get_table_by_1d6(table)
  end

  # 一人でできるインドア趣味表Ｂ
  def get_hobbyindoorb_table
    table = [
      '仕事　（事務仕事　忍耐力）',
      '資格集め　（社会の仕組み　商品知識）',
      'お絵かき　（絵を描く　想像力）',
      '料理　（料理する　設計する）',
      '筋トレ　（運動する　忍耐力）',
      'コンピューターゲーム　（ゲーム　プログラム）'
    ]
    return get_table_by_1d6(table)
  end

  # 一人でできるアウトドア趣味表Ａ
  def get_hobbyoutdoora_table
    table = [
      'スポーツ観戦　（忍耐力　お祈りする）',
      '水泳　（運動する　泳ぐ）',
      '旅行／鉄道　（移動する　外国語）',
      '写真　（自然の知識　想像力）',
      'ジグソーパズル　（ゲーム　忍耐力）',
      'マラソン　（運動する　忍耐力）'
    ]
    return get_table_by_1d6(table)
  end

  # 一人でできるアウトドア趣味表Ｂ
  def get_hobbyoutdoorb_table
    table = [
      'スキー・スノーボード　（運動する　自然の知識）',
      '自転車　（移動する　運動する）',
      '盆栽・生花　（丁寧　育てる）',
      'キャンプ　（自然の知識　精神力）',
      '映画鑑賞　（演技する　想像力）',
      '恋愛　（仲良くする　見た目を整える）'
    ]
    return get_table_by_1d6(table)
  end

end
