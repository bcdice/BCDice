# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class KizunaBullet < Base
      ID = "KizunaBullet"
      NAME = "キズナバレット"
      SORT_KEY = "きすなはれつと"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■最大値（ｘＤ）ダイスロール
        max:xD  または  max(xD)

        □調査判定
        max:xD>=5  または  max(xD)>=5

        □作戦判定（調査値ｙ，脅威度ｚ）
        max:xD+y>=z  または  max(xD)+y>=z

        ■表
        日常表・場所  DLL
        日常表・内容  DLA
        交流表・場所  INL
        交流表・内容  INT
        ターンテーマ表  TTM
        調査表・ベーシック  RSB
        調査表・ダイナミック  RSD
        ハザード効果表  HAZ
      MESSAGETEXT

      MAX_DICE_ROLL_RE = /^max(:(\d+)d6?|\((\d+)d6?\))(\+\d+)?((>=|=>)(\d+))?$/i.freeze

      register_prefix('max[:(]\\d+D')

      def initialize(command)
        super(command)
        @round_type = RoundType::CEIL
        @sort_barabara_dice = true
      end

      def eval_game_system_specific_command(command)
        max_dice_roll(command) ||
          roll_tables(command, TABLES)
      end

      def max_dice_roll(command)
        parsed = self.class.parse_max_dice_roll_command(command)
        return nil if parsed.nil?

        dice_number = parsed[:dice_number]
        return nil if dice_number.zero?

        dices = @randomizer.roll_barabara(dice_number, 6)
        max = dices.max
        total = max

        offset = parsed[:offset]
        threshold = parsed[:threshold]

        result = "(#{self.class.rebuild_command(dice_number, offset, threshold)}) ＞ [#{dices.join(',')}] ＞ #{max}"

        unless offset.nil?
          total += offset
          result = "#{result}+#{offset} ＞ #{total}"
        end

        unless threshold.nil?
          success = total >= threshold
          result = Result.new("#{result} ＞ #{success ? '成功' : '失敗'}").tap do |r|
            r.condition = success
          end
        end

        result
      end

      def self.parse_max_dice_roll_command(command)
        m = MAX_DICE_ROLL_RE.match(command)
        return nil if m.nil?

        {
          dice_number: (m[2] || m[3]).to_i,
          offset: m[4].nil? ? nil : m[4].to_i,
          threshold: m[7].nil? ? nil : m[7].to_i,
        }
      end

      def self.rebuild_command(dice_number, offset, threshold)
        command = "max:#{dice_number}D"
        command += "+#{offset}" unless offset.nil?
        command += ">=#{threshold}" unless threshold.nil?
        command
      end

      # ダイスを２回振って12通りの結果を得るテーブル.
      class KizunaBullet_12_Table < DiceTable::D66HalfGridTable
        def initialize(name, items)
          super(
            name,
            items[0...6],
            items[6...12]
          )
        end

        def roll(randomizer)
          roll_result = super(randomizer)

          # ルールブックでの記述が、いわゆる“D66”ではないので、結果を D66 ライクではない形に整形する.
          "#{roll_result.table_name}(#{roll_result.value / 10},#{roll_result.value % 10}) ＞ #{roll_result.body}"
        end
      end

      TABLES = {
        'DLL' => DiceTable::Table.new(
          "日常表・場所",
          "1D6",
          [
            "ケージ → ハウンドの私室にオーナーがお邪魔している。",
            "公園 → 緑地公園、運動公園、あるいは小さな広場など。",
            "病院 → 組織の管理下にある病院、あるいは医務室など。",
            "オーナーの家 → オーナーの家に、ハウンドがお邪魔している。",
            "訓練場 → 武道場、ジム、体育館、あるいは射撃場など。",
            "資料室 → 組織の資料室や書庫、証拠品の保管庫など。",
          ]
        ),
        'DLA' => DiceTable::Table.new(
          "日常表・内容",
          "1D6",
          [
            "仕事／勉強 → 片方の仕事や勉強を、もう片方が手伝っている。",
            "ゲーム → ふたりでゲームを楽しんでいる。",
            "趣味 → 片方の趣味にもう片方がつきあっている。",
            "食事 → 食事をとっている。もしくは料理をしている。",
            "掃除／整頓 → ふたりで、その場の掃除や整頓を行なっている。",
            "訓練／手入れ → 戦闘訓練や、武器の手入れなどを行なっている。",
          ]
        ),
        'INL' => DiceTable::Table.new(
          "交流表・場所",
          "1D6",
          [
            "カフェ → お洒落なカフェ。一息つくには丁度いい。",
            "路地裏 → 薄暗い路地裏。少なくとも人目は気にならない。",
            "公園 → 解放感のある公園。自動販売機もある。",
            "拠点 → 組織が管理している隠れ家。安全な場所だ。",
            "車内 → 車や電車の中。他の人がいるなら声量には気をつけて。",
            "屋上 → 街を見下ろせるビルの屋上。風が気持ちいい。",
          ]
        ),
        'INT' => DiceTable::Table.new(
          "交流表・内容",
          "1D6",
          [
            "下準備 → 次の調査や、戦いに向けた下準備を進めよう。",
            "被害者 → 事件や標的に被害を受けた人について話そう。",
            "ひと休み → 円滑な任務遂行のためには、ひと休みも必要だ。",
            "次の予定 → この事件が終わった後のスケジュールを決めよう。",
            "気付いたこと → 調査活動の中で気付いたことを話し合ってみよう。",
            "敵 → 事件の犯人や標的などについて話し合ってみよう。",
          ]
        ),
        'TTM' => KizunaBullet_12_Table.new(
          "ターンテーマ表",
          [
            "感謝 → パートナーへ感謝の言葉を送ろう。円滑な関係には、こういうことも必要だ。",
            "協力 → パートナーと力を合わせる必要がある。どんな役割分担がよいだろう？",
            "思い出作り → 調査のついでに、パートナーと思い出を作ろう。いい思い出になるかな？",
            "終わったら…… → この仕事が終わったら、なにをしようか。パートナーと相談してみよう。",
            "相手の調子 → パートナーの調子はどうだろうか？　少し注意して、相手を観察してみよう。",
            "気になっていたこと → パートナーについて、前から気になっていたこと。この機会に、尋ねてよう。",
            "エンジョイ！ → どんな時でも、楽しむことが大切だ！　調査も大事だが、楽しいことを探そう。",
            "言えなかったこと → いつか言おうと思っていたこと。この機会に、打ち明けられるだろうか。",
            "新しい挑戦 → 苦手なこと、未経験のことでも、挑戦が大切だ。パートナーの力を借りるのもいい。",
            "サプライズ → パートナーには秘密で、何かを用意してみよう。驚く顔が見られるかもしれない。",
            "まだ知らない一面 → パートナーの、まだ知らない一面が見られるかも。相手の様子を観察してみよう。",
            "ほしかった物 → 調査のついでに、ほしかった物を探してみよう。意外な場所で手に入るかも。",
          ]
        ),
        'RSB' => KizunaBullet_12_Table.new(
          "調査表・ベーシック",
          [
            "遺留品 → 現場に残された遺留品や、押収された品などを、しっかり調べてみよう。",
            "聞き込み（繁華街） → 繁華街の店員や通行人に聞き込みをしてみよう。小さな違和感や気がかりがヒントになるかも。",
            "過去の洗い直し → 標的が起こした過去の事件や、活動の履歴を、しっかり洗い直してみよう。",
            "情報屋（取引） → 裏社会の事情に通じている情報屋と会おう。うまく折り合いがつけば情報を手に入れられるかも。",
            "ウェブ調査 → インターネットを使って情報を集めてみよう。ＳＮＳの書き込みや噂も、なかなか馬鹿にできない。",
            "報告の整理 → バックアップの調査員から報告が集まっている。話を聞きに行くか、書類に目を通してみよう。",
            "ハッキング → 標的に関係がありそうな組織や施設のコンピュータに、ハッキングを仕掛けてみよう。",
            "聞き込み（学生） → 街で学生たちに聞き込みをしてみよう。彼らの情報網は意外と馬鹿にならないものだ。",
            "専門家を訪問 → 事件や標的に関連のある専門家を訪ねよう。うまく話せば有益なヒントが得られるかも。",
            "現場検証 → 事件の現場や、標的が目撃された場所に、なにか手がかりが残っていないか調べてみよう。",
            "聞き込み（港湾部） → 港や倉庫が集まる地域で聞き込みをしてみよう。不審な積み荷や業者などの情報が得られるかも。",
            "謎の電話 → 関係者を名乗る謎の電話がかかってきた。うまく話を聞き出すことはできるだろうか？",
          ]
        ),
        'RSD' => KizunaBullet_12_Table.new(
          "調査表・ダイナミック",
          [
            "突然の抗争 → 聞き込みに訪れた店で銃撃戦が発生した。やめさせるか、全員ぶちのめして話を聞くとしよう。",
            "色仕掛け → 重要な情報を持っていそうな人物を見つけた。ここはひとつ、色仕掛けで話を聞き出してみよう。",
            "返り討ち（個人） → あなたたちに因縁のある人物が襲いかかってきた。返り討ちのついでに、何か話を聞き出せるだろうか。",
            "血の代償 → 情報の代価に邪魔な人物の“処分”を提示された。実行するか、別の条件を提示する必要がある。",
            "聞き込み（裏社会） → 裏社会に属する犯罪組織へ、聞き込みに行こう。ちょっと荒っぽい行動が必要になるかもしれない。",
            "返り討ち（集団） → あなたたちに因縁のある集団が襲いかかってきた。返り討ちのついでに、何か話を聞き出せるだろうか。",
            "力試し → 情報の代価に、腕試しや度胸試しを提示された。提案に乗るか、他の条件を提示する必要がある。",
            "襲撃（アジト） → 情報を持っていそうな犯罪者や犯罪組織。そのアジトを襲撃して、情報を漁ることにした。",
            "聞き込み（裏市場） → 盗品や横流し品などを扱う裏市場。ここでなら有益な情報を得られるかもしれない。",
            "情報屋（脅迫） → いい情報を持っているかもしれない情報屋。弱みを握って脅迫すれば、簡単に口を割るだろう。",
            "襲撃（取引現場） → 偶然にも、密輸品の取引現場に遭遇した。こいつらをぶちのめしたら、情報を得られるかも。",
            "逃走劇 → 情報を持っていそうな人物が逃げ出した。追いかけて捕まえて、お話をしてもらおう。",
          ]
        ),
        'HAZ' => DiceTable::Table.new(
          "ハザード効果表",
          "1D6",
          [
            "不活性化 → 【励起値】がもっとも高いＰＣが、【励起値】を１点失う。",
            "キセキ増強 → ［決戦］でエネミーが与えるダメージに＋３する。",
            "小さな事故 → ＰＣひとり（任意に決定）が【耐久値】を［１Ｄ］失う。",
            "強まるネガイ → ［決戦］でエネミーの初期【生命値】が１点増加する。",
            "大きな事故 → ＰＣ全員が【耐久値】を［１Ｄ］失う。",
            "悪運強し → なんたる幸運！　何も発生しない。",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      register_prefix(TABLES.keys)
    end
  end
end
