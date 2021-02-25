# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class AlchemiaStruggle < Base
      ID = "AlchemiaStruggle"
      NAME = "アルケミア・ストラグル"
      SORT_KEY = "あるけみあすとらくる"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ ダイスロール（ xAS ）
          xDをロールします。
          例） 5AS

        ■ ダイスロール＆最大になるようにピック（ xASy ）
          xDをロールし、そこから最大になるようにy個をピックします。
          例） 4AS3

        ■ ウルダイスの獲得（ xUL ）
          xDのウルダイスを振り、出た出目の個数をNo.ごとにカウントします。
          例） 6UL

        ■ 表
          ・奇跡の触媒
            ・エレメント (CELE, CElement)
            ・アルケミア (CALC, CAlchemia)
            ・インフォーマント (CINF, CInformant)
            ・イノセンス (CINN, CInnocence)
            ・アクワイヤード (CACQ, CAcquired)
          ・携行品
            ・Ｓサイズ (ARS, ArticleS)
            ・Ｍサイズ (ARM, ArticleM)
            ・Ｌサイズ (ARL, ArticleL)
          ・ＰＣ情報獲得表 (PCI, PCInformation)
          ・理由表 (REA, Reason)
          ・交流表 (ASS, Associate)
          ・接触のきっかけ表 (CON, Contact)
      MESSAGETEXT

      ROLL_REG = /^(\d+)AS(\d+)?$/i.freeze

      register_prefix('\d+AS', '\d+UL')

      def initialize(command)
        super(command)

        @sort_add_dice = true # 加算ダイスのソート有
        @sort_barabara_dice = true # バラバラダイスでソート有
        @round_type = RoundType::CEIL # 割り算をした時の端数切り上げ
      end

      def eval_game_system_specific_command(command)
        c = ALIAS[command] || command

        try_roll_alchemia(c) ||
          try_roll_uldice(c) ||
          roll_tables(c, TABLES)
      end

      def try_roll_alchemia(command)
        match = ROLL_REG.match(command)
        return nil unless match

        roll_dice_count = match[1].to_i

        if match[2].nil?
          # ロールのみ（ピックなし）:

          result = roll_alchemia(roll_dice_count)
          return make_roll_text(result)
        else
          # ロールして最大値をピック:

          pick_dice_count = match[2].to_i

          result = roll_alchemia_and_pick(roll_dice_count, pick_dice_count)
          return make_roll_and_pick_text(result[:rolled_dices], pick_dice_count, result[:picked_dices])
        end
      end

      def try_roll_uldice(command)
        match = /^(\d+)UL$/.match(command)
        return nil unless match

        roll_dice_count = match[1].to_i
        dice_list = @randomizer.roll_barabara(roll_dice_count, 6).sort
        dice_list_text = dice_list.join(",")

        result = dice_list.group_by(&:itself)
                          .map { |k, v| "No.#{k}: #{v.size}個" }
                          .join(", ")

        sequence = [
          "(#{roll_dice_count}D6)",
          "[#{dice_list_text}]",
          result
        ]

        sequence.join(" ＞ ")
      end

      def roll_alchemia(roll_dice_count)
        @randomizer.roll_barabara(roll_dice_count, 6)
      end

      def roll_alchemia_and_pick(roll_dice_count, pick_dice_count)
        rolled_dice_list = roll_alchemia(roll_dice_count)

        return {
          rolled_dices: rolled_dice_list,
          picked_dices: pick_maximum(rolled_dice_list, pick_dice_count),
        }
      end

      def pick_maximum(dice_list, pick_dice_count)
        if dice_list.size <= pick_dice_count
          dice_list
        else
          dice_list.sort.pop(pick_dice_count)
        end
      end

      def make_roll_text(rolled_dice_list)
        "(#{rolled_dice_list.size}D6) ＞ #{make_dice_text(rolled_dice_list)}"
      end

      # 実際にピックできた数と要求されたピック数は一致しないケースが（ルール上）あるため、 pick_dice_count はパラメータとして受ける必要がある。
      def make_roll_and_pick_text(rolled_dice_list, pick_dice_count, picked_dice_list)
        "(#{rolled_dice_list.size}D6|>#{pick_dice_count}D6) ＞ #{make_dice_text(rolled_dice_list)} >> #{make_dice_text(picked_dice_list)} ＞ #{picked_dice_list.sum}"
      end

      def make_dice_text(dice_list)
        "[#{dice_list.sort.join ', '}]"
      end

      CATALYST_TABLES = {
        'CElement' => DiceTable::Table.new(
          "奇跡の触媒（エレメント）",
          "1D6",
          [
            "ワンド",
            "水晶玉",
            "カード",
            "ステッキ",
            "手鏡",
            "宝石",
          ]
        ),
        'CAlchemia' => DiceTable::Table.new(
          "奇跡の触媒（アルケミア）",
          "1D6",
          [
            "指輪",
            "ブレスレット",
            "イヤリング",
            "ネックレス",
            "ブローチ",
            "ヘアピン",
          ]
        ),
        'CInformant' => DiceTable::Table.new(
          "奇跡の触媒（インフォーマント）",
          "1D6",
          [
            "スマートフォン",
            "タブレット",
            "ノートパソコン",
            "無線機（トランシーバー）",
            "ウェアラブルデバイス",
            "携帯ゲーム機",
          ]
        ),
        'CInnocence' => DiceTable::Table.new(
          "奇跡の触媒（イノセンス）",
          "1D6",
          [
            "手袋",
            "笛",
            "靴",
            "鈴",
            "拡声器",
            "弦楽器",
          ]
        ),
        'CAcquired' => DiceTable::Table.new(
          "奇跡の触媒（アクワイヤード）",
          "1D6",
          [
            "ボタン",
            "音声",
            "モーション",
            "脳波",
            "記録媒体",
            "ＡＩ",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      ARTICLE_TABLES = {
        'ArticleS' => DiceTable::D66Table.new(
          "携行品（Ｓサイズ）",
          D66SortType::ASC,
          {
            11 => "マッチ",
            12 => "ペットボトル",
            13 => "試験管",
            14 => "団扇",
            15 => "植物",
            16 => "ハンカチ",
            22 => "化粧用具",
            23 => "ベルト",
            24 => "タバコ",
            25 => "チェーン",
            26 => "電池",
            33 => "お菓子",
            34 => "針金",
            35 => "コイン",
            36 => "ナイフ",
            44 => "カトラリー",
            45 => "砂",
            46 => "スプレー",
            55 => "石",
            56 => "文房具",
            66 => "ペンライト",
          }
        ),
        'ArticleM' => DiceTable::D66ParityTable.new(
          "携行品（Ｍサイズ）",
          [
            "本",
            "傘",
            "金属板",
            "花火",
            "エアガン",
            "包帯",
          ],
          [
            "工具",
            "ジャケット",
            "ロープ",
            "人形",
            "軽食",
            "ガラス瓶",
          ]
        ),
        'ArticleL' => DiceTable::D66ParityTable.new(
          "携行品（Ｌサイズ）",
          [
            "木刀",
            "釣り具",
            "自転車",
            "バット",
            "寝袋",
            "丸太",
          ],
          [
            "物干し竿",
            "鍋",
            "スケートボード",
            "シャベル（スコップ）",
            "タンク",
            "脚立",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      DRAMA_SEQUENCE_TABLES = {
        'PCInformation' => DiceTable::D66ParityTable.new(
          "ＰＣ情報獲得表",
          [
            "前の場面の直後 ―― 直前にやり取りをしていた場所。聞きたいことを突きつける頃合いかもしれない。",
            "自分の拠点 ―― 自分の心身を休められる場所。こちらのペースに引き込み、ゆさぶりをかける。",
            "相手の拠点 ―― 相手が生活の基点にしている場所。相手のペースに呑まれないよう、慎重にいこう。",
            "自学派の拠点 ―― 自分が学派の仲間と共に使用する場所。仲間に手は出させず、あくまでプレッシャーを与えるだけにしてもらう。",
            "カフェ、バー ―― 厳かな空気に包まれた大人の場所。ここで声を荒げるのは紳士的ではない。",
            "路地裏 ―― 建物と建物の間や、人通りの少ない裏通り。多少手荒な手段に出ても目立ちはしないだろう。",
          ],
          [
            "廃墟 ―― 廃ビル、廃工場のような人が立ち入らない場所。おあつらえ向きの場所を用意してやった。",
            "公共交通機関 ―― バス、電車など。昼夜問わず多くの人が利用する乗り物。敢えて人目に付く場所で詰め寄り、動揺を誘う。",
            "雑木林 ―― 草木が揺れる音、虫や鳥の鳴き声だけが聞こえる。そこに邪魔する者はいない。",
            "夜の公園 ―― 寝静まった街の公園。街灯に照らされない場所なら目立つこともないだろう。",
            "駐車場 ―― 立体、平面、地下を問わず車を停める場所。人の出入りの激しさに対し、そこに留まる人は少ない。目撃者も多くはないだろう。",
            "高架下 ―― 線路、道路の橋の下。響く騒音が自分たちの存在を薄めてくれる。",
          ]
        ),
        'Reason' => DiceTable::Table.new(
          "理由表",
          "1D6",
          [
            "不信感 ―― 行動や言動になにか釈然としない部分を感じる。白黒はっきりさせよう。",
            "好奇心 ―― 相手のことを知りたいと掻き立てられる。知りたい気持ちを抑えられない。",
            "庇護感 ―― 知古の姿を重ねて守りたくなってしまう。信頼関係を君と築くため、踏み込んだところまで知っておきたい。",
            "嫌悪感 ―― 理由はないけど気に食わない。情報のアドバンテージを握ることで優位に立てるはずだ。",
            "偏愛 ―― 愛ゆえに知りたくなってしまう。君の思考、目的、感情のすべてを手に入れたい。",
            "直感 ―― 根拠はないが、なにか隠している気がする。一か八か、勝負に出よう。",
          ]
        ),
        'Associate' => DiceTable::D66ParityTable.new(
          "交流表",
          [
            "前の場面の直後 ―― 直前にやり取りをした場所。ちょっと一息つくものいいだろう。",
            "自分の拠点 ―― 自分の心身を休められる場所。一緒にくつろぎながら話をしよう。",
            "相手の拠点 ―― 相手が生活の基点にしている場所。ちょっとお邪魔させてもらえないだろうか？",
            "相手学派の拠点 ―― 相手が学派の仲間と共に使用する場所。若干の居心地悪さはあるが、好感を持ってもらうためには我慢も必要。",
            "食事処 ―― ファミレス、居酒屋など。人でにぎわう食事処。気軽に飲み食いできる空間で、話も弾むはず。",
            "アミューズメント施設 ―― カラオケ、ボーリング、ゲームセンターなどの娯楽施設。遊べば人となりがわかる。手っ取り早くいこう。",
          ],
          [
            "お祭り ―― 老若男女が参加するイベント。非日常的な空気を楽しむことで、気分転換もできるだろう。",
            "昼間の公園 ―― 散歩する人や子連れの家族で溢れる公園。僕らにもああやって生きる道があったのだろうか。",
            "思い出の場所 ―― 自分にとって思い入れのある大事な場所。この人になら胸の内を明かしてもいい気分になった。",
            "スポーツ観戦 ―― 野球、サッカー、バスケなど。プロアマ問わず観戦する。手に汗握る展開を共に見届けよう。",
            "屋上 ―― 街と人を見下ろす眺めのいい場所。この景色を君は喜ぶだろうか、怖がるだろうか。",
            "ショッピング ―― 大型商業施設やショッピングストリートに向かう。互いの興味があるものを知るいい機会だ。",
          ]
        ),
        'Contact' => DiceTable::Table.new(
          "接触のきっかけ表",
          "1D6",
          [
            "体勢を崩す ―― 転びそうになったところを支える、支えられる。",
            "付着物をとる ―― 髪や服についているゴミ、汚れをとってあげる。",
            "思わず手が出る ―― 言葉より先に、強めに手が出てしまう。",
            "物ごしに触れる ―― 物を渡す、拾う際に指先同士がぶつかる。",
            "友好のサイン ―― 肩を組む、握手をする、ハグをするなど。",
            "ケアをしてあげる ―― 髪をとかす、肩をもむ、頭を撫でる。相手を労ってする行為全般。",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      TABLES =
        CATALYST_TABLES.merge(ARTICLE_TABLES).merge(DRAMA_SEQUENCE_TABLES)

      alias_catalyst_tables = CATALYST_TABLES.keys.map { |key| [key[0, 4], key] }.to_h
      alias_article_tables = ARTICLE_TABLES.keys.map { |key| [key[0, 2] + key[-1], key] }.to_h
      alias_drama_sequence_tables = DRAMA_SEQUENCE_TABLES.keys.map { |key| [key[0, 3], key] }.to_h

      ALIAS = alias_catalyst_tables.merge(alias_article_tables).merge(alias_drama_sequence_tables).freeze

      register_prefix(ALIAS.keys, TABLES.keys)
    end
  end
end
