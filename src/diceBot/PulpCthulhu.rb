# -*- coding: utf-8 -*-

class PulpCthulhu < DiceBot
  setPrefixes(['CC\(\d+\)', 'CC.*', 'CBR\(\d+,\d+\)', 'FAR.*', 'BMR', 'BMS', 'FCE', 'PH', 'MA', 'IT'])

  def initialize
    # $isDebug = true
    super

    @bonus_dice_range = (-2..2)
  end

  def gameName
    'パルプ・クトゥルフ'
  end

  def gameType
    "PulpCthulhu"
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
※私家翻訳のため、用語・ルールの詳細については原本を参照願います。
※コマンドは入力内容の前方一致で検出しています。
・判定　CC(x)<=（目標値）
　x：ボーナス・ペナルティダイス (2～－2)。省略可。
　目標値が無くても1D100は表示される。
　ファンブル／失敗／
　成功／ハード成功／イクストリーム成功／クリティカル を自動判定。
例）CC<=30　CC(2)<=50　CC(-1)<=75 CC-1<=50 CC1<=65 CC

・組み合わせ判定　(CBR(x,y))
　目標値 x と y で％ロールを行い、成否を判定。
　例）CBR(50,20)

・自動火器の射撃判定　FAR(w,x,y,z,d)
　w：弾丸の数(1～100）、x：技能値（1～100）、y：故障ナンバー、
　z：ボーナス・ペナルティダイス(-2～2)。省略可。
　d：指定難易度で連射を終える（レギュラー：r,ハード：h,イクストリーム：e）。省略可。
　命中数と貫通数、残弾数のみ算出。ダメージ算出はありません。
例）FAR(25,70,98)　FAR(50,80,98,-1)　far(30,70,99,1,R)
　　far(25,88,96,2,h)　FaR(40,77,100,,e)

・各種表
　【狂気関連】
　・狂気の発作（リアルタイム）　BMR
　・狂気の発作（サマリー）　BMS
　・恐怖症表　PH／マニア表　MA
　・狂気のタレント（Insane Talents）表　IT
　【魔術関連】
　・プッシュ時のキャスティング・ロールの失敗（Failed Casting Effects）表　FCE
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
    when /^BMR/i # 狂気の発作（リアルタイム）
      return roll_bmr_table()
    when /^BMS/i # 狂気の発作（サマリー）
      return roll_bms_table()
    when /^FCE/i # キャスティング・ロールのプッシュに失敗した場合
      return roll_1d20_table("キャスティング・ロール失敗表", FAILED_CASTING_EFFECTS_TABLE)
    when /^PH/i # 恐怖症表
      return roll_1d100_table("恐怖症表", PHOBIAS_TABLE)
    when /^MA/i # マニア表
      return roll_1d100_table("マニア表", MANIAS_TABLE)
    when /^IT/i # 狂気のタレント表
      return roll_1d20_table("狂気のタレント表", INSANE_TALENTS_TABLE)
    else
      return nil
    end
  end

  private

  def roll_1d20_table(table_name, table)
    total_n, = roll(1, 20)
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
    m = /^CC([-\d]+)?(<=(\d+))?/i.match(command)
    unless m
      return nil
    end

    bonus_dice_count = m[1].to_i # ボーナス・ペナルティダイスの個数
    diff = m[3].to_i
    without_compare = m[2].nil? || diff <= 0

    if bonus_dice_count == 0 && diff <= 0
      dice, = roll(1, 100)
      return  "1D100 ＞ #{dice}"
    end

    unless @bonus_dice_range.include?(bonus_dice_count)
      return "エラー。ボーナス・ペナルティダイスの値は#{@bonus_dice_range.min}～#{@bonus_dice_range.max}です。"
    end

    units_digit = rollPercentD10
    total_list = getTotalLists(bonus_dice_count, units_digit)
    total = getTotal(total_list, bonus_dice_count)

    if without_compare
      output = "(1D100) ボーナス・ペナルティダイス[#{bonus_dice_count}]"
      output += " ＞ #{total_list.join(', ')} ＞ #{total}"
    else
      result_text = getCheckResultText(total, diff)
      output = "(1D100<=#{diff}) ボーナス・ペナルティダイス[#{bonus_dice_count}]"
      output += " ＞ #{total_list.join(', ')} ＞ #{total} ＞ #{result_text}"
    end

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
      return "クリティカル" if total == 1
      return "イクストリーム成功" if total <= (diff / 5)
      return "ハード成功" if total <= (diff / 2)

      return "成功"
    end

    fumble_text = "ファンブル"

    return fumble_text if total == 100

    if total >= 96
      if diff < 50
        return fumble_text
      elsif fumbleable
        return fumble_text
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

    successList = ["クリティカル", "イクストリーム成功", "ハード成功", "成功"]

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
          output += " ジャム"
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
    # レギュラー
    'r' => 0,
    # ハード
    'h' => 1,
    # イクストリーム
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
      successList = ["ハード成功", "成功"]
      impaleBulletList = ["クリティカル", "イクストリーム成功"]
    when 1
      successList = ["ハード成功"]
      impaleBulletList = ["クリティカル", "イクストリーム成功"]
    when 2
      successList = []
      impaleBulletList = ["クリティカル", "イクストリーム成功"]
    when 3
      successList = ["クリティカル"]
      impaleBulletList = []
    end

    return successList, impaleBulletList
  end

  def getNextDifficultyMessage(more_difficulty)
    case more_difficulty
    when 1
      return "\n    難易度がハードに変更"
    when 2
      return "\n    難易度がイクストリームに変更"
    when 3
      return "\n    難易度がクリティカルに変更"
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

    return "狂気の発作（リアルタイム）(#{total_n}) ＞ #{text}(1D10＞#{time_n}ラウンド)"
  end

  MADNESS_REAL_TIME_TABLE = [
    '健忘症：ヒーローは自分自身がヒーローである考えをやめ、1D10ラウンドの間パルプのタレントを失う。',
    '狂った計画：1D10ラウンドの間ヒーローは不合理的または非効率的な計画を考えつく。その計画は敵を有利にするものかもしれないし、ヒーローの仲間に対して危険を高めるものかもしれない。',
    '怒り：頭に血が上り1D10ラウンドの間、周囲の人間、味方、敵問わず暴力と破壊を振りまく。',
    'おごり高ぶる：1D10ラウンドの間ヒーローは威張り散らし、自らの計画を大声で叫ぶように強制される。「私と私の盟友達がこの巣穴に潜むグール達を一掃する！！　だがしかし、その前に一言言わせてもらいたい」',
    'リラックス：ヒーローが目の前の驚異が気にするほどの物でないと思い1D10ラウンドの間その場に座り込む。彼は葉巻を吸ったり、スキットルで乾杯するのに時間を使うかもしれない。',
    'パニックになって逃亡する:1台のみの車に乗り、例え仲間を置き去りにしていくことになっても、ヒーローは手段さえあれば可能な限り遠くへ行こうとします。1D10ラウンドの間、逃げ続ける。',
    '注目を集めたがる：ヒーローは1D10ラウンドの間注目を集めようとする。恐らく無謀な事を行うことだろう。',
    'アルター・エゴ（もう一人の僕！）：ヒーローは完全な変化を受け、1D10ラウンドの間、完全に別の人格に入れ替わる。入れ替わった人格はヒーローの性格と真逆のものだ。そのヒーローが親切であれば、もう１人の自分は不親切だ。一方が利己的であれば、もう１人の自分は利他的となる。もし特定のヒーローが永久的な狂気に陥った場合、キーパーは原因である怪物の自我を生み出すことに使用する事もできる。',
    '恐怖症：ヒーローは新しい恐怖症に陥る。恐怖症表（PHコマンド）をロールするか、キーパーが恐怖症を1つ選ぶ。恐怖症の原因は存在しなくとも、その探索者は次の1D10ラウンドの間、それがそこにあると思い込む。',
    'マニア：ヒーローは新しいマニアに陥る。マニア表（MAコマンド）をロールするか、キーパーがマニアを1つ選ぶ。その探索者は次の1D10ラウンドの間、自分の新しいマニアに没頭しようとする。',
  ].freeze

  # 略式の恐怖表
  def roll_bms_table()
    total_n, = roll(1, 10)
    text = MADNESS_SUMMARY_TABLE[total_n - 1]

    time_n, = roll(1, 10)

    return "狂気の発作（サマリー）(#{total_n}) ＞ #{text}(1D10＞#{time_n}時間)"
  end

  MADNESS_SUMMARY_TABLE = [
    '健忘症：ヒーローは自分が誰であるかの記憶を失い、パルプのタレントを失い、自分のいる場所に大きな違和感を覚える。彼らの記憶は時間の経過と共にゆっくりと戻る。彼らのパルプのタレントは危機的な状況でのみ戻る。この場合、危機的状況とは誰かの命が晒されているなどの場合と定義する。誰かの命が脅かされるとヒーローは〈幸運〉ロールをう。成功すればタレントは戻る。失敗すれば1D10ラウンド後にもう一度行うことができる。',
    '盗難：1D10時間後にヒーローは意識を取り戻す。彼は無傷だ。彼が宝物を持っている場合それが盗まれたかどうかを知るために〈幸運〉ロールを行う。価値のあるものは全て自動的に失われる。',
    '暴行：ヒーローは1D10時間後に目覚め、体中が痣や傷だらけであることに気づく。耐久力が半分になる。物は奪われていない。どの様な被害にあったかは、キーパーに委ねられる。',
    '暴力：暴力と破壊衝動をヒーローは爆発させる。1D10時間後にヒーローの意識が戻るとき、彼らが行った行動を覚えているかもしれない。ヒーローが誰に対して暴力を振るったか、誰を殺したかはキーパーに委ねられる。',
    'イデオロギー／信念：ヒーローのイデオロギーと信念、背景を証明しようとする。ヒーローは極端に狂い、実証的なやり方でこれらの１つを証明しようとする。一般的にこのような結果はヒーローが人類を傷つけ、正義という名の誇大妄想を抱く事につながる。',
    '重要な人々：ヒーローの背景情報を見て関係を持つ重要な人々を参照する。（1D10時間以上）ヒーローはその人物に近づき、その人の為に最善を尽くす。',
    '収容：ヒーローは高セキュリティの精神病院または警察の監獄で目を覚ます。彼らはそこで自分が犯した出来事をゆっくりと思い出すかもしれない。',
    'パニック：ヒーローが目覚めると元いた場所から遠く離れた場所にいることに気づく。彼らはエンパイア・ステート・ビルの屋上、ホワイト・ハウスの中、または軍事本部の中心にいるかもしれない。それは注目を集める事になるだろう、何故彼らがその場にいるのかは彼らにもわからない。',
    '恐怖症：ヒーロー新たな恐怖症を獲得する。恐怖症表（PHコマンド）をロールするか、キーパーがどれか1つ選ぶ。探索者は1D10時間後に意識を取り戻し、この新たな恐怖症の対象を避けるためにあらゆる努力をしている。',
    'マニア：ヒーローは新たなマニアを獲得する。マニア表（MAコマンド）をロールするか、キーパーがどれか1つ選ぶ。この狂気の発作の間、探索者はこの新たなマニアに完全に溺れているだろう。これがほかの人々に気づかれるかどうかは、キーパーとプレイヤーに委ねられる。',
  ].freeze

  # キャスティング・ロールのプッシュに失敗した場合
  FAILED_CASTING_EFFECTS_TABLE = [
    '叙事詩的な雷と稲光。',
    '1D6ラウンドの一時的な盲目（成功難易度を変化させる/ペナルティ・ダイスを1つ加える）。',
    'どこかから強い風が吹きつける（幸運ロールに失敗すると紙や本などの軽い持ち物を失う）。',
    '壁や床や窓などから輝く緑の粘体が発生する（0/1D3の正気度喪失）',
    'キーパーが選んだ奇妙な幻覚に襲われる（見たものに適した正気度喪失）',
    'その付近の小動物たちが爆発する（0/1D3の正気度喪失）。',
    '呪文の使い手の髪が真っ白になる。',
    '大きな姿のない悲鳴が聞こえる（0/1の正気度喪失）',
    '1D4ラウンドの間、目から血を流す（成功難易度を変化させる/ペナルティ・ダイスを1つ加える）。',
    '硫黄の臭いがする。',
    '大地が震え、壁に亀裂が入って崩れる。',
    '呪文の使い手の手がしおれて、燃え（どちらの手なのか幸運ロールで決定する）、1D2のHPを失う。（キーパーの裁量で、手が一時的に燃えるか（手を使用する必要がある技能ロールとDEXロールのすべてにペナルティ・ダイスが加わる）、または永久にしおれて黒くなる（DEXと手を使用する必要がある技能のすべてを20ポイント減少する。））',
    '1D6ラウンドの間、血が空から降る。',
    '呪文の使い手は異常に年をとる（+2D10歳と能力値の修正）。',
    '呪文の使い手の皮膚が永久的に半透明になる（その呪文の使い手を見た者は1/1D4の正気度喪失）。',
    '呪文の使い手は1D10のPOWを獲得するが、1D10の正気度も失う。',
    'クトゥルフ神話の怪物が偶然召喚される。',
    'キーパーはランダムに2つの呪文を選び、両方が発動する（呪文の使い手を中心に）。',
    '呪文の使い手と近くの全員が、別の場所に吸い込まれる（キーパーがどこかは決定する）。',
    'クトゥルフ神話の神格が偶然招来される。',
  ].freeze

  # 恐怖症表
  PHOBIAS_TABLE = [
    '入浴恐怖症：体、手、顔を洗うのが怖い。',
    '高所恐怖症：高いところが怖い。',
    '飛行恐怖症：飛ぶのが怖い。',
    '広場恐怖症：広場、公共の(混雑した)場所が怖い。',
    '鶏肉恐怖症：鶏肉が怖い。',
    'ニンニク恐怖症：ニンニクが怖い。',
    '乗車恐怖症：車両の中にいたり車両に乗るのが怖い。',
    '風恐怖症：風が怖い。',
    '男性恐怖症：男性が怖い。',
    'イングランド恐怖症：イングランド、もしくはイングランド文化などが怖い。',
    '花恐怖症：花が怖い。',
    '切断恐怖症：手足や指などが切断された人が怖い。',
    'クモ恐怖症：クモが怖い。',
    '稲妻恐怖症：稲妻が怖い。',
    '廃墟恐怖症：廃墟が怖い。',
    '笛恐怖症：笛(フルート)が怖い。',
    '細菌恐怖症：細菌、バクテリアが怖い。',
    '銃弾恐怖症：投擲物や銃弾が怖い。',
    '落下恐怖症：落下が怖い。',
    '書物恐怖症：本が怖い。',
    '植物恐怖症：植物が怖い。',
    '美女恐怖症：美しい女性が怖い。',
    '低温恐怖症：冷たいものが怖い。',
    '時計恐怖症：時計が怖い。',
    '閉所恐怖症：壁に囲まれた場所が怖い。',
    '道化師恐怖症：道化師が怖い。',
    '犬恐怖症：犬が怖い。',
    '悪魔恐怖症：悪魔が怖い。',
    '群集恐怖症：人混みが怖い。',
    '歯科医恐怖症：歯科医が怖い。',
    '処分恐怖症：物を捨てるのが怖い(ためこみ症)',
    '毛皮恐怖症：毛皮が怖い。',
    '構断恐怖症：道路を横断するのが怖い。',
    '教会恐怖症：教会が怖い。',
    '鏡恐怖症：鏡が怖い。',
    'ピン恐怖症：針やピンが怖い。',
    '昆虫恐怖症：昆虫が怖い。',
    '猫恐怖症：猫が怖い。',
    '橋恐怖症：橋を渡るのが怖い。',
    '老人恐怖症：老人や年をとることが怖い。',
    '女性恐怖症：女性が怖い。',
    '血液恐怖症：血が怖い。',
    '過失恐怖症：失敗が怖い。',
    '接触恐怖症：触ることが怖い。',
    '爬虫類恐怖症：爬虫類が怖い。',
    '霧恐怖症：霧が怖い。',
    '銃器恐怖症：銃器が怖い。',
    '水恐怖症：水が怖い。',
    '睡眠恐怖症：眠ったり、催眠状態に陥るのが怖い。',
    '医師恐怖症：医師が怖い。',
    '魚恐怖症：魚が怖い。',
    'ゴキブリ恐怖症：ゴキブリが怖い。',
    '雷鳴恐怖症：雷鳴が怖い。',
    '野菜恐怖症：野菜が怖い。',
    '大騒音恐怖症：大きな騒音が怖い。',
    '湖恐怖症：湖が怖い。',
    '機械恐怖症：機械や装置が怖い。',
    '巨大物恐怖症：巨大なものが怖い。',
    '拘束恐怖症：縛られたり結びつけられたりするのが怖い。',
    '隕石恐怖症：流星や隕石が怖い。',
    '孤独恐怖症：独りでいることが怖い。',
    '汚染恐怖症：汚れたり汚染されたりするのが怖い。',
    '粘液恐怖症：粘液、粘体が怖い。',
    '死体恐怖症：死体が怖い。',
    '8恐怖症：8の数字が怖い。',
    '歯恐怖症：歯が怖い。',
    '夢恐怖症：夢が怖い。',
    '名称恐怖症：特定の言葉（1つまたは複数）を聞くのが怖い。',
    '蛇恐怖症：蛇が怖い。',
    '鳥恐怖症：鳥が怖い。',
    '寄生生物恐怖症：寄生生物が怖い。',
    '人形恐怖症：人形が怖い。',
    '恐食症：のみ込むこと食べること、もしくは食べられることが怖い。',
    '薬物恐怖症：薬物が怖い。',
    '幽霊恐怖症：幽霊が怖い。',
    '羞明：日光が怖い。',
    'ひげ恐怖症：ひげが怖い',
    '河川恐怖症：川が怖い',
    'アルコール恐怖症：アルコールやアルコール飲料が怖い。',
    '火恐怖症：火が怖い。',
    '魔術恐怖症：魔術が怖い。',
    '暗黒恐怖症：暗闇や夜が怖い。',
    '月恐怖症：月が怖い。',
    '鉄道恐怖症：列車の旅が怖い。',
    '星恐怖症：星が怖い。',
    '狭所恐怖症：狭いものや場所が怖い。',
    '対称恐怖症：左右対称が怖い。',
    '生き埋め恐怖症：生き埋めになることや墓地が怖い。',
    '雄牛恐怖症：雄牛が怖い。',
    '電話恐怖症：電話が怖い。',
    '奇形恐怖症：怪物が怖い。',
    '海洋恐怖症：海が怖い。',
    '手術恐怖症：外科手術が怖い。',
    '13恐怖症：13の数字が怖い。',
    '衣類恐怖症：衣服が怖い。',
    '魔女恐怖症：魔女と魔術が怖い。',
    '黄色恐怖症：黄色や「黄色」という言葉が怖い。',
    '外国語恐怖症：外国語が怖い。',
    '外国人恐怖症：外国人が怖い。',
    '動物恐怖症：動物が怖い。',
  ].freeze

  # マニア表
  MANIAS_TABLE = [
    '洗浄マニア：自分の体を洗わずにはいられない。',
    '無為マニア：病的な優柔不断。',
    '暗闇マニア：暗黒に関する過度の嗜好。',
    '高所マニア：高い場所に登らずにはいられない。',
    '善良マニア：病的な親切。',
    '広場マニア：開けた場所にいたいという激しい願望。',
    '先鋭マニア：鋭いもの、とがったものへの執着。',
    '猫マニア：猫に関する異常な愛好心。',
    '疼痛性愛：痛みへの執着。',
    'にんにくマニア：にんにくへの執着。',
    '乗り物マニア：車の中にいることへの執着。',
    '病的快活：不合理なほがらかさ。',
    '花マニア：花への執着。',
    '計算マニア：数への偏執的な没頭。',
    '浪費マニア：衝動的あるいは無謀な浪費。',
    '自己マニア：孤独への過度の嗜好。',
    'バレエマニア：バレエに関する異常な愛好心。',
    '書籍約盗癖：本を盗みたいという強迫的衝動。',
    '書物マニア：本または読書、あるいはその両方への執着。',
    '歯ぎしりマニア：歯ぎしりしたいという強迫的衝動。',
    '悪霊マニア：誰かの中に邪悪な精霊がいるという病的な信念。',
    '自己愛マニア：自分自身の美への執着。',
    '地図マニア：いたる所の地図を見る制御不可能な強迫的衝動。',
    '飛び降りマニア：高い場所から跳躍することへの執着。',
    '寒冷マニア：冷たさ、または冷たいもの、あるいはその両方への異常な欲望。',
    '舞踏マニア：踊ることへの愛好もしくは制御不可能な熱狂。',
    '睡眠マニア：寝ることへの過度の願望。',
    '基地マニア：墓地への執着。',
    '色彩マニア：特定の色への執着。',
    'ピエロマニア：ピエロへの執着。',
    '遭遇マニア：恐ろしい状況を経験したいという強迫的衝動。',
    '殺害マニア：殺害への執着。',
    '悪魔マニア：誰かが悪魔にとりつかれているという病的な信念。',
    '皮膚マニア：人の皮膚を引っぱりたいという強迫的衝動。',
    '正義マニア：正義が完遂されるのを見たいという執着。',
    'アルコールマニア：アルコールに関する異常な欲求。',
    '毛皮マニア：毛皮を所有することへの執着。',
    '贈り物マニア：贈り物を与えることへの執着。',
    '逃走マニア：逃走することへの迫的衝動。',
    '外出マニア：外を歩き回ることの強迫的衝動。',
    '自己中心マニア：不合理な自心の態度か自己崇拝。',
    '公職マニア：公的な職業に就きいという強欲な衝動。',
    '戦慄マニア：誰かが罪を犯したという病的な信念',
    '知識マニア：知識を得ることへ執着。',
    '静寂マニア：静寂であることへ強迫的衝動。',
    'エーテルマニア：エーテルへの切望',
    '求婚マニア：奇妙な求婚をすることへの執着。',
    '笑いマニア：制御不可能な笑うことへの強迫的衝動。',
    '魔術マニア：魔女と魔術への執着。',
    '筆記マニア：すべてを書き留めることへの執着。',
    '裸体マニア：裸になりたいという強迫的衝動。',
    '幻想マニア：快い幻想(現実とは関係なく)にとらわれやすい異常な傾向。',
    '蟲マニア：蟲に関する過度の嗜好。',
    '火器マニア：火器への執着。',
    '水マニア：水に関する不合理な渇望。',
    '魚マニア：魚への執着。',
    'アイコンマニア：像や肖像への執着。',
    'アイドルマニア：偶像への執着または献身。',
    '情報マニア：事実を集めることへの過度の献身。',
    '絶叫マニア：叫ぶことへの説明できない強迫的衝動。',
    '窃盗マニア：盗むことへの説明できない強迫的衝動。',
    '騒音マニア：大きな、あるいは甲高い騒音を出すことへの制御不可能な強迫的衝動。',
    'ひもマニア：ひもへの執着。',
    '宝くじマニア：宝くじに参加したいという極度の願望。',
    'うつマニア：異常に深くふさぎ込む傾向。',
    '巨石マニア：環状列石/立石があると奇妙な考えにとらわれる異常な傾向。',
    '音楽マニア：音楽もしくは特定の旋律への執着。',
    '作詩マニア：詩を書くことへの強欲な願望。',
    '憎悪マニア：何らかの対象あるいはグループの何もかもを憎む執着。',
    '偏執マニア：ただ1つの思想やアイデアへの異常な執着。',
    '虚言マニア：異常なほどにうそをついたり、誇張して話す。',
    '疾病マニア：想像上の病気に苦められる幻想。',
    '記録マニア：あらゆるものを記録に残そうという強迫的衝動。',
    '名前マニア：人々、場所、ものなどの名前への執着',
    '単語マニア：ある単語を繰り返したいという押さえ切れない欲求。',
    '爪損傷マニア：指の爪をむしったりはがそうとする強迫的衝動。',
    '美食マニア：1種類の食物への異常な愛。',
    '不平マニア：不平を言うことへの異常な喜び。',
    '仮面マニア：仮面や覆面を着けたいという強迫的衝動。',
    '幽霊マニア：幽霊への執着。',
    '殺人マニア：殺人への病的な傾向。',
    '光線マニア：光への病的な願望。',
    '放浪マニア：社会の規範に背きたいという異常な欲望。',
    '長者マニア：富への強迫的な欲望。',
    '病的虚言マニア：うそをつきたくてたまらない強迫的衝動。',
    '放火マニア：火をつけることへの強迫的衝動。',
    '質問マニア：質問したいという激しい強迫的衝動。',
    '鼻マニア：鼻をいじりたいという強迫的衝動。',
    '落書きマニア：いらずら書きや落書きへの執着。',
    '列車マニア：列車と鉄道旅行への強い魅了。',
    '知性マニア：誰かが信じられないほど知的であるという幻想。',
    'テクノマニア：新技術への執着。',
    'タナトスマニア：誰かが死を招く魔術によって呪われているという信念。',
    '宗教マニア：その人が神であるという信仰。',
    'かき傷マニア：かき傷をつけることへの強迫的衝動。',
    '手術マニア：外科手術を行なうことへの不合理な嗜好。',
    '抜毛マニア：自分の髪を引き抜くことへの切望。',
    '失明マニア：病的な視覚障害。',
    '異国マニア：外国のものへの執着。',
    '動物マニア：動物への正気でない溺愛。',
  ].freeze

  # 狂気のタレント表
  INSANE_TALENTS_TABLE = [
    '狂気的筋力：「私は無尽蔵の内なる力の蓄えを引き出す！」1つのSTRロールにボーナス・ダイスを1つ得る。ロールが失敗した場合、何かがうまくいかない。キーパーは、ヒーローが負傷した（1D3+ヒーローのDBのダメージを筋断裂等により受ける）か、働きかけたものが壊れるかを選ぶ。',
    '狂気的敏捷性：「私の手は目で見えるよりも素早く動く！」1つのDEXロールにボーナス・ダイスを1つ得る。ロールに失敗した場合、何かがうまくいかない。キーパーは、ヒーローが負傷した（1D4のダメージを受ける）か、彼らが働きかけていたものを壊してしまう。',
    '狂気的精神力：「私を流れるパワーを感じることができる！」1つのPOWロールにボーナス・ダイスを1つ得る。ロールに失敗した倍、何かがうまくいかない。キーパーは、ヒーローが意識を失うか、達成しようとしていた効果が、意図していた以上にかなり危険になる。',
    '狂気的体力：「歯軋りをしても痛みを感じない！」かなりのダメージを受けたときに、ヒーローはCONロールをすることを選ぶかもしれない。成功すれば、苦痛に耐え、ダメージを半減させる。ロールに失敗した場合は、ロールしたダメージを受け、地面へと倒れ、1D3ラウンド無能力化される。',
    '狂気的外見：「くそ、私がかわい子ちゃんに！」ヒーローは、どういうわけかとても違って見える。これは純粋に表情と姿勢に現れるか、あるいは彼らの服や髪が何か根本的に時間をかけて変わる（服が魔法のように変わるのではなく、彼らが自分で変える）。APPや魅惑や言いくるめなどの彼らの外見によって影響を受けるかもしれないロールにボーナス・ダイスを1つ得る。この効果は短命だが、1つのシーンや会議などの一定の時間内の全ての交流に適応される。『改善された』外見のためにこのボーナス・ダイスを使用し、ロールに失敗した場合、彼らは社会的な不名誉や悪い結果に苦しめられることになる。',
    '狂気的回想力：「私は全てを完全に覚えている！」ヒーローがこれまでに聞いた事実と記憶をすぐに手に入れられる。顔、数字、細部の情報が、情報の洪水の中で彼らの精神に押し寄せてくる。ヒーローが一度聞いたあるいは見たことのありそうな情報を思い出そうとする時の、EDUか知識か技能ロール1つにボーナス・ダイスを1つ得る。ロールに失敗した場合、情報の洪水は多すぎた！1正気度ポイントを失い、1つの狂気の発作に苦しむ。ヒーローがまだ狂気でないのであれば、彼らは今や一時的な狂人となる。',
    '狂気的スピード：「私を見ろ、私は弾丸よりも早いぞ！」1つのチェイスに入った時に、ヒーローは移動率を決めるためのCONロールにボーナス・ダイスを1つ得る。ロールが成功すれば、1移動率が上がる。ロールが極限の成功をした場合には、2上がる。ロールが失敗した場合は、彼らは何かをしくじって、少なくとも1D3回の行動を失う。',
    '狂気的運転手：「今や私を止められるものなど誰もいない！」あるチェイスにおけるヒーローの全ての運転ロールにボーナス・ダイスを1つ得る。運転ロールが失敗した場合、彼らはどういうわけか（キーパーの裁量で）車両のコントロールを失う。',
    '狂気的言語：「いやはや、スワヒリ語の勉強をこれまでしたことはないのですが、これは難しいのでしょうかね？」ヒーローは短期間、全ての現代の言語（あるいは古風なある言語、またはあるクトゥルフ神話の言語）を一時的に理解する。この効果は魔道書を最初に読んだり、会話を行ったり、スピーチを聞けるくらいに十分な長さがある。事実上の技能としては75％だ。新たな言語の使用に技能ロールが必要な場合、その失敗は、ヒーローが1D6日間の間母国語を忘れ、その時に使用された新たな言語が代わりに母国語になるということを意味する。',
    '狂気的精度：「私には当たる気しかしないよ！」ヒーローは彼らの銃が空になるまで、全ての火器ロールにボーナス・ダイスを1つ得る。彼らの射撃がターゲットの1つに当たらないか、弾薬がなくなるまで、ボーナス・ダイスを使い続けることができる。その当たらなかった弾丸は当たって欲しくないものに当たる（味方の1人かすごく価値のある何かに、極限の成功（貫通）をしたかのようにダメージを与える）。',
    '狂気的脅し：「お前、俺が愉快なんだと思うかい？どこが愉快なんだ？」ヒーローは威圧ロールにボーナスを1つ得る。ロールに失敗した場合、彼らは短期間彼らの行動を制御できなくなる。キーパーが何が起こるか（彼らが暴力的に激怒する（会話している人にダメージを与える可能性がある）か、見くびられ恥を受けるか）を決める。',
    '狂気的回避：「蝶のように舞う！」ヒーローは回避ロールに失敗するまで、現在の戦闘シーンにおける全ての回避ロールにボーナス・ダイスを1つ得る。この失敗は、攻撃に自ら突っ込んでいくことを示しており、その場合、攻撃が極限の成功を収めたかのようにダメージを受ける。',
    '狂気的方向感覚：「ついて来て、こっちがそうだよ！」ヒーローのプレイヤーはキーパーに彼らがどこに行きたいのか、あるいは何に向かいたいのかを伝える。キーパーはこれが達成されるであろう方向を示す。ヒーローは幸運ロールをし、ロールに失敗した場合は、彼らは何かしらの種類の罠や危険な遭遇へと直進していく。',
    '狂気的理解：「ああ、今それが分かった！」ヒーローのプレイヤーはプロットに関する質問をすることができる。「なぜ敵が～をしているの？」、「敵は～によって達成しようとしていることは何です？」、「我々が敵の計画を妨害することができる最良の行動は何です？」、「敵の最大の弱点は何です？」などだ。質問はかなり具体的でなければならず、キーパーは正直に答えるべきである。このタレントは一度しか使用できず、使用すれば失われる。',
    '狂気的視界：「光？誰が必要なんだい？」ヒーローは1つの目星ロールにボーナス・ダイスを1つ得る。完全な暗闇の中でさえも、彼らは夕暮れのようにロールすることができる。ロールに失敗した場合、キーパーは、目が敏感になりすぎて痛みが生じる（1D10ラウンドの間事実上に盲目になる）、またはこれから1時間妄想に悩ませられることになるかを決定する。',
    '狂気的聴覚：「みんな静かにして、何かカチカチ音がしない？」ヒーローは、1つの聞き耳ロールにボーナス・ダイスを1つ得る。周囲の騒音や他の音によらずに、彼らはその中で最も静かな音でさえも拾うことができる。キーパーは、何らかの突発的なノイズが1D10分間彼らを聴覚障害にするか、またはこれから1時間聴覚的な妄想にとらわれるかを決定する。',
    '狂気的隠密：「私のこと見えてないんだよね？」ヒーローは1つのステルスロールにボーナス・ダイスを1つ得る。彼らは猫のような優雅さで移動し、丸見えのような場所にさえ隠れようとするかもしれない。ロールが失敗したのであれば、彼らは誤って何かを壊したり、大きな騒ぎを引き起こす。',
    '狂気的獰猛さ：「お前を粉みじんに叩き切ってみせるぜ！」ヒーローは全ての近接攻撃のダメージロールを2回行い、最良の結果を得る。欠点としては、いったん命中すると彼らは止められないことだ！彼らは最後の一撃を与えるまで、攻撃し続ける。これを止めるための方法は2つしかない。彼らが意識不明になるか、誰かが困難難易度の言いくるめか、魅惑か、威圧ロールを彼らに成功させた場合がそうだ（1戦闘ラウンドで、1人の人物のみがこれらの状態のヒーローの1人に試みることができる）。',
    '狂気的技能増強：「あんたは私が狂ってると思うのか？だがあんたに教えることができるぞ！」狂気の副作用として、ヒーローはクトゥルフ神話のいくつかの側面を伴う、彼らの技能の1つ（プレイヤーが選び、キーパーが許可を与えたもの）を強化することができる。これはその技能で達成できることの範囲に影響する。ハーバート・ウェストとクロフォード・ティリンギャーストの両方が、これがどのようにその人物に影響を与えるかについての事前研究の良い候補者となる。',
    '狂気的技能増強：「あんたは私が狂ってると思うのか？だがあんたに教えることができるぞ！」狂気の副作用として、ヒーローはクトゥルフ神話のいくつかの側面を伴う、彼らの技能の1つ（プレイヤーが選び、キーパーが許可を与えたもの）を強化することができる。これはその技能で達成できることの範囲に影響する。ハーバート・ウェストとクロフォード・ティリンギャーストの両方が、これがどのようにその人物に影響を与えるかについての事前研究の良い候補者となる。',
  ].freeze
end
