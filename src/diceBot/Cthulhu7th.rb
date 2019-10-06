# -*- coding: utf-8 -*-

class Cthulhu7th < DiceBot
  setPrefixes(['CC\(\d+\)', 'CC.*', 'CBR\(\d+,\d+\)', 'FAR\(\d+\)', 'FAR.*', 'SI.*', 'BMR', 'BMS', 'FCL', 'FCM', 'PH', 'MA', 'COM', 'IHI(C)?.*', 'IHI(C)?\(\d+,\d+\)', 'KRI(C)?.*', 'KRI(C)?\(\d+,\d+\)', 'PD', 'IB', 'SP', 'ML', 'TP', 'TR', 'ABG', 'IO(C)?.*', 'IO(C)?\(\w+\)', 'KO(C)?.*', 'KO(C)?\(\w+\)', 'MN', 'FN', 'RN'])

  def initialize
    # $isDebug = true
    super

    @bonus_dice_range = (-2..2)
  end

  def gameName
    'クトゥルフ第7版'
  end

  def gameType
    "Cthulhu7th"
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
※私家翻訳のため、用語・ルールの詳細については原本を参照願います。
※コマンドは入力内容の前方一致で検出しています。
・判定　CC(x)<=（目標値）
　x：ボーナス・ペナルティダイス：Bonus/Penalty Dice (2～－2)。省略可。
　目標値が無くても1D100は表示される。
　致命的失敗：Fumble／失敗：Failure／通常成功：Regular success／
　困難な成功：Hard success／極限の成功：Extreme success／
　決定的成功：Critical success　を自動判定。
例）CC<=30　CC(2)<=50　CC(-1)<=75 CC-1<=50 CC1<=65 CC

・組み合わせ判定　(CBR(x,y))
　目標値 x と y で％ロールを行い、成否を判定。
　例）CBR(50,20)

・連射（Full Auto）判定　FAR(w,x,y,z,d)
　w：弾数(1～100）、x：技能値（1～100）、y：故障ナンバー、
　z：ボーナス・ペナルティダイス(-2～2)。省略可。
　d：指定難易度で連射を終える（通常成功：r,困難な成功：h,極限の成功：e）。省略可。
　命中数と貫通数、残弾数のみ算出。ダメージ算出はありません。
例）FAR(25,70,98)　FAR(50,80,98,-1)　far(30,70,99,1,R)
　　far(25,88,96,2,h)　FaR(40,77,100,,e)

・成長ロール　SIx[y]
　x：技能値、[y]：試行回数（自動的にy回連続で成長を行います。[y]省略可。）
例）SI89　SI25[10]

・各種表
　【狂気関連】
　・即時の狂気の発作（Bouts of Madness Real Time）表　BMR
　・略式の狂気の発作（Bouts of Madness Summary）表　BMS
　・恐怖症（Sample Phobias）表　PH／マニア（Sample Manias）表　MA
　【魔術関連】
　・プッシュ時の詠唱ロール（Casting Roll）での失敗表
　　控えめな呪文の場合　FCL／パワフルな呪文の場合　FCM
　【バックグラウンド関係】
　・外的特徴（Personal Description）表　PD／信念・信仰（Ideology/Beliefs）表　IB
　　重要な人物（Significant People）表　SP／宝物（Treasured Possessions）表　TP
　　意味のある場所（Meaningful Locations）表　ML／内的特徴（Traits）表　TR
　　全てのバックグラウンド一括　ABG
　【職業関係】
　・Keeper Rulebookから職業をランダムに決定　KO(x) (KOCで現代職業を非選択)
　　Investigators Handbookの職業をランダムに決定IO(x) (IOCで現代職業を非選択)
　xにstr, edu, dex, app, powのいずれかを入力すると、
　入力した能力値で職業技能ポイントを決定する職業からランダムに決定。省略可。)
例）KO(str), KO, KOC(DEX), KOC, IO(App), IO, IOC(PoW), IOC
　【名前関係】（Investigators Handbook収録の名前表を使用）
　・男性名ランダム作成　MN／女性名ランダム作成　FN／男女混合ランダム名前作成　RN

