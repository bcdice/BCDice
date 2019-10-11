# -*- coding: utf-8 -*-

class Cthulhu7th < DiceBot
  setPrefixes(['CC\(\d+\)', 'CC.*', 'CBR\(\d+,\d+\)', 'FAR.*', 'BMR', 'BMS', 'FCL', 'FCM', 'PH', 'MA'])

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

・各種表
　【狂気関連】
　・即時の狂気の発作（Bouts of Madness Real Time）表　BMR
　・略式の狂気の発作（Bouts of Madness Summary）表　BMS
　・恐怖症（Sample Phobias）表　PH／マニア（Sample Manias）表　MA
　【魔術関連】
　・プッシュ時の詠唱ロール（Casting Roll）での失敗表
　　控えめな呪文の場合　FCL／パワフルな呪文の場合　FCM
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
    when /^BMR/i # 即時の狂気の発作表
      return roll_bmr_table()
    when /^BMS/i # 略式の狂気の発作表
      return roll_bms_table()
    when /^FCL/i # 詠唱ロールのプッシュに失敗した場合（小）
      return roll_1d8_table("詠唱ロール失敗(小)表", FAILED_CASTING_L_TABLE)
    when /^FCM/i # 詠唱ロールのプッシュに失敗した場合（大）
      return roll_1d8_table("詠唱ロール失敗(大)表", FAILED_CASTING_M_TABLE)
    when /^PH/i # 恐怖症表
      return roll_1d100_table("恐怖症表", PHOBIAS_TABLE)
    when /^MA/i # マニア表
      return roll_1d100_table("マニア表", MANIAS_TABLE)
    else
      return nil
    end
  end

  private

  def roll_1d8_table(table_name, table)
    total_n, = roll(1, 8)
    index = total_n - 1

    text = table[index]

    return "#{table_name}(#{total_n}) ＞ #{text}"
  end

  def roll_1d100_table(table_name, table)
    total_n, = roll(1, 100)
    index = total_n - 1

    text = table[index]

    return "#{table_name}(#{total_n}) ＞ #{text}"
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
    return nil unless /^FAR\((-?\d+),(-?\d+),(-?\d+)(?:,(-?\d+)?)?(?:,(-?\w+)?)?\)/i =~ command

    bullet_count = Regexp.last_match(1).to_i
    diff = Regexp.last_match(2).to_i
    broken_number = Regexp.last_match(3).to_i
    bonus_dice_count = (Regexp.last_match(4) || 0).to_i
    stop_count = (Regexp.last_match(5) || "").to_s.downcase

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
    (0..3).each do |more_difficulty|
      output += getNextDifficultyMessage(more_difficulty)

      # ペナルティダイスを減らしながらロール用ループ
      while dice_num >= @bonus_dice_range.min

        loopCount += 1
        hit_result, total, total_list = getHitResultInfos(dice_num, diff, more_difficulty)
        output += "\n#{loopCount}回目: ＞ #{total_list.join(', ')} ＞ #{hit_result}"

        if total >= broken_number
          output += "ジャム"
          return getHitResultText(output, counts)
        end

        hit_type = getHitType(more_difficulty, hit_result)
        hit_bullet, impale_bullet, lost_bullet = getBulletResults(counts[:bullet], hit_type, diff)

        counts[:hit_bullet] += hit_bullet
        counts[:impale_bullet] += impale_bullet
        counts[:bullet] -= lost_bullet

        return getHitResultText(output, counts) if counts[:bullet] <= 0

        dice_num -= 1
      end

      # 指定された難易度となった場合、連射処理を途中で止める
      if shouldStopRollFullAuto?(stop_count, more_difficulty)
        output += "\n指定の難易度となったので、処理を終了します。"
        break
      end

      dice_num += 1
    end

    return getHitResultText(output, counts)
  end

  # 連射処理を止める条件（難易度の閾値）
  # @return [Hash<String, Integer>]
  #
  # 成功の種類の小文字表記 => 難易度の閾値
  ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD = {
    # 通常成功
    'r' => 0,
    # 困難な成功
    'h' => 1,
    # 極限の成功
    'e' => 2
  }.freeze

  # 連射処理を止めるべきかどうかを返す
  # @param [String] stop_count 成功の種類
  # @param [Integer] difficulty 難易度
  # @return [Boolean]
  def shouldStopRollFullAuto?(stop_count, difficulty)
    difficulty_threshold = ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD[stop_count]
    return difficulty_threshold && difficulty >= difficulty_threshold
  end

  def getHitResultInfos(dice_num, diff, more_difficulty)
    units_digit = rollPercentD10
    total_list = getTotalLists(dice_num, units_digit)
    total = getTotal(total_list, dice_num)

    fumbleable = getFumbleable(more_difficulty)
    hit_result = getCheckResultText(total, diff, fumbleable)

    return hit_result, total, total_list
  end

  def getHitResultText(output, counts)
    return "#{output}\n＞ #{counts[:hit_bullet]}発が命中、#{counts[:impale_bullet]}発が貫通、残弾#{counts[:bullet]}発"
  end

  def getHitType(more_difficulty, hit_result)
    successList, impaleBulletList = getSuccessListImpaleBulletList(more_difficulty)

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

  def getSuccessListImpaleBulletList(more_difficulty)
    successList = []
    impaleBulletList = []

    case more_difficulty
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

  def getNextDifficultyMessage(more_difficulty)
    case more_difficulty
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

  def getFumbleable(more_difficulty)
    # 成功が49以下の出目のみとなるため、ファンブル値は上昇
    return (more_difficulty >= 1)
  end

  # 表一式
  # 即時の恐怖症表
  def roll_bmr_table()
    total_n, = roll(1, 10)
    text = MADNESS_REAL_TIME_TABLE[total_n - 1]

    time_n, = roll(1, 10)

    return "即時の狂気の発作表(#{total_n}) ＞ #{text}(1D10＞#{time_n}ラウンド)"
  end

  MADNESS_REAL_TIME_TABLE = [
    '最後にいた安全な場所から事件が起こった時までの出来事の記憶を失い、1D10ラウンド続く。',
    '探索者は心因性視覚障害、心因性難聴、単数あるいは複数の四肢の機能障害を1D10ラウンド受ける。',
    '敵味方を問わずに周囲へ暴力と破壊の衝動が1D10ラウンドの間向けられる。',
    '探索者は1D10ラウンドの間、深刻な被害妄想を受ける。全員それを手に入れようと思っている/誰も信頼することはできない/彼らはスパイをしている/誰かが彼らを裏切った/見ているものは何かの陰謀か策略だ。',
    '探索者の背景の「重要な人々」を参照。そのシーンにいる他の人物を自分達の重要な人物と誤認し、その人物との関係性に従って行動。1D10ラウンド持続する。',
    '探索者は気絶し、1D10ラウンド後に回復する。',
    'たとえその場にある唯一の車を使い、他の人を見捨てて行くことになったとしても、使えるものはなんでも使って、できる限り遠くに無理やり離れようとして、1D10ラウンドの間逃げようとする。',
    '探索者は1D10ラウンドの間、叫んだり、泣いたり、笑ったりして無力化される。',
    '探索者は新しい恐怖症を得る。恐怖症の原因が途中で無くなっても、1D10ラウンドの間それがそこにいると想像してしまう。恐怖症の内容は、恐怖症表（PHコマンド）で決定するか、KPが決定する。',
    '探索者は新しいマニアを得る。1D10ラウンドの間、探索者は自分の新しい偏執症に耽溺するために探し回る。マニアの内容は、マニア表（MAコマンド）で決定するか、KPが決定する。'
  ].freeze

  # 略式の恐怖表
  def roll_bms_table()
    total_n, = roll(1, 10)
    text = MADNESS_SUMMARY_TABLE[total_n - 1]

    time_n, = roll(1, 10)

    return "略式の狂気の発作表(#{total_n}) ＞ #{text}(1D10＞#{time_n}時間)"
  end

  MADNESS_SUMMARY_TABLE = [
    '見知らぬ場所で自分達が誰なのか記憶を無くしたことに気づく。時間の経過と共に記憶は回復する。（1D10時間）',
    '1D10時間の後、盗難に遭ったことに気づく。背景の宝物を持っていたなら幸運ロールを振る。自動的に全ての価値のあるものは失われる。',
    '1D10時間の後、自分達が打ちのめされ、傷だらけになっていることに気づく(HP半減)。ただしこれで重傷にはならないし、物も盗まれることは無い。どのような傷だったかはKPが決定する。',
    '感情を爆発させて暴力と破壊の大騒ぎをする。気づくともしかしたらその行動中の記憶が戻るかもしれない。誰や何を破壊したのか、殺したのか、または単に危害を加えたのかは、KPが決定する。（1D10時間）',
    '背景の対象について極端で狂った実証方法で表明を行う。例えば、信仰心が強い人物が、自らの教義を地下鉄で述べ伝えているところを発見される。（1D10時間）',
    '1D10時間かそれ以上後まで、探索者はその人物に近づくために何でもし、彼らとのつながりに何らかの形で影響を与える。',
    '精神科病棟や警察の牢獄で気がつく。彼らはそれから今までの出来事をゆっくりと思い出すかもしれない。（1D10時間）',
    '感覚が戻ると荒野で迷子になるか、電車や長距離バスでどこかに向かっている。（1D10時間）',
    '探索者は新しい恐怖症を得る。1D10時間後に、その恐怖症に対してあらゆる予防措置をとった状態で気がつく。恐怖症の内容は、恐怖症表（PHコマンド）で決定するか、KPが決定する。',
    '探索者は新しいマニアを得る。1D10時間後に意識がはっきりする。この発作中、探索者は新たなマニアに耽溺しているだろうが、それが他の人物にも明らかだったかどうかは、KPとPLが決定する。マニアの内容はマニア表（MAコマンド）で決定するか、KPが決定する。'
  ].freeze

  # 詠唱ロールのプッシュに失敗した場合（小）
  FAILED_CASTING_L_TABLE = [
    '目がかすむか、一時的な失明。',
    '姿が見えない相手からの悲鳴や声や雑音など。',
    '強風やその他大気効果。',
    '呪文の使い手や他のその場にいる人物、周囲の物体（例えば壁）からの出血。',
    '奇妙なビジョンや幻覚。',
    '付近の小動物が爆ぜる。',
    '硫黄の悪臭。',
    'クトゥルフ神話の怪物が誤って召喚される。'
  ].freeze

  # 詠唱ロールのプッシュに失敗した場合（大）
  FAILED_CASTING_M_TABLE = [
    '大地が揺れ、壁が崩壊する。',
    '途方も無い雷や稲妻。',
    '空から血が降ってくる。',
    '呪文の使い手の手が萎びて黒こげになる。',
    '呪文の使い手が異常に老ける（+2D10歳）。',
    '強力あるいは数多くの神話の存在が現れ、呪文の使い手を最初にして、近くの全ての者を攻撃する。',
    '呪文の使い手や周囲の全員が遠くの場所や時間に吸い込まれる。',
    '神話の神が誤って招来される。'
  ].freeze

  # 恐怖症表
  PHOBIAS_TABLE = [
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
  ].freeze

  # マニア表
  MANIAS_TABLE = [
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
  ].freeze
end