・ルール外補助ツール（通常ルールに、全てランダムでキャラクター作成という方法は無い為）
　・キャラクター能力値自動生成　COM
　・Keeper Rulebookの職業からランダムに探索者自動生成
　　KRI[a.b] (KRICで現代職業を非選択)
　・Investigators Handbookの職業からランダムに探索者自動生成
　　IHI[a,b] (IHICで現代職業を非選択)
　　[a,b]は省略可。a～b歳（最低15歳、最高90歳）で、偏りなしでランダムに年齢を決定。
　　KRI[a]、IHI[a]のみで年齢をa歳に指定して、その他をランダムに決定。
　　年齢無指定の場合、59歳以下が約9割出るように偏らせて決定（一番出やすいのは30代）。
　　注意：サーバーに負荷がかかるので、反応遅くても連打しないこと。
例）KRI, KRIC, KRI[20,40], KRIC[20,40],KRI[34],KRIC[89]
　　IHI, IHIC, IHI[20,40], IHIC[20,40],IHI[34],IHIC[89]
INFO_MESSAGE_TEXT
  end

  def rollDiceCommand(command)
    case command
    when /^CC/i
      return getCheckResult(command)
    when /^CBR/i
      return getCombineRoll(command)
    when /^FAR/i
      return getFullAutoResult(command)
    when /^SI/i # 技能成長
      return getCheckRoll(command)
    when /(^BMR)/i # 即時の狂気の発作表
      return BMR_table()
    when /(^BMS)/i # 略式の狂気の発作表
      return getBMS_table()
    when /(^FCL)/i # 詠唱ロールのプッシュに失敗した場合（小）
      return getFCL_table()
    when /(^FCM)/i # 詠唱ロールのプッシュに失敗した場合（大）
      return getFCM_table()
    when /(^PH)/i # 恐怖症表
      return getPH_table()
    when /(^MA)/i # マニア表
      return getMA_table()
    when /(^COM)/i # キャラクター能力値生成
      return getCOMResult()
    when /(^IHI)/i # 探索者ブックキャラクターデータ生成
      return getCOMALLResult(command)
    when /(^IHIC)/i # 探索者ブックキャラクターデータ生成現代職業なし
      return getCOMALLResult(command)
    when /(^KRI)/i # KPルールブックキャラクターデータ生成
      return getCOMALLResult(command)
    when /(^KRIC)/i # KPルールブックキャラクターデータ生成現代職業なし
      return getCOMALLResult(command)
    when /(^PD)/i # Personal Description
      return PD_text()
    when /(^IB)/i # Ideology/Beliefs
      return IB_text()
    when /(^SP)/i # Significant People
      return SP_text()
    when /(^ML)/i # Meaningful Locations
      return ML_text()
    when /(^TP)/i # Treasured Possessions
      return TP_text()
    when /(^TR)/i # Traits
      return TR_text()
    when /(^ABG)/i # バックグラウンド全部
      return getAllBG_text()
    when /(^KO)/i # ルールブック職業ランダム
      return Occupation_text(command)
    when /(^KOC)/i # ルールブック現代抜き職業ランダム
      return Occupation_text(command)
    when /(^IO)/i # 探索者ハンドブック職業ランダム
      return Occupation_text(command)
    when /(^IOC)/i # 探索者ハンドブック現代抜き職業ランダム
      return Occupation_text(command)
    when /(^MN)/i # 男性名前ランダム
      return MaleNames_text()
    when /(^FN)/i # 女性名前ランダム
      return FemaleNames_text()
    when /(^RN)/i # 名前ランダム
      return RandomNames_text()
    end

    return nil
  end

  def get_coc7th_1d8_table_output(tableName, table)
    total_n, = roll(1, 8)
    index = total_n - 1

    text = table[index]
    return '1' if text.nil?

    output = "#{tableName}(#{total_n}) ＞ #{text}"

    return output
  end

  def get_coc7th_1d100_table_output(tableName, table)
    total_n, = roll(1, 100)
    index = total_n - 1

    text = table[index]
    return '1' if text.nil?

    output = "#{tableName}(#{total_n}) ＞ #{text}"

    return output
  end

  def getCheckResult(command)
    nil unless /^CC([-\d]+)?<=(\d+)/i =~ command
    bonus_dice_count = Regexp.last_match(1).to_i # ボーナス・ペナルティダイスの個数
    diff = Regexp.last_match(2).to_i

    # 「return "エラー。目標値は1以上です。" if diff <= 0」は、以下の処理に置き換えて、CCのみでロールできるように変更。
    if diff <= 0
      dice, = roll(1, 100)
      return  "1D100 ＞ #{dice}"
    end

    unless @bonus_dice_range.include?(bonus_dice_count)
      return "エラー。ボーナス・ペナルティダイスの値は#{@bonus_dice_range.min}～#{@bonus_dice_range.max}です。"
    end

    output = ""
    output += "(1D100<=#{diff})"
    output += " ボーナス・ペナルティダイス[#{bonus_dice_count}]"

    units_digit = rollPercentD10
    total_list = getTotalLists(bonus_dice_count, units_digit)

    total = getTotal(total_list, bonus_dice_count)
    result_text = getCheckResultText(total, diff)

    output += " ＞ #{total_list.join(', ')} ＞ #{total} ＞ #{result_text}"

    return output
  end

  def rollPercentD10
    dice, = roll(1, 10)
    dice = 0 if dice == 10

    return dice
  end

  def getTotalLists(bonus_dice_count, units_digit)
    total_list = []

    tens_digit_count = 1 + bonus_dice_count.abs
    tens_digit_count.times do
      bonus = rollPercentD10
      total = (bonus * 10) + units_digit
      total = 100 if total == 0

      total_list.push(total)
    end

    return total_list
  end

  def getTotal(total_list, bonus_dice_count)
    return total_list.min if bonus_dice_count >= 0

    return total_list.max
  end

  def getCheckResultText(total, diff, fumbleable = false)
    if total <= diff
      return "決定的成功" if total == 1
      return "極限の成功" if total <= (diff / 5)
      return "困難な成功" if total <= (diff / 2)

      return "通常成功"
    end

    fumble_text = "致命的失敗"

    return fumble_text if total == 100

    if total >= 96
      if diff < 50
        return fumble_text
      else
        return fumble_text if fumbleable
      end
    end

    return "失敗"
  end

  def getCombineRoll(command)
    return nil unless /CBR\((\d+),(\d+)\)/i =~ command

    diff_1 = Regexp.last_match(1).to_i
    diff_2 = Regexp.last_match(2).to_i

    total, = roll(1, 100)

    result_1 = getCheckResultText(total, diff_1)
    result_2 = getCheckResultText(total, diff_2)

    successList = ["決定的成功", "極限の成功", "困難な成功", "通常成功"]

    succesCount = 0
    succesCount += 1 if successList.include?(result_1)
    succesCount += 1 if successList.include?(result_2)
    debug("succesCount", succesCount)

    rank =
      if succesCount >= 2
        "成功"
      elsif succesCount == 1
        "部分的成功"
      else
        "失敗"
      end

    return "(1d100<=#{diff_1},#{diff_2}) ＞ #{total}[#{result_1},#{result_2}] ＞ #{rank}"
  end

  def getFullAutoResult(command)
    return nil unless /^FAR\((-?\d+)(,(-?\d+))(,(-?\d+))(,|,(-?\d+))?(,|,(-?\w+))?\)/i =~ command

    bullet_count = Regexp.last_match(1).to_i
    diff = Regexp.last_match(3).to_i
    broken_number = Regexp.last_match(5).to_i
    bonus_dice_count = (Regexp.last_match(7) || 0).to_i
    stop_count = (Regexp.last_match(9) || "").to_s.downcase

    output = ""

    # 最大で（8回*（PC技能値最大値/10））＝72発しか撃てないはずなので上限
    bullet_count_limit = 100
    if bullet_count > bullet_count_limit
      output += "\n弾薬が多すぎます。装填された弾薬を#{bullet_count_limit}発に変更します。\n"
      bullet_count = bullet_count_limit
    end

    return "弾薬は正の数です。" if bullet_count <= 0
    return "目標値は正の数です。" if diff <= 0

    if broken_number < 0
      output += "\n故障ナンバーは正の数です。マイナス記号を外します。\n"
      broken_number = broken_number.abs
    end

    unless @bonus_dice_range.include?(bonus_dice_count)
      return "\nエラー。ボーナス・ペナルティダイスの値は#{@bonus_dice_range.min}～#{@bonus_dice_range.max}です。"
    end

    output += "ボーナス・ペナルティダイス[#{bonus_dice_count}]"
    output += rollFullAuto(bullet_count, diff, broken_number, bonus_dice_count, stop_count)

    return output
  end

  def rollFullAuto(bullet_count, diff, broken_number, dice_num, stop_count)
    output = ""
    loopCount = 0

    counts = {
      :hit_bullet => 0,
      :impale_bullet => 0,
      :bullet => bullet_count,
    }

    # 難易度変更用ループ
    (0..3).each do |more_difficlty|
      output += getNextDifficltyMessage(more_difficlty)

      # ペナルティダイスを減らしながらロール用ループ
      while dice_num >= @bonus_dice_range.min

        loopCount += 1
        hit_result, total, total_list = getHitResultInfos(dice_num, diff, more_difficlty)
        output += "\n#{loopCount}回目: ＞ #{total_list.join(', ')} ＞ #{hit_result}"

        if total >= broken_number
          output += "ジャム"
          return getHitResultText(output, counts)
        end

        hit_type = getHitType(more_difficlty, hit_result)
        hit_bullet, impale_bullet, lost_bullet = getBulletResults(counts[:bullet], hit_type, diff)

        counts[:hit_bullet] += hit_bullet
        counts[:impale_bullet] += impale_bullet
        counts[:bullet] -= lost_bullet

        return getHitResultText(output, counts) if counts[:bullet] <= 0

        dice_num -= 1
      end

      # 連射処理を途中で止める機能の追加
      if stop_count == "r"
        if more_difficlty == 0
          output += "\n指定の難易度となったので、処理を終了します。"
          break
        end
      elsif stop_count == "h"
        if more_difficlty == 1
          output += "\n指定の難易度となったので、処理を終了します。"
          break
        end
      elsif stop_count == "e"
        if more_difficlty == 2
          output += "\n指定の難易度となったので、処理を終了します。"
          break
        end
      end

      dice_num += 1
    end

    return getHitResultText(output, counts)
  end

  def getHitResultInfos(dice_num, diff, more_difficlty)
    units_digit = rollPercentD10
    total_list = getTotalLists(dice_num, units_digit)
    total = getTotal(total_list, dice_num)

    fumbleable = getFumbleable(more_difficlty)
    hit_result = getCheckResultText(total, diff, fumbleable)

    return hit_result, total, total_list
  end

  def getHitResultText(output, counts)
    return "#{output}\n＞ #{counts[:hit_bullet]}発が命中、#{counts[:impale_bullet]}発が貫通、残弾#{counts[:bullet]}発"
  end

  def getHitType(more_difficlty, hit_result)
    successList, impaleBulletList = getSuccessListImpaleBulletList(more_difficlty)

    return :hit if successList.include?(hit_result)
    return :impale if impaleBulletList.include?(hit_result)

    return ""
  end

  def getBulletResults(bullet_count, hit_type, diff)
    bullet_set_count = getSetOfBullet(diff)
    hit_bullet_count_base = getHitBulletCountBase(diff, bullet_set_count)
    impale_bullet_count_base = (bullet_set_count / 2.to_f)

    lost_bullet_count = 0
    hit_bullet_count = 0
    impale_bullet_count = 0

    if !isLastBulletTurn(bullet_count, bullet_set_count)

      case hit_type
      when :hit
        hit_bullet_count = hit_bullet_count_base # 通常命中した弾数の計算

      when :impale
        hit_bullet_count = impale_bullet_count_base.floor
        impale_bullet_count = impale_bullet_count_base.ceil # 貫通した弾数の計算
      end

      lost_bullet_count = bullet_set_count

    else

      case hit_type
      when :hit
        hit_bullet_count = getLastHitBulletCount(bullet_count)

      when :impale
        halfbull = bullet_count / 2.to_f

        hit_bullet_count = halfbull.floor
        impale_bullet_count = halfbull.ceil
      end

      lost_bullet_count = bullet_count
    end

    return hit_bullet_count, impale_bullet_count, lost_bullet_count
  end

  def getSuccessListImpaleBulletList(more_difficlty)
    successList = []
    impaleBulletList = []

    case more_difficlty
    when 0
      successList = ["困難な成功", "通常成功"]
      impaleBulletList = ["決定的成功", "極限の成功"]
    when 1
      successList = ["困難な成功"]
      impaleBulletList = ["決定的成功", "極限の成功"]
    when 2
      successList = []
      impaleBulletList = ["決定的成功", "極限の成功"]
    when 3
      successList = ["決定的成功"]
      impaleBulletList = []
    end

    return successList, impaleBulletList
  end

  def getNextDifficltyMessage(more_difficlty)
    case more_difficlty
    when 1
      return "\n    難易度が困難な成功に変更"
    when 2
      return "\n    難易度が極限の成功に変更"
    when 3
      return "\n    難易度が決定的成功に変更"
    end

    return ""
  end

  def getSetOfBullet(diff)
    bullet_set_count = diff / 10

    if (diff >= 1) && (diff < 10)
      bullet_set_count = 1 # 技能値が9以下での最低値保障処理
    end

    return bullet_set_count
  end

  def getHitBulletCountBase(diff, bullet_set_count)
    hit_bullet_count_base = (bullet_set_count / 2)

    if (diff >= 1) && (diff < 10)
      hit_bullet_count_base = 1 # 技能値9以下での最低値保障
    end

    return hit_bullet_count_base
  end

  def isLastBulletTurn(bullet_count, bullet_set_count)
    ((bullet_count - bullet_set_count) < 0)
  end

  def getLastHitBulletCount(bullet_count)
    # 残弾1での最低値保障処理
    if bullet_count == 1
      return 1
    end

    count = (bullet_count / 2.to_f).floor
    return count
  end

  def getFumbleable(more_difficlty)
    # 成功が49以下の出目のみとなるため、ファンブル値は上昇
    return (more_difficlty >= 1)
  end

  # 表一式
  # 即時の恐怖症表
  def BMR_table()
    tableName = "即時の狂気の発作表"
    table = [
      '最後にいた安全な場所から事件が起こった時までの出来事の記憶を失い、1D10ラウンド続く。',
      '探索者は心因性視覚障害、心因性難聴、単数あるいは複数の四肢の機能障害を1D10ラウンド受ける。',
      '敵味方を問わずに周囲へ暴力と破壊の衝動が1D10ラウンドの間向けられる。',
      '探索者は1D10ラウンドの間、深刻な被害妄想を受ける。全員それを手に入れようと思っている/誰も信頼することはできない/彼らはスパイをしている/誰かが彼らを裏切った/見ているものは何かの陰謀か策略だ。',
      '探索者の背景の「重要な人々」を参照。そのシーンにいる他の人物を自分達の重要な人物と誤認し、その人物との関係性に従って行動。1D10ラウンド持続する。',
      '探索者は気絶し、1D10ラウンド後に回復する。',
      'たとえその場にある唯一の車を使い、他の人を見捨てて行くことになったとしても、使えるものはなんでも使って、できる限り遠くに無理やり離れようとして、1D10ラウンドの間逃げようとする。',
      '探索者は1D10ラウンドの間、叫んだり、泣いたり、笑ったりして無力化される。',
      '探索者は新しい恐怖症を得る。恐怖症の原因が途中で無くなっても、1D10ラウンドの間それがそこにいると想像してしまう。恐怖症の内容は、PHコマンドで決定するか、KPが決定する。',
      '探索者は新しいマニアを得る。1D10ラウンドの間、探索者は自分の新しい偏執症に耽溺するために探し回る。マニアの内容は、MAコマンドで決定するか、KPが決定する。'
    ]
    total_n, = roll(1, 10)
    text = table[total_n - 1]
    return '1' if text.nil?

    output = "#{tableName}(#{total_n}) ＞ #{text}"

    time_n, = roll(1, 10)
    output += "(1D10＞#{time_n}ラウンド)"
    return output
  end

  # 略式の恐怖表
  def getBMS_table()
    tableName = "略式の狂気の発作表"
    table = [
      '見知らぬ場所で自分達が誰なのか記憶を無くしたことに気づく。時間の経過と共に記憶は回復する。（1D10時間）',
      '1D10時間の後、盗難に遭ったことに気づく。背景の宝物を持っていたなら幸運ロールを振る。自動的に全ての価値のあるものは失われる。',
      '1D10時間の後、自分達が打ちのめされ、傷だらけになっていることに気づく(HP半減)。ただしこれで重傷にはならないし、物も盗まれることは無い。どのような傷だったかはKPが決定する。',
      '感情を爆発させて暴力と破壊の大騒ぎをする。気づくともしかしたらその行動中の記憶が戻るかもしれない。誰や何を破壊したのか、殺したのか、または単に危害を加えたのかは、KPが決定する。（1D10時間）',
      '背景の対象について極端で狂った実証方法で表明を行う。例えば、信仰心が強い人物が、自らの教義を地下鉄で述べ伝えているところを発見される。（1D10時間）',
      '1D10時間かそれ以上後まで、探索者はその人物に近づくために何でもし、彼らとのつながりに何らかの形で影響を与える。',
      '精神科病棟や警察の牢獄で気がつく。彼らはそれから今までの出来事をゆっくりと思い出すかもしれない。（1D10時間）',
      '感覚が戻ると荒野で迷子になるか、電車や長距離バスでどこかに向かっている。（1D10時間）',
      '探索者は新しい恐怖症を得る。1D10時間後に、その恐怖症に対してあらゆる予防措置をとった状態で気がつく。恐怖症の内容は、PHコマンドで決定するか、KPが決定する。',
      '探索者は新しいマニアを得る。1D10時間後に意識がはっきりする。この発作中、探索者は新たなマニアに耽溺しているだろうが、それが他の人物にも明らかだったかどうかは、KPとPLが決定する。マニアの内容はMAコマンドで決定するか、KPが決定する。'
    ]
    total_n, = roll(1, 10)
    text = table[total_n - 1]
    return '1' if text.nil?

    output = "#{tableName}(#{total_n}) ＞ #{text}"

    time_n, = roll(1, 10)
    output += "(1D10＞#{time_n}時間)"
    return output
  end

  # 詠唱ロールのプッシュに失敗した場合（小）
  def getFCL_table()
    table = [
      '目がかすむか、一時的な失明。',
      '姿が見えない相手からの悲鳴や声や雑音など。',
      '強風やその他大気効果。',
      '呪文の使い手や他のその場にいる人物、周囲の物体（例えば壁）からの出血。',
      '奇妙なビジョンや幻覚。',
      '付近の小動物が爆ぜる。',
      '硫黄の悪臭。',
      'クトゥルフ神話の怪物が誤って召喚される。'
    ]
    return get_coc7th_1d8_table_output("詠唱ロール失敗(小)表", table)
  end

  # 詠唱ロールのプッシュに失敗した場合（大）
  def getFCM_table()
    table = [
      '大地が揺れ、壁が崩壊する。',
      '途方も無い雷や稲妻。',
      '空から血が降ってくる。',
      '呪文の使い手の手が萎びて黒こげになる。',
      '呪文の使い手が異常に老ける（+2D10歳）。',
      '強力あるいは数多くの神話の存在が現れ、呪文の使い手を最初にして、近くの全ての者を攻撃する。',
      '呪文の使い手や周囲の全員が遠くの場所や時間に吸い込まれる。',
      '神話の神が誤って招来される。'
    ]
    return get_coc7th_1d8_table_output("詠唱ロール失敗(大)表", table)
  end

  # バックグラウンド出力
  def PD_text()
    output = getPD_table()
    return output
  end

  def IB_text()
    output = getIB_table()
    return output
  end

  def SP_text()
    output = getSP_table()
    return output
  end

  def ML_text()
    output = getML_table()
    return output
  end

  def TP_text()
    output = getTP_table()
    return output
  end

  def TR_text()
    output = getTR_table()
    return output
  end

  # バックグラウンド表
  def getPD_table()
    tableName = "外的特徴"
    table = [
      '不恰好', 'ハンサム', '頑丈', '可愛らしい', '魅惑的', '童顔', '鈍い', 'だらしない', 'スマート', '汚らしい',
      'こけおどし', '本好き', '若々しい', '疲れた', 'ぷっくりしている', 'でっぷりとしている', '毛深い', 'スリム', 'エレガント', 'みすぼらしい',
      '小太り', '青白い', '不機嫌', '普通', '赤らんだ', '日焼けした', '皺のある', '古風な', '鼠のような', 'シャープ', 'たくましい',
      '華奢', '筋肉', 'がっしりとした', 'か弱い', '不器用'
    ]
    total_n, = roll(1, 36)
    text = table[total_n - 1]
    return '1' if text.nil?

    result = "#{tableName}(#{total_n}) ＞ #{text}"
    return result
  end

  def getIB_table()
    tableName = "信念/信仰"
    table = [
      'あなたには熱心な崇拝/祈りの対象があります（キリスト、ビシュヌ神）',
      '信じるものが無くてもうまくいける人種です（無神論者、ヒューマニスト、世俗主義）',
      '科学がすべてです（進化、低温学、宇宙探査）',
      '運命を信じてます（カルマ、階級制度、迷信）',
      '団体又は秘密結社のメンバーです（フリーメイソン、女性主義団体、匿名団体）',
      '根絶されるべき悪があります（薬物、暴力、人種差別）',
      'オカルト主義者です（占星術、スピリチュアリズム、タロット）',
      '政治主義（保守的、社会主義、自由主義）',
      '金が全てだ（貪欲、冷酷、守銭奴）',
      '活動家です（フェミニズム、平等の権利、組合）'
    ]
    total_n, = roll(1, 10)
    text = table[total_n - 1]
    return '1' if text.nil?

    result = "#{tableName}(#{total_n}) ＞ #{text}"
    return result
  end

  def getSP_table()
    tableAName = "重要な人物"
    tableA = [
      '親',
      '祖父母',
      '兄弟',
      '子供',
      'パートナー',
      'あなたの職業スキルを磨いた人（先生、師匠、父）',
      '子供のころの友（同級生、幼馴染、頭の中の友）',
      '有名人（アイドル、ヒーロー、映画スター、政治家、音楽家）',
      '探索者の一人（ランダム又は任意に1人選ぶ）',
      'ゲームでのＮＰＣ（ＫＰに聞き、一人を選ぶ）'
    ]
    totalA_n, = roll(1, 10)
    textA = tableA[totalA_n - 1]
    return '1' if textA.nil?

    tableBName = "その人物とどのような関係か"
    tableB = [
      'あなたはその人物に恩義がある',
      'その人物はあなたに何かを教えてくれた',
      'その人物はあなたの人生の意味である',
      'あなたは不当な扱いをし和解を求めている（盗み、警察の事情聴取）',
      'ある体験を共有した（戦争、少年期、辛い時）',
      'あなたはその人物に自分自身を証明しようとしている（バイトによって、配偶者を見つけることによって）',
      'あなたはその人物に心酔している（名声、美しさ、思想）',
      '後悔の気持ちがある（死なせてしまった、助けてあげられなかった、見なかった不利をした）',
      'あなたはその人物に良い人間と言うことをということを証明したい（怠惰な人なので、酒飲みであるので、愛情を表に出さないので）',
      'あなたはその人物に酷いことをされ、復讐をのぞんでいる（愛する人の死、破産、離婚）'
    ]
    totalB_n, = roll(1, 10)
    textB = tableB[totalB_n - 1]
    return '1' if textB.nil?

    result = "#{tableAName}(#{totalA_n}) ＞ #{textA}\n"
    result += "#{tableBName}(#{totalB_n}) ＞ #{textB}"
    return result
  end

  def getML_table()
    tableName = "意味のある場所"
    table = [
      '学習場所（大学、学校）',
      'あなたの故郷',
      'あなたが初めて愛に出合った場所（音楽コンサート、休日、シェルター）',
      '静かに熟考できる場所（図書館、釣り）',
      '社交の場（紳士クラブ、バー、伯父の家）',
      'あなたの信念と繋がれる場所（教会、メッカ）',
      '重要な人物の墓（母、子供、恋人）',
      'あなたの実家（田舎の家、孤児院）',
      '人生で一番幸せだった場所（初めてのキスの場所、大学）',
      'あなたの職場（オフィス、図書館、銀行）'
    ]
    total_n, = roll(1, 10)
    text = table[total_n - 1]
    return '1' if text.nil?

    result = "#{tableName}(#{total_n}) ＞ #{text}"
    return result
  end

  def getTP_table()
    tableName = "宝物"
    table = [
      'あなたの一番高い技能に関係有るもの',
      '職業に不可欠な品',
      '子供の頃からの記念品（ポケットナイフ、漫画、ラッキーコイン）',
      '死んだ人の形見（宝石、手紙、写真）',
      '大切な人にもらった何か（指輪、日記）',
      'コレクション',
      'あなたが見つけた不明の品（書斎で見つけた未知の言語、よく分からない物体）',
      'スポーツアイテム',
      '武器',
      'ペット'
    ]
    total_n, = roll(1, 10)
    text = table[total_n - 1]
    return '1' if text.nil?

    result = "#{tableName}(#{total_n}) ＞ #{text}"
    return result
  end

  def getTR_table()
    tableName = "内的特徴"
    table = [
      '寛大（慈善家）',
      '動物愛好家',
      '夢見がち（空想、想像力豊か）',
      '快楽主義者',
      'ギャンブラー、危険を求める',
      '料理が上手',
      '魅惑的',
      '忠実',
      '良い評判（勇敢、名スピーチ）',
      '野心的'
    ]
    total_n, = roll(1, 10)
    text = table[total_n - 1]
    return '1' if text.nil?

    result = "#{tableName}(#{total_n}) ＞ #{text}"
    return result
  end

  def getAllBG_text()
    output = ""
    pd = getPD_table()
    ib = getIB_table()
    sp = getSP_table()
    ml = getML_table()
    tp = getTP_table()
    tr = getTR_table()
    output = "\n#{pd}\n#{ib}\n#{sp}\n#{ml}\n#{tp}\n#{tr}"
    return output
  end

  # 恐怖症表
  def getPH_table()
    table = [
      'Ablutophobia　洗浄恐怖症:洗濯や風呂への恐怖。',
      'Acrophobia　高所恐怖症:高さへの恐怖。',
      'Aerophobia　空気恐怖症:浮遊物などへの恐怖。',
      'Agoraphobia　広場恐怖症:開けた、公共の（混雑した）場所への恐怖。',
      'Alektorophobia　ニワトリ恐怖症:ニワトリへの恐怖。',
      'Alliumphobia　ニンニク恐怖症:ニンニクへの恐怖。',
      'Amaxophobia　乗り物恐怖症:乗り物への恐怖。',
      'Ancraophobia　風恐怖症:風への恐怖。',
      'Androphobia　男性恐怖症:男性への恐怖。',
      'Anglophobia　イギリス恐怖症:イギリスや英語文化などへの恐怖。',
      'Anthophobia　花恐怖症:花への恐怖。',
      'Apotemnophobia　切断恐怖症:四肢が切断されていることへの恐怖。',
      'Arachnophobia　蜘蛛恐怖症:蜘蛛への恐怖。',
      'Astraphobia　雷恐怖症:雷への恐怖。',
      'Atephobia　破滅恐怖症:遺跡や滅びたものに対する恐怖。',
      'Aulophobia　笛声恐怖症:笛の音への恐怖。',
      'Bacteriophobia　細菌恐怖症:バクテリアなどの細菌への恐怖。',
      'Ballistophobia　弾丸恐怖症:飛び道具や弾丸への恐怖。',
      'Basophobia　歩行恐怖症:転ぶことへの恐怖。',
      'Bibliophobia　本恐怖症:本への恐怖。',
      'Botanophobia　植物恐怖症:植物への恐怖。',
      'Caligynephobia　美女恐怖症:美女への恐怖。',
      'Cheimaphobia　寒冷恐怖症:寒さへの恐怖。',
      'Chronomentrophobia　時計恐怖症:時計への恐怖。',
      'Claustrophobia　閉所恐怖症:狭い場所への恐怖。',
      'Coulrophobia　ピエロ恐怖症:ピエロへの恐怖。',
      'Cynophobia　犬恐怖症:犬への恐怖。',
      'Demonophobia　悪魔恐怖症:精霊や悪魔への恐怖。',
      'Demophobia　群集恐怖症:群集への恐怖。',
      'Dentophobia　歯科恐怖症:歯の治療に対する恐怖。',
      'Disposophobia　廃棄恐怖症:物を捨てることへの恐怖（溜める）。',
      'Doraphobia　毛皮恐怖症:毛皮への恐怖。',
      'Dromophobia　道路横断恐怖症:道路を横断することへの恐怖。',
      'Ecclesiophobia　教会恐怖症:教会への恐怖。',
      'Eisoptrophobia　鏡恐怖症:鏡への恐怖。',
      'Enetophobia　ピン恐怖症:ピンや針に対する恐怖。',
      'Entomophobia　昆虫恐怖症:昆虫への恐怖。',
      'Felinophobia　猫恐怖症:猫への恐怖。',
      'Gephyrophobia　渡橋恐怖症:交差している橋への恐怖。',
      'Gerontophobia　老人恐怖症:老いや老人への恐怖。',
      'Gynophobia　女性恐怖症:女性への恐怖。',
      'Haemaphobia　血液恐怖症:血液に対する恐怖。',
      'Hamartophobia　失敗恐怖症:失敗による罪への恐怖。',
      'Haphophobia　接触恐怖症:触られることへの恐怖。',
      'Herpetophobia　爬虫両生類恐怖症:爬虫類への恐怖。',
      'Homichlophobia　霧恐怖症:霧への恐怖。',
      'Hoplophobia　銃器恐怖症:銃器への恐怖。',
      'Hydrophobia　水恐怖症:水への恐怖。',
      'Hypnophobia　睡眠恐怖症。:睡眠や催眠に対する恐怖。',
      'Iatrophobia　医者恐怖症:医者への恐怖。',
      'Ichthyophobia　魚恐怖症:魚への恐怖。',
      'Katsaridaphobia　ゴキブリ恐怖症:ゴキブリへの恐怖。',
      'Keraunophobia　雷鳴恐怖症:雷鳴への恐怖。',
      'Lachanophobia　野菜恐怖症:野菜への恐怖。',
      'Ligyrophobia　大騒音恐怖症:大騒音への恐怖。',
      'Limnophobia　湖恐怖症:湖への恐怖。',
      'Mechanophobia　機械恐怖症:機械への恐怖。',
      'Megalophobia　巨大物恐怖症:巨大なものへの恐怖。',
      'Merinthophobia　拘束恐怖症:拘束されたり、縛られたりすることへの恐怖。',
      'Meteorophobia　隕石恐怖症:流星や隕石への恐怖。',
      'Monophobia　孤独恐怖症:孤独への恐怖。',
      'Mysophobia　汚染恐怖症:汚れや汚染への恐怖。',
      'Myxophobia　粘液恐怖症:粘液への恐怖。',
      'Necrophobia　死亡恐怖症:死んだものに対する恐怖。',
      'Octophobia8恐　怖症:8という形への恐怖。',
      'Odontophobia　歯欠損恐怖症:歯に対する恐怖症。',
      'Oneirophobia　夢恐怖症:夢への恐怖。',
      'Onomatophobia　名称恐怖症:特定の単語や言葉に対する恐怖。',
      'Ophidiophobia　ヘビ恐怖症:ヘビへの恐怖。',
      'Ornithophobia　鳥恐怖症:鳥への恐怖。',
      'Parasitophobia　寄生生物恐怖症:寄生生物への恐怖。',
      'Pediophobia　人形恐怖症:人形に対する恐怖。',
      'Phagophobia　食事恐怖症:飲むことや食べることに対する恐怖。',
      'Pharmacophobia　薬物恐怖症:薬物に対する恐怖。',
      'Phasmophobia　幽霊恐怖症:幽霊への恐怖。',
      'Phenogophobia　日光恐怖症:日光への恐怖。',
      'Pogonophobia　髭そり恐怖症:髭に対する恐怖。',
      'Potamophobia　河川恐怖症:河川への恐怖。',
      'Potophobia　アルコール恐怖症:アルコールやアルコール飲料に対する恐怖。',
      'Pyrophobia　火恐怖症:火への恐怖。',
      'Rhabdophobia　魔術恐怖症:魔術への恐怖。',
      'Scotophobia　暗黒恐怖症:夜や暗黒への恐怖。',
      'Selenophobia　月恐怖症:月への恐怖。',
      'Siderodromophobia　鉄道恐怖症:鉄道旅行への恐怖。',
      'Siderophobia　星恐怖症:星への恐怖。',
      'Stenophobia　狭所恐怖症:狭いものや場所への恐怖。',
      'Symmetrophobia　対称恐怖症:対象性のあるものに対する恐怖。',
      'Taphephobia　生き埋め恐怖症:生きたまま埋められるか、墓地に埋葬されることへの恐怖。',
      'Taurophobia　雄牛恐怖症:雄牛への恐怖。',
      'Telephonophobia　電話恐怖症:電話への恐怖。',
      'Teratophobia　奇形恐怖症:モンスターへの恐怖。',
      'Thalassophobia　海洋恐怖症:海への恐怖。',
      'Tomophobia　手術恐怖症:外科手術に対する恐怖。',
      'Triskadekaphobia13　恐怖症:13に対する恐怖。',
      'Vestiphobia　衣類恐怖症:衣服への恐怖。',
      'Wiccaphobia　魔女恐怖症:魔女や魔術に対する恐怖。',
      'Xanthophobia　黄色恐怖症:黄色や黄色という言葉への恐怖。',
      'Xenoglossophobia　外国語恐怖症:外国の言語への恐怖。',
      'Xenophobia　外国人恐怖症:見知らぬ人物や外人に対する恐怖。',
      'Zoophobia　動物恐怖症:動物への恐怖。'
    ]
    return get_coc7th_1d100_table_output("恐怖症表", table)
  end

  # マニア表
  def getMA_table()
    table = [
      'Ablutomania　洗浄狂：自分自身を洗うことへの強迫。',
      'Aboulomania　優柔不断狂：病的な決断力の無さ。',
      'Achluomania　暗闇狂：過度に暗闇を好む。',
      'Acromania　高所狂：高所への強迫。',
      'Agathomania　善良狂：病的な優しさ。',
      'Agromania　田園狂：開けた場所にいたいという強い願望。',
      'Aichmomania　先端狂：鋭いあるいは尖った物への強迫観念。',
      'Ailuromania　猫狂：猫への異常な愛情。',
      'Algomania　痛み狂：痛みへの強迫観念。',
      'Alliomania　ニンニク狂：ニンニクへの執着。',
      'Amaxomania　車狂：車に乗っていることへの執着。',
      'Amenomania　快活狂：不合理な陽気。',
      'Anthomania　花狂：花への執着。',
      'Arithmomania　計算狂：数字への執拗なこだわり。',
      'Asoticamania　浪費狂：衝動的なあるいは無謀な消費。',
      'Automania　孤独狂：過度に孤独を好む。',
      'Balletomania　バレエ狂：バレエへの異常な愛情。',
      'Bibliokleptomania　書籍窃盗狂：本を盗むことへの強迫。',
      'Bibliomania　書籍狂：本や読書への執着。',
      'Bruxomania　歯軋り狂：歯軋りへの強迫。',
      'Cacodemomania　憑依狂信症：悪霊に憑依されているという病的に信じる。',
      'Callomania　優美狂：自分自身の美しさへの執着。',
      'Cartacoethes　地図狂：どこでも地図を見ることへの抑えがたい欲求。',
      'Catapedamania　跳躍狂：高所からジャンプすることへの強迫観念。',
      'Cheimatomania　冷感狂：冷たい状態や冷たいものへの異常な欲望。',
      'Choreomania　舞踏狂：踊ることへの執着または抑えがたい激高。',
      'Clinomania　寝床狂：ベッドの中にとどまることへの過度な欲求。',
      'Coimetromania　墓地狂：墓地への執着。',
      'Coloromania　色狂：特定の色への執着。',
      'Coulromania　ピエロ狂：道化師への執着。',
      'Countermania　反撃狂：恐ろしい状況を経験することへの衝動強迫。',
      'Dacnomania　殺害狂：殺すことへの執着。',
      'Demonomania　悪魔憑依狂：悪魔に憑依されていることを病的に信じる。',
      'Dermatillomania　皮膚むしり狂：自分の皮膚を剥くことへの衝動強迫。',
      'Dikemania　正義狂：正義が成されるのを見ることへの執着。',
      'Dipsomania　アルコール依存症：アルコールを異常に渇望する。',
      'Doramania　毛皮狂：毛皮を持つことへの執着。',
      'Doromania　贈与狂：贈り物を与えることへの執着。',
      'Drapetomania　逃亡奴隷精神病：逃げることへの執着。',
      'Ecdemiomania　驚愕症：驚くことへの執着。',
      'Egomania　自己中心狂：不合理な自己中心の態度や自己崇拝。',
      'Empleomania　役職狂：役職に就くことへの貪欲な衝動。',
      'Enosimania　罪悪狂：罪を犯したのではないかと病的に信じる。',
      'Epistemomania　知識取得狂：知識を獲得することへの執着。',
      'Eremiomania　静寂狂：静かであることへの強迫観念。',
      'Etheromania　エーテル狂：ジエチルエーテルの欲求。',
      'Gamomania　求婚狂：奇妙な求婚をすることへの執着。',
      'Geliomania　笑顔狂：制御できない笑う衝動。',
      'Goetomania　魔術狂：魔女や魔術への執着。',
      'Graphomania　書字狂：何でも書き留めることへの執着。',
      'Gymnomania　裸狂：裸への執着。',
      'Habromania　欣快狂：（現実にもかかわらず）心地のよい妄想を生み出す異常な傾向。',
      'Helminthomania　ぜん虫狂：ワームへの過剰な嗜好。',
      'Hoplomania　銃器狂：銃器への執着。',
      'Hydromania　水狂：水への不合理な渇望。',
      'Ichthyomania　魚狂：魚への執着。',
      'Iconomania　肖像狂：肖像や肖像画への執着。',
      'Idolomania　偶像狂：偶像への執着または偶像への献身。',
      'Infomania　情報狂：事実を蓄積することの極端な情熱。',
      'Klazomania　絶叫狂：大声で叫ぶことへの不合理な衝動。',
      'Kleptomania　窃盗狂：窃盗することへの不合理な衝動。',
      'Ligyromania　騒音狂：騒がしくて騒々しい騒音を出すことへの制御不能な衝動。',
      'Linonomania　弦狂：弦への執着。',
      'Lotterymania　宝くじ狂：宝くじに参加することの極端な欲望。',
      'Lypemania　憂鬱狂：深い憂鬱に向かう異常な傾向。',
      'Megalithomania　巨石狂：石の円や立石の存在下で奇妙なアイデアを思いつく異常な傾向。',
      'Melomania　音楽狂：音楽や特定の調べへの執着。',
      'Metromania　作詞狂：詩を書くことへの貪欲な欲望。',
      'Misomania　憎悪狂：全てを憎しみ、なんらかの主題またはグループを嫌うことの強迫観念。',
      'Monomania　単一思考狂：単一の思考やアイディアへの異常な強迫観念。',
      'Mythomania　虚言狂：異常なほどに嘘や誇張をする。',
      'Nosomania　病気妄想狂：想像上の病気に苦しんでいるという妄想。',
      'Notomania　記録狂：すべてを記録するという強迫観念（写真など）。',
      'Onomamania　名前狂：名前への執着（人、場所、もの）。',
      'Onomatomania　言葉狂：特定の言葉を繰り返すことへの抵抗できない欲求。',
      'Onychotillomania　爪むしり狂：自分の爪を摘むことへの強迫観念。',
      'Opsomania　美食狂：1種類の食べ物に対する異常な愛。',
      'Paramania　不平狂：文句を言うことを異常に好む。',
      'Personamania　ペルソナ狂：仮面をかぶることの強迫衝動。',
      'Phasmomania　幽霊狂：幽霊への執着。',
      'Phonomania　殺人狂：病的に殺人する傾向。',
      'Photomania　光狂：光への病的欲求。',
      'Planomania　放浪狂：社会的規範に反することへの異常な欲求。',
      'Plutomania　裕福狂：富への強い欲求。',
      'Pseudomania　虚狂：嘘をつくことへの不合理な衝動。',
      'Pyromania　放火狂：火つけることへの衝動。',
      'Question-Asking Mania　質問狂：質問せずにはいられない衝動。',
      'Rhinotillexomania　鼻ほじり狂：強迫的な鼻ほじり。',
      'Scribbleomania　落書き狂：落書きやいたずら書きへの執着。',
      'Siderodromomania　列車狂：列車や鉄道の旅への強烈な魅了状態。',
      'Sophomania　知的妄想狂：自分が信じられないほど知的だという妄想。',
      'Technomania　新技術狂：新技術への執着。',
      'Thanatomania　死の運命狂：自分が死の魔術によって呪われていると信じている。',
      'Theomania　神妄想狂：自分は神であると信じている。',
      'Titillomania　掻き毟り狂：自分自身を掻くことへの強迫衝動。',
      'Tomomania　手術狂：手術を行うことへの不合理な嗜好。',
      'Trichotillomania　抜毛狂：自分の髪を抜くことへの欲求。',
      'Typhlomania　盲目狂：病的な盲目。',
      'Xenomania　異文化狂：外国の物への執着。',
      'Zoomania　動物狂：動物への常軌を逸した愛好。'
    ]
    return get_coc7th_1d100_table_output("マニア表", table)
  end

  # 職業ランダム
  def getOccupation_table(characteristics, rule)
    tableName = "職業ランダム"
    table_K = [
      ['Antiquarian [Lovecraftian](考古学者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Artist(芸術家)', '：職業技能ポイント EDU×2+POWかDEX×2', 'POW', 'DEX'],
      ['Author [Lovecraftian](作家)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Clergy(聖職者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Criminal(犯罪者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Dilettante [Lovecraftian](ディレッタント)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Doctor of Medicine [Lovecraftian](医師)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Drifter(放浪者)', '：職業技能ポイント EDU×2+APPかDEXかSTR×2', 'APP', 'DEX', 'STR'],
      ['Engineer(エンジニア)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Entertainer(エンターテイナー)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Farmer(農林業作業者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Hacker [Modern](ハッカー)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Journalist [Lovecraftian](ジャーナリスト)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Lawyer(弁護士)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Librarian [Lovecraftian](図書館司書)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Military Officer(軍士官)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Missonary(伝道者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Musician(ミュージシャン)', '：職業技能ポイント EDU×2+DEXかPOW×2', 'DEX', 'POW'],
      ['Parapsychologist(超心理学者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Pilot(パイロット)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Police Detective [Lovecraftian](刑事)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Police Officer(警官)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Private Investigator(私立探偵)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Professor [Lovecraftian](教授)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Soldier(兵士)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Tribe Member(トライブ・メンバー)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Zealot(狂信者)', '：職業技能ポイント EDU×2+APPかPOW×2', 'APP', 'POW']
    ]
    table_I = [
      ['Accountant(会計士)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Acrobat(アクロバット)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Agency Detective(探偵社)', '：職業技能ポイント EDU×2+STRかDEX×2', 'STR', 'DEX'],
      ['Alienist [Classic](精神科医)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Animal Trainer(動物調教師)', '：職業技能ポイント EDU×2+APPかPOW×2', 'APP', 'POW'],
      ['Antiquarian [Lovecraftian](古物研究家)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Antique Dealer(アンティークディーラー)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Archaeologist [Lovecraftian](考古学者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Architect(建築家)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Artist(芸術家)', '：職業技能ポイント EDU×2+DEXかPOW×2', 'DEX', 'POW'],
      ['Assassin – see Criminal(暗殺者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Asylum Attendant(精神病院係員)', '：職業技能ポイント EDU×2+STRかDEX×2', 'STR', 'DEX'],
      ['Athlete(スポーツ選手)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Author [Lovecraftian](作家)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Aviator [Classic] – see Pilot(飛行家)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Bank Robber – see Criminal(銀行強盗)', '：職業技能ポイント EDU×2+STRかDEX×2', 'STR', 'DEX'],
      ['Bartender(バーテンダー)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Big Game Hunter(ビッグゲームハンター)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Book Dealer(書籍販売店)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Bootlegger/Thug – see Criminal(酒密造者)', '：職業技能ポイント EDU×2+STR×2', 'STR'],
      ['Bounty Hunter(賞金稼ぎ)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Boxer/Wrestler(ボクサー/レスラー)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Burglar – see Criminal(押し込み強盗)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Butler/Valet/Maid(執事/従者/メイド)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Chauffeur – see Driver(運転手)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Clergy, Member of the(聖職者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Clerk/Executive - see White-collar Worker(サラリーマン/公務員)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Computer Programmer/Technician [Modern](コンピュータプログラマー/技術者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Conman – see Criminal(詐欺師)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Cowboy/girl(カウボーイ/カウガール)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Craftsperson(職人)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Criminal(freelance/solo) – also Gangster(犯罪者（フリーランス/ソロ）)', '：職業技能ポイント EDU×2+DEXかAPP×2', 'DEX', 'APP'],
      ['Cult Leader(カルトリーダー)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Deprogrammer [Modern](洗脳解除療法専門家 )', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Designer(デザイナー)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Dilettante [Lovecraftian](ディレッタント)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Diver(ダイバー)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Doctor of Medicine [Lovecraftian] – also see Psychiatrist(医師)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Drifter(放浪者)', '：職業技能ポイント EDU×2+APPかDEXかSTR×2', 'APP', 'DEX', 'STR'],
      ['Driver(ドライバー)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Editor(編集者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Elected Official(議員)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Engineer(エンジニア)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Entertainer(エンターテイナー)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Explorer [Classic](探検家)', '：職業技能ポイント EDU×2+APPかSTRかDEX×2', 'APP', 'STR', 'DEX'],
      ['Farmer(農林業作業者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Federal Agent(連邦捜査官)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Fence – see Criminal(盗品故買者)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Film Star – see Actor(映画スター)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Firefighter(消防士)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Foreign Correspondent(海外特派員)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Forensic Surgeon(法医学医)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Forger/Counterfeiter – see Criminal(偽造者/贋造者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Gambler(ギャンブラー)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Gangster Boss(ギャングのボス)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Gangster Underling(ギャングの手下)', '：職業技能ポイント EDU×2+STR×2', 'STR'],
      ['Gentleman/Lady(紳士/婦人)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Gun Moll [Classic] – see Criminal(ギャングの情婦)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Hacker – see Computer Programmer [Modern](ハッカー)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Hobo(渡り労働者)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Hospital Orderly(病院の用務係)', '：職業技能ポイント EDU×2+STR×2', 'STR'],
      ['Investigative Journalist -see Journalist [Lovecraftian](ジャーナリスト)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Judge(裁判官)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Laboratory Assistant(研究のアシスタント)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Laborer(労働者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Lawyer(弁護士)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Librarian [Lovecraftian](図書館司書)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Lumberjack – see Laborer(樵)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Mechanic (and Skilled Trades)(職工)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Middle/Senior Manager - see White-collar Worker(中間管理職/上級管理職)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Military Officer(軍士官)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Miner – see Laborer(鉱夫)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Missionary(伝道者)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Mountain Climber(登山者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Museum Curator(博物館のキュレーター)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Musician(ミュージシャン)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Nurse(ナース)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Occultist [Lovecraftian](オカルティスト)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Outdoorsman/woman(野外活動愛好家)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Parapsychologist(超心理学者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Pharmacist(薬剤師)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Photographer(写真家)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Photojournalist – see Photographer(フォトジャーナリスト)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Pilot(パイロット)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Police Detective [Lovecraftian](刑事)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Police Officer(警官)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Private Investigator(私立探偵)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Professor [Lovecraftian](教授)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Prospector(試掘者)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Prostitute(売春婦)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Psychiatrist(精神科医)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Psychologist/Psychoanalyst(心理学者/精神分析者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Reporter – see Journalist(レポーター)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Researcher(研究員)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Sailor, Commerical(商船船員)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Sailor, Naval(海軍船員)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Salesperson(営業担当者)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Scientist(科学者)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Secretary(秘書)', '：職業技能ポイント EDU×2+DEXかAPP×2', 'DEX', 'APP'],
      ['Shopkeeper(店主)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Smuggler – see Criminal(密輸業者)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Soldier/Marine(兵士/海兵)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Spy(スパイ)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Stage Actor – see Actor(舞台役者)', '：職業技能ポイント EDU×2+APP×2', 'APP'],
      ['Street Punk – see Criminal(ストリートパンク)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Student/Intern(学生/インターン)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Stuntman(スタントマン)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Taxi Driver – see Driver(タクシードライバー)', '：職業技能ポイント EDU×2+DEX×2', 'DEX'],
      ['Tribe Member(トライブ・メンバー)', '：職業技能ポイント EDU×2+DEXかSTR×2', 'DEX', 'STR'],
      ['Undertaker(葬儀屋)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Union Activist(組合活動家)', '：職業技能ポイント EDU×2+EDU×2', 'EDU'],
      ['Waitress/Waiter(ウェイトレス/ウェイター)', '：職業技能ポイント EDU×2+APPかDEX×2', 'APP', 'DEX'],
      ['Zealot(狂信者)', '：職業技能ポイント EDU×2+APPかPOW×2', 'APP', 'POW'],
      ['Zookeeper(動物園職員)', '：職業技能ポイント EDU×2+EDU×2', 'EDU']
    ]
    # rule = 0:探索者ブックから職業ランダム、1：探索者ブックから現代を除いた職業ランダム、2：KPルールブックから職業ランダム、3：KPルールブックから現代を除いた職業ランダム
    # 現代職業を抜いた場合の処理を行うのはrule = 1の場合のみなので、rule = 3の場合のみ表を選択した後に値を変更
    if (rule == 2) || (rule == 3)
      table = table_K
      if rule == 3
        rule = 1
      end
    elsif (rule == 0) || (rule == 1)
      table = table_I
    end

    if characteristics == ""
      number = table
    elsif characteristics == "str"
      number = table.select { |x| x[2] == 'STR' }
      number += table.select { |x| x[3] == 'STR' }
      number += table.select { |x| x[4] == 'STR' }
    elsif characteristics == "edu"
      number = table.select { |x| x[2] == 'EDU' }
      number += table.select { |x| x[3] == 'EDU' }
      number += table.select { |x| x[4] == 'EDU' }
    elsif characteristics == "dex"
      number = table.select { |x| x[2] == 'DEX' }
      number += table.select { |x| x[3] == 'DEX' }
      number += table.select { |x| x[4] == 'DEX' }
    elsif characteristics == "app"
      number = table.select { |x| x[2] == 'APP' }
      number += table.select { |x| x[3] == 'APP' }
      number += table.select { |x| x[4] == 'APP' }
    elsif characteristics == "pow"
      number = table.select { |x| x[2] == 'POW' }
      number += table.select { |x| x[3] == 'POW' }
      number += table.select { |x| x[4] == 'POW' }
    else
      number = ['Error(エラー)', '：職業技能ポイント EDU×2+null×2', '']
    end

    # 現代職業を抜いたクラッシック職業ランダム化処理
    if rule == 1
      number = number.reject { |a| a[0].include?("Modern") }
    end

    choice_table = number.sample

    occupation_name = choice_table[0]
    occupation_sub = choice_table[1]
    return '1' if occupation_name.nil?

    output = "#{tableName} ＞ #{occupation_name}#{occupation_sub}"

    occupation_characteristics_A = choice_table[2]
    occupation_characteristics_B = choice_table[3]
    occupation_characteristics_C = choice_table[4]
    return '1' if occupation_name.nil?

    return output, occupation_name, occupation_characteristics_A, occupation_characteristics_B, occupation_characteristics_C
  end

  def Occupation_text(command)
    rule = 2
    # rule = 0:探索者ブックから職業ランダム、1：探索者ブックから現代を除いた職業ランダム、2：KPルールブックから職業ランダム、3：KPルールブックから現代を除いた職業ランダム
    if /^KOC\((edu|str|dex|app|pow)\)/i =~ command
      characteristics = Regexp.last_match(1).to_s.downcase
      rule = 3
    elsif /^KO\((edu|str|dex|app|pow)\)/i =~ command
      characteristics = Regexp.last_match(1).to_s.downcase
      rule = 2
    elsif /^KOC/i =~ command
      characteristics = ""
      rule = 3
    elsif /^KO/i =~ command
      characteristics = ""
      rule = 2
    elsif /^IOC\((edu|str|dex|app|pow)\)/i =~ command
      characteristics = Regexp.last_match(1).to_s.downcase
      rule = 1
    elsif /^IO\((edu|str|dex|app|pow)\)/i =~ command
      characteristics = Regexp.last_match(1).to_s.downcase
      rule = 0
    elsif /^IOC/i =~ command
      characteristics = ""
      rule = 1
    elsif /^IO/i =~ command
      characteristics = ""
      rule = 0
    end

    output = getOccupation_table(characteristics, rule)
    return output[0]
  end

  def MaleNames_text()
    output = getMaleNames_table()
    return output[0]
  end

  def FemaleNames_text()
    output = getFemaleNames_table()
    return output[0]
  end

  def RandomNames_text()
    output = getRandomNames_table()
    return output[0]
  end

  def getMaleNames_table()
    tableName = "名前ランダム作成（男）"
    table = [
      'Aaron',
      'Abraham',
      'Addison',
      'Amos',
      'Anderson',
      'Archibald',
      'August',
      'Barnabas',
      'Barney',
      'Baxter',
      'Blair',
      'Caleb',
      'Cecil',
      'Chester',
      'Clifford',
      'Clinton',
      'Cornelius',
      'Curtis',
      'Dayton',
      'Delbert',
      'Douglas',
      'Dudley',
      'Ernest',
      'Eldridge',
      'Elijah',
      'Emanuel',
      'Emmet',
      'Enoch',
      'Ephraim',
      'Everett',
      'Ezekiel',
      'Forest',
      'Gilbert',
      'Granville',
      'Gustaf',
      'Hampton',
      'Harmon',
      'Henderson',
      'Herman',
      'Hilliard',
      'Howard',
      'Hudson',
      'Irvin',
      'Issac',
      'Jackson',
      'Jacob',
      'Jeremiah',
      'Jonah',
      'Josiah',
      'Kirk',
      'Larkin',
      'Leland',
      'Leopold',
      'Lloyd',
      'Luther',
      'Manford',
      'Marcellus',
      'Martin',
      'Mason',
      'Maurice',
      'Maynard',
      'Melvin',
      'Miles',
      'Milton',
      'Morgan',
      'Mortimer',
      'Moses',
      'Napoleon',
      'Nelson',
      'Newton',
      'Noble',
      'Oliver',
      'Orson',
      'Oswald',
      'Pablo',
      'Percival',
      'Porter',
      'Quincy',
      'Randall',
      'Reginald',
      'Richmond',
      'Rodney',
      'Roscoe',
      'Rowland',
      'Rupert',
      'Sampson',
      'Sanford',
      'Sebastian',
      'Shelby',
      'Sidney',
      'Solomon',
      'Squire',
      'Sterling',
      'Sidney',
      'Thaddeus',
      'Walter',
      'Wilbur',
      'Wilfred',
      'Zadok',
      'Zebedee'
    ]
    total_n, = roll(1, 100)
    firstname = table[total_n - 1]
    return '1' if firstname.nil?

    surname = getLastName_table()
    sex = "男"
    output = "#{tableName} ＞ #{firstname} #{surname}"
    return output, firstname, surname, sex
  end

  def getFemaleNames_table()
    tableName = "名前ランダム作成（女）"
    table = [
      'Adele',
      'Agatha',
      'Agnes',
      'Albertina',
      'Almeda',
      'Amelia',
      'Anastasia',
      'Annabelle',
      'Asenath',
      'Augusta',
      'Barbara',
      'Bernadette',
      'Bernice',
      'Beryl',
      'Beulah',
      'Camilla',
      'Carmen',
      'Caroline',
      'Cecilia',
      'Celeste',
      'Charity',
      'Christina',
      'Clarissa',
      'Claudia',
      'Constance',
      'Cordelia',
      'Cynthia',
      'Daisy',
      'Dolores',
      'Doris',
      'Edith',
      'Edna',
      'Eloise',
      'Elsie',
      'Estelle',
      'Ethel',
      'Eudora',
      'Eugenie',
      'Eunice',
      'Florence',
      'Frieda',
      'Genevieve',
      'Gertrude',
      'Gladys',
      'Gretchen',
      'Hannah',
      'Henrietta',
      'Hoshea',
      'Ingrid',
      'Irene',
      'Iris',
      'Ivy',
      'Jeanette',
      'Jezebel',
      'Josephine',
      'Joyce',
      'Juanita',
      'Keziah',
      'Laverne',
      'Leonora',
      'Letitia',
      'Loretta',
      'Lucretia',
      'Mabel',
      'Madeleine',
      'Margery',
      'Marguerite',
      'Marjorie',
      'Matilda',
      'Melinda',
      'Melissa',
      'Mercedes',
      'Mildred',
      'Millicent',
      'Muriel',
      'Myrtle',
      'Naomi',
      'Nora',
      'Octavia',
      'Ophelia',
      'Pansy',
      'Patience',
      'Pearle',
      'Phoebe',
      'Phyllis',
      'Rosemary',
      'Ruby',
      'Sadie',
      'Selina',
      'Selma',
      'Sibyl',
      'Sylvia',
      'Tabitha',
      'Ursula',
      'Veronica',
      'Violet',
      'Virginia',
      'Wanda',
      'Wilhelmina',
      'Winifred'
    ]
    total_n, = roll(1, 100)
    firstname = table[total_n - 1]
    return '1' if firstname.nil?

    surname = getLastName_table()
    sex = "女"
    output = "#{tableName} ＞ #{firstname} #{surname}"
    return output, firstname, surname, sex
  end

  def getRandomNames_table()
    total_n, = roll(1, 2)
    if total_n == 1
      output = getMaleNames_table()
    elsif total_n == 2
      output = getFemaleNames_table()
    else
      output = "error"
    end
    return output[0], output[1], output[2], output[3]
  end

  def getLastName_table()
    table = [
      'Abraham',
      'Adler',
      'Ankins',
      'Avery',
      'Barnham',
      'Bentz',
      'Bessler',
      'Blakely',
      'Bleeker',
      'Bouche',
      'Bretz',
      'Brock',
      'Buchman',
      'Butts',
      'Caffey',
      'Click',
      'Cordova',
      'Crabtree',
      'Crankovitch',
      'Cuthburt',
      'Cuttling',
      'Dorman',
      'Eakley',
      'Eddie',
      'Elsner',
      'Fandrick',
      'Farwell',
      'Feigel',
      'Felten',
      'Fenske',
      'Fillman',
      'Finley',
      'Firske',
      'Flanagan',
      'Franklin',
      'Freeman',
      'Frisbe',
      'Gore',
      'Greenwald',
      'Hahn',
      'Hammermeister',
      'Heminger',
      'Hogue',
      'Hollister',
      'Kasper',
      'Kisro',
      'Kleeman',
      'Lake',
      'Levard',
      'Lockhart',
      'Luckstrim',
      'Lynch',
      'Madison',
      'Mantei',
      'Marsh',
      'McBurney',
      'McCarney',
      'Moses',
      'Nickels',
      'O\'Neil',
      'Olson',
      'Ozanich',
      'Patterson',
      'Patzer',
      'Peppin',
      'Porter',
      'Posch',
      'Raslo',
      'Razner',
      'Rifenberg',
      'Riley',
      'Ripley',
      'Rossini',
      'Schiltgan',
      'Schmidt',
      'Schroeder',
      'Schwartz',
      'Shane',
      'Shattuck',
      'Shea',
      'Slaughter',
      'Smith',
      'Speltzer',
      'Stimac',
      'Strenburg',
      'Strong',
      'Swanson',
      'Tillinghast',
      'Traver',
      'Urton',
      'Vallier',
      'Wagner',
      'Walsted',
      'Wang',
      'Warner',
      'Webber',
      'Welch',
      'Winters',
      'Yarbrough',
      'Yeske'
    ]
    total_n, = roll(1, 100)
    text = table[total_n - 1]
    return '1' if text.nil?

    return text
  end

  # 人間の能力値自動生成（仮）
  def getCOMResult()
    output = "\n"

    # 能力値を作成してくる
    str, dex, int, con, app, pow, siz, edu, luck = Make_Characteristic()

    # 能力値から決定する値の算出

    # ダメージボーナスとビルドを計算してきてもらう
    db, build = Damage_Bonus(str, siz)

    # HPとMPの決定
    hp = (con + siz) / 10
    mp = pow / 5

    # 年齢を考慮しない移動値を算出してもらう
    mov = getMovement(dex, str, siz)

    # 出力
    output += "STR #{str}/#{str / 2}/#{str / 5} \tDEX #{dex}/#{dex / 2}/#{dex / 5}\tINT #{int}/#{int / 2}/#{int / 5}\n"
    output += "CON #{con}/#{con / 2}/#{con / 5}\tAPP #{app}/#{app / 2}/#{app / 5}\tPOW #{pow}/#{pow / 2}/#{pow / 5}\n"
    output += "SIZ #{siz}/#{siz / 2}/#{siz / 5}\tEDU #{edu}/#{edu / 2}/#{edu / 5}\t幸運 #{luck}/#{luck / 2}/#{luck / 5}\n"
    output += "HP #{hp}  MP #{mp}  MOVE #{mov}  SAN #{pow}\n"
    output += "ダメージ・ボーナス #{db}  ビルド #{build}"

    return output
  end

  # 探索者データ自動作成（仮）
  def getCOMALLResult(command)
    output = "1"
    age_s = 0
    age_l = 0
    non_age = 0
    age_fixed = 0
    if /^IHIC\[(-?\d+)(,(-?\d+))?\]/i =~ command
      age_s = Regexp.last_match(1)
      age_l = (Regexp.last_match(3) || "")
      rule = 1
    elsif /^IHI\[(-?\d+)(,(-?\d+))?\]/i =~ command
      age_s = Regexp.last_match(1).to_i
      age_l = (Regexp.last_match(3) || "")
      rule = 0
    elsif /^IHIC/i =~ command
      non_age = 1
      age_s = 0
      age_l = 0
      rule = 1
    elsif /^IHI/i =~ command
      non_age = 1
      age_s = 0
      age_l = 0
      rule = 0
    elsif /^KRIC\[(-?\d+)(,(-?\d+))?\]/i =~ command
      age_s = Regexp.last_match(1).to_i
      age_l = (Regexp.last_match(3) || "")
      rule = 3
    elsif /^KRI\[(-?\d+)(,(-?\d+))?\]/i =~ command
      age_s = Regexp.last_match(1).to_i
      age_l = (Regexp.last_match(3) || "")
      rule = 2
    elsif /^KRIC/i =~ command
      non_age = 1
      age_s = 0
      age_l = 0
      rule = 3
    elsif /^KRI/i =~ command
      non_age = 1
      age_s = 0
      age_l = 0
      rule = 2
    else
      output = "error"
      return output
    end

    # rule = 0:探索者ブックから職業ランダム、1：探索者ブックから現代を除いた職業ランダム、2：KPルールブックから職業ランダム、3：KPルールブックから現代を除いた職業ランダム

    # 下限のみ指定（固定）の時の判別。age_fixed = 1なら、固定という意味。
    if age_l != ""
      age_l = age_l.to_i
      age_s = age_s.to_i
    else
      age_s = age_s.to_i
      age_l = 0
      age_fixed = 1
    end

    output = "\n\n"
    message = "\n"

    # 入力内容を再確認し、おかしな入力を修正し、メッセージに内容を入れる
    if age_s < 0
      age_s = age_s.abs
      message += "年齢にマイナスは指定できません。下限の指定値の絶対値をとりました。\n"
    end

    if (age_l < 0) && (age_fixed != 1)
      age_l = age_l.abs
      message += "年齢にマイナスは指定できません。上限の指定値の絶対値をとりました。\n"
    end

    if (age_l < age_s) && (age_fixed != 1)
      # 年齢の大小が逆なら入れ替える
      age_l, age_s = age_s, age_l
      message += "年齢の大小が逆なので、下限の入力値を#{age_s}歳に、上限入力値を#{age_l}歳に入れ替えました。\n"
    end

    if (age_s < 15) && (non_age != 1)
      # non_age = 1なら、年齢が指定されてないという意味。
      age_s = 15
      message += "年齢の最低は、15歳なのでランダム範囲の下限の指定が15歳となりました。\n"
    elsif age_s > 90
      age_s = 90
      message += "年齢の最高は、90歳なのでランダム範囲の下限の指定が90歳となりました。\n"
    end

    if (age_l > 90) && (age_fixed != 1)
      age_l = 90
      message += "年齢の最高は、90歳なのでランダム範囲の上限の指定が90歳となりました。\n"
    elsif (age_l < 15) && (non_age != 1) && (age_fixed != 1)
      age_l = 15
      message += "年齢の最低は、15歳なのでランダム範囲の上限の指定が15歳となりました。\n"
    end

    if (age_s != 0) && (age_l != 0) && (age_s <= age_l)
      message += "年齢は、#{age_s}～#{age_l}歳の範囲でランダムが選択されました。\n"
    elsif non_age == 1
      message += "年齢は、30代に偏った15～90歳の範囲でランダムが選択されました。\n"
    elsif (age_s != 0) && (age_fixed == 1)
      message += "年齢は、#{age_s}歳が選択されました。\n"
    else
      message += "エラー"
    end

    if rule == 0
      message += "職業は、Investigators Handbookのものがランダムに選ばれました。\n"
    elsif rule == 1
      message += "職業は、Investigators Handbookの現代以外のものがランダムに選ばれました。\n"
    elsif rule == 2
      message += "職業は、Keeper Rulebookのものがランダムに選ばれました。\n"
    elsif rule == 3
      message += "職業は、Keeper Rulebookの現代以外のものがランダムに選ばれました。\n"
    end

    # 名前を持ってくる
    name = getRandomNames_table()

    # 年齢を持ってくる
    age = getAge(age_s, age_l)

    # 能力値を作成してくる
    str, dex, int, con, app, pow, siz, edu, luck = Make_Characteristic()

    # 能力値から決定する値の算出

    # 年齢を考慮しない仮の移動値を算出してもらう
    mov_if = getMovement(dex, str, siz)

    # 年齢による移動値の補正
    if (age > 39) && (age < 50)
      mov = mov_if - 1
      message += "年齢により、MOVが-1されました。\n"
    elsif (age > 49) && (age < 60)
      mov = mov_if - 2
      message += "年齢により、MOVが-2されました。\n"
    elsif (age > 59) && (age < 70)
      mov = mov_if - 3
      message += "年齢により、MOVが-3されました。\n"
    elsif (age > 69) && (age < 80)
      mov = mov_if - 4
      message += "年齢により、MOVが-4されました。\n"
    elsif age > 79
      mov = mov_if - 5
      message += "年齢により、MOVが-5されました。\n"
    else
      mov = mov_if
    end

    # 年齢による能力値の成長処理と減少処理
    deduct_point_A = 0
    deduct_point_C = 0
    # type=1でEDU専用の成長処理をしてもらう
    type = 1

    if (age > 14) && (age < 20)
      deduct_point_C = 5
      deduct_point_B = 5
      total_n, = roll(3, 6)
      total_n *= 5
      text = ""
      message += "年齢により、幸運を再決定します。\n3D6×5 ＞ #{total_n}\n"
      if total_n > luck
        message += "再決定の幸運（#{total_n}）が最初の幸運（#{luck}）より高いので、幸運を#{total_n}に変更しました。"
        luck = total_n
      else
        message += "再決定の幸運（#{total_n}）が最初の幸運（#{luck}）以下なので、幸運を変更しませんでした。"
      end
    elsif (age > 19) && (age < 40)
      deduct_point_A = 0
      deduct_point_B = 0
      message += "年齢により、以下のEDUの成長処理を行いました。"
      text, edu = getImprovementRoll(edu, 1, type)
    elsif (age > 39) && (age < 50)
      deduct_point_A = 5
      deduct_point_B = 5
      message += "年齢により、以下のEDUの成長処理を行いました。"
      text, edu = getImprovementRoll(edu, 2, type)
    elsif (age > 49) && (age < 60)
      deduct_point_A = 10
      deduct_point_B = 10
      message += "年齢により、以下のEDUの成長処理を行いました。"
      text, edu = getImprovementRoll(edu, 3, type)
    elsif (age > 59) && (age < 70)
      deduct_point_A = 20
      deduct_point_B = 15
      message += "年齢により、以下のEDUの成長処理を行いました。"
      text, edu = getImprovementRoll(edu, 4, type)
    elsif (age > 69) && (age < 80)
      deduct_point_A = 40
      deduct_point_B = 20
      message += "年齢により、以下のEDUの成長処理を行いました。"
      text, edu = getImprovementRoll(edu, 4, type)
    elsif age > 79
      deduct_point_A = 80
      deduct_point_B = 25
      message += "年齢により、以下のEDUの成長処理を行いました。"
      text, edu = getImprovementRoll(edu, 4, type)
    end
    message += text
    message += "\n"

    # APPは固定で減少する
    app -= deduct_point_B
    if deduct_point_B > 0
      message += "年齢によりAPPが-#{deduct_point_B}されました。\n"
    end
    if app < 0
      message += "APPが0以下（#{app}）となったため、0にされました。\n"
      app = 0
    end

    # 年齢による能力値のランダム減少処理
    if (deduct_point_A != 0) || (deduct_point_C != 0)
      if deduct_point_A != 0
        count = deduct_point_A / 5
        choice_characteristics_list = ['STR', 'CON', 'DEX']
      elsif deduct_point_C != 0
        count = deduct_point_A / 5
        choice_characteristics_list = ['STR', 'SIZ']
      else
        count = 0
      end

      loopCount = 0
      str_after = str
      con_after = con
      dex_after = dex
      siz_after = siz

      while loopCount < count
        loopCount += 1 # テーブル読み込み回数のカウント
        choice_characteristics = choice_characteristics_list.sample

        if choice_characteristics == "STR"
          str_after -= 5
          if str_after <= 0
            choice_characteristics_list = choice_characteristics_list.delete('STR')
            str_after = 0
          end
        elsif choice_characteristics == "CON"
          con_after -= 5
          if con_after <= 0
            choice_characteristics_list = choice_characteristics_list.delete('CON')
            con_after = 0
          end
        elsif choice_characteristics == "DEX"
          dex_after -= 5
          if dex_after <= 0
            choice_characteristics_list = choice_characteristics_list.delete('DEX')
            dex_after = 0
          end
        elsif choice_characteristics == "SIZ"
          siz_after -= 5
          if siz_after <= 0
            choice_characteristics_list = choice_characteristics_list.delete('SIZ')
            siz_after = 0
          end
        end
      end

      if str_after != str
        message += "年齢によりSTRが-#{str - str_after}されました。\n"
        str = str_after
      end
      if con_after != con
        message += "年齢によりCONが-#{con - con_after}されました。\n"
        con = con_after
      end
      if dex_after != dex
        message += "年齢によりDEXが-#{dex - dex_after}されました。\n"
        dex = dex_after
      end
      if siz_after != siz
        message += "年齢によりSIZが-#{siz - siz_after}されました。\n"
        siz = siz_after
      end
    end

    # 最大の能力値を職業技能の算出で使用できる職業をランダムで持ってきてもらう
    max_occupation_characteristics_list = [[str, "str"], [dex, "dex"], [edu, "edu"], [app, "app"], [pow, "pow"]]
    max_occupation_characteristics = max_occupation_characteristics_list.index(max_occupation_characteristics_list.max)
    occupation_characteristics = max_occupation_characteristics_list[max_occupation_characteristics][0]
    occupation_list = getOccupation_table(max_occupation_characteristics_list[max_occupation_characteristics][1], rule)
    occupation_name = occupation_list[1]

    # ダメージボーナスとビルドを計算してきてもらう
    db, build = Damage_Bonus(str, siz)

    # HPとMPの決定
    hp = (con + siz) / 10
    mp = pow / 5

    # 職業技能ポイントと趣味技能ポイントを算出
    occupation_point = (occupation_characteristics * 2) + (edu * 2)
    intrests_point = int * 2

    # 職業技能ポイントランダム割り振り処理
    allocate_sum = 0
    loopCount = 8
    skill_point = 0
    skill_point_allocation_text = ""
    while (occupation_point - (allocate_sum + skill_point - 10)) > 0
      loopCount -= 1
      skill_point = loopCount * 10
      if loopCount != 7
        skill_point_allocation_text += ", "
      end
      skill_point_allocation_text += "#{skill_point}%"
      allocate_sum += skill_point
      # 30%未満の技能値を割り振ることはあまりしたくないと思うので、ループから脱出
      if loopCount == 3
        break
      end
    end
    # 余った技能値が89以上の場合、1：3に割り振りを分割、それ以外はそのまま出力
    if (occupation_point - allocate_sum) > 89
      quarter = (occupation_point - allocate_sum) / 4
      skill_point_allocation_text += ", #{occupation_point - allocate_sum - quarter}%, #{quarter}%"
    else
      skill_point_allocation_text += ", #{occupation_point - allocate_sum}%"
    end

    # ランダムにバックグラウンドを持ってきてもらう
    pd = getPD_table()
    ib = getIB_table()
    sp = getSP_table()
    ml = getML_table()
    tp = getTP_table()
    tr = getTR_table()

    # 出力
    output += "探索者名：#{name[1]} #{name[2]} "
    output += "年齢：#{age}歳 "
    output += "性別：#{name[3]}\n"
    output += "職業：#{occupation_name}\n"
    output += "【能力値】\n"
    output += "STR #{str}/#{str / 2}/#{str / 5} \tDEX #{dex}/#{dex / 2}/#{dex / 5}\tINT #{int}/#{int / 2}/#{int / 5}\n"
    output += "CON #{con}/#{con / 2}/#{con / 5}\tAPP #{app}/#{app / 2}/#{app / 5}\tPOW #{pow}/#{pow / 2}/#{pow / 5}\n"
    output += "SIZ #{siz}/#{siz / 2}/#{siz / 5}\tEDU #{edu}/#{edu / 2}/#{edu / 5}\t幸運 #{luck}/#{luck / 2}/#{luck / 5}\n"
    output += "HP #{hp}\t\tMP #{mp}\t\tMOVE #{mov}\t\tSAN #{pow}\n"
    output += "ダメージ・ボーナス #{db}\tビルド #{build}\n"
    output += "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\n"
    output += "\n【技能】（職業技能ポイント #{occupation_point}, 趣味技能ポイント #{intrests_point}）\n"
    output += "●ランダム決定した職業の職業技能欄を確認し、8つの職業技能と信用に以下の％を割り振ると容易に技能を割り振れるでしょう。\n　ただし、職業ごとに決められた信用の範囲を超えて信用に割り振ることはできません。\n技能ポイント（割り振り目安です）："
    output += skill_point_allocation_text
    output += "\n●趣味技能ポイントを自由に割り振りましょう。\n"
    output += "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\n"
    output += "\n【バックグラウンド】\n#{pd}\n#{ib}\n#{sp}\n#{ml}\n#{tp}\n#{tr}\n"
    output += "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\n"
    output += "\n【処理に関するメッセージ】"
    output += message

    return output
  end

  def Damage_Bonus(str, siz)
    # ダメージボーナス決定処理
    strsiz = str + siz

    if strsiz < 65
      db = "-2"
      build = "-2"
    elsif (strsiz > 64) && (strsiz < 85)
      db = "-1"
      build = "-1"
    elsif (strsiz > 84) && (strsiz < 125)
      db = "0"
      build = "0"
    elsif (strsiz > 124) && (strsiz < 165)
      db = "+1D4"
      build = "1"
    elsif (strsiz > 164) && (strsiz < 204)
      db = "+1D6"
      build = "2"
    else
      return '1'
    end

    return db, build
  end

  def Make_Characteristic()
    # 能力値の算出処理
    loopCount = 0
    while loopCount < 9
      loopCount += 1 # テーブル読み込み回数のカウント

      if (loopCount == 3) || (loopCount == 7) || (loopCount == 8)
        total_n, = roll(2, 6)
        characteristic = (total_n + 6) * 5
      else
        total_n, = roll(3, 6)
        characteristic = total_n * 5
      end

      if loopCount == 1 # 能力値から決定する値に関する値のみを抽出
        str = characteristic
      elsif loopCount == 2
        dex = characteristic
      elsif loopCount == 3
        int = characteristic
      elsif loopCount == 4
        con = characteristic
      elsif loopCount == 5
        app = characteristic
      elsif loopCount == 6
        pow = characteristic
      elsif loopCount == 7
        siz = characteristic
      elsif loopCount == 8
        edu = characteristic
      elsif loopCount == 9
        luck = characteristic
      end
    end
    return str, dex, int, con, app, pow, siz, edu, luck
  end

  def getMovement(dex, str, siz)
    # 移動率決定処理
    if (dex < siz) && (str < siz)
      mov_if = 7
    elsif (dex > siz) && (str > siz)
      mov_if = 9
    else
      mov_if = 8
    end
    return mov_if
  end

  # 年齢を決定処理
  def getAge(age_s, age_l)
    # 30歳付近を最頻値にして年齢を決定
    if (age_s == 0) && (age_l == 0)
      dice_a = rand(1..20)
      # 下記dice_a> 16の条件を変えると、偏りが代わる。
      if dice_a > 16
        total_n, = roll(3, 6)
      else
        total_n, = roll(3, 3)
      end
      age = total_n * 5

      if age == 90
      else
        rand, = roll(1, 6)
        rand -= 1
        age += rand
      end
    # 年齢が指定されている場合
    elsif (age_s != 0) && (age_l == 0)
      age = age_s
    # 年齢の範囲を指定してランダムで年齢を決定
    elsif (age_s != 0) && (age_l != 0)
      age = rand(age_s..age_l)
    end
    return age
  end

  # 成長判定処理
  def getImprovementRoll(diff, loopCount, type)
    output = "エラー"
    # type=1で、自動作成時のEDU成長処理の意味。
    if (diff < 0) || ((diff > 99) && (type == 1))
      return output diff
    end

    afterdiff = diff
    output = ""

    if (loopCount > 0) && (loopCount < 101)
      while loopCount > 0
        total_n, = roll(1, 100)
        # 成否判定部
        if (total_n > afterdiff) || ((total_n > 95) && (type != 1))
          output += "\n(1D100>#{afterdiff}) ＞ #{total_n}  ＞ 成功"
          rise_n, = roll(1, 10)
          output += " ＞ #{rise_n}成長"
          afterdiff += rise_n
        else
          output += "\n(1D100>#{afterdiff}) ＞ #{total_n}  ＞ 失敗"
        end
        loopCount -= 1
      end
    end
    output += "\n合計#{afterdiff - diff}ポイント成長"
    return output, afterdiff
  end

  # 技能成長処理
  def getCheckRoll(command)
    output = ""
    return output unless /^SI(-?\d+)(\[(\d+)?\])?$/i =~ command

    diff = Regexp.last_match(1).to_i
    loopCount = (Regexp.last_match(3) || 1).to_i
    maxrise = 100 # 最大試行回数
    type = 0
    if diff < 0
      output = "技能値は正の値を入力してください。"
      return output
    end

    if (loopCount > 0) && (loopCount < maxrise)
      output, afterdiff = getImprovementRoll(diff, loopCount, type)
      if (afterdiff >= 90) && (diff < 90)
        output += "\n2D6正気度ポイント獲得（技能値の成長の場合のみ）"
      end
      output += "\n結果#{afterdiff}ポイント"
      if afterdiff > 100
        output += "\n100以上成長しないものを成長させようとし、結果が100ポイント以上となっている場合には、99にしてください。"
      end
      if afterdiff > 95
        output += "\nEDUの成長は技能の成長と処理が異なるので、EDUの成長前の値が96以上の場合、96-100までの値を出しても必ず成長することはないことに注意してください。"
      end
    elsif loopCount > maxrise
      output += "試行回数は1以上#{maxrise}以下にしてください。"
      return output
    else
      output += "試行回数が間違っています。"
      return output
    end
    return output
  end
end
