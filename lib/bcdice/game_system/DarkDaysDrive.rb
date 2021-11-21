# frozen_string_literal: true

module BCDice
  module GameSystem
    class DarkDaysDrive < Base
      # ゲームシステムの識別子
      ID = 'DarkDaysDrive'

      # ゲームシステム名
      NAME = 'ダークデイズドライブ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'たあくていすとらいふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        スペシャル／ファンブル／成功／失敗を判定
        ・各種表
        RTTn ランダム特技決定表(n：分野番号、省略可能)
        RCT  ランダム分野決定表
        ABRT アビリティ決定表
        DT ダメージ表
        FT 失敗表
        GJT 大成功表
        ITT 移動トラブル表
        NTT 任務トラブル表
        STT 襲撃トラブル表
        HTT 変身トラブル表
        DET ドライブイベント表
        BET ブレイクイベント表
        CT キャンプ表
        KZT 関係属性表
        IA イケメンアクション決定表
         IAA 遠距離 IAB 移動 IAC 近距離 IAD 善人 IAE 悪人
         IAF 幼い IAG バカ IAH 渋い IAI 賢い IAJ 超自然
        IAX イケメンアクション決定表 → IA表
        
        ■本格的な戦闘
        CAC センターの行動決定
        DDC 対話ダメージ表
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)
        @d66_sort_type = D66SortType::ASC
      end

      # ゲーム別成功度判定(2D6)
      def result_2d6(total, dice_total, _dice_list, cmp_op, target)
        return nil unless cmp_op == :>=

        if dice_total <= 2
          Result.fumble("ファンブル(判定失敗。失敗表(FT)を追加で１回振る)")
        elsif dice_total >= 12
          Result.critical("スペシャル(判定成功。大成功表(GJT)を１回使用可能)")
        elsif target == "?"
          Result.nothing
        elsif total >= target
          Result.success("成功")
        else
          Result.failure("失敗")
        end
      end

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES) ||
          command_iax(command) ||
          RTT.roll_command(randomizer, command)
      end
      
      private
      
      def command_iax(command)
        return nil unless command == "IAX"
        ia = TABLES["IA"].choise(@randomizer.roll_d66(D66SortType::ASC))
        m = ia.body.match(/\((.+?)\)/)
        return ia unless m
        ia2 = TABLES[m[1]].choice(@randomizer.roll_once(6))
        return "#{ia} ＞ #{ia2}"
      end

      RTT = DiceTable::SaiFicSkillTable.new(
        [
          ['背景', ['呪い', '絶望', '孤児', '死別', '一般人', '獲物', '憧れ', '友人', '挑戦者', '血縁', '永遠']],
          ['仕事',  ['脅迫', '捨てる', '拉致', '盗む', 'ハッキング', '侵入', '変装', 'だます', '隠す', 'のぞく', '聞き出す']],
          ['捜索',  ['トイレ', '食事', '自然', '運動施設', '街', '友愛会', '暗部', '史跡', '文化施設', '温泉', '宿泊']],
          ['趣味',  ['お酒', 'グルメ', 'ダンス', 'スポーツ', '健康', 'ファッション', '恋愛', 'フェス', '音楽', '物語', '学問']],
          ['雰囲気',  ['だらしない', 'のんびり', '暖かい', '明るい', '甘い', '普通', '洗練', '渋い', '静か', '真面目', '冷たい']],
          ['戦闘法',  ['忍術', '古武術', '剣術', '棒術', '拳法', 'ケンカ', '総合格闘技', 'レスリング', '軍隊格闘術', '射撃', '弓術']],
        ],
        rtt_format: "ランダム指定特技表(%<category_dice>d,%<row_dice>d) ＞ %<category_name>s《%<skill_name>s》"
      )
      TABLES = {

        "ABRT" => DiceTable::D66Table.new(
          "アビリティ決定表",
          D66SortType::ASC,
          {
            11 => "インストラクター(P155)",
            12 => "運送業(P155)",
            13 => "運転手(P155)",
            14 => "カフェ店員(P155)",
            15 => "趣味人(P155)",
            16 => "ショップ店員(P155)",
            22 => "正社員(P156)",
            23 => "大工(P156)",
            24 => "探偵(P156)",
            25 => "バイヤー(P156)",
            26 => "俳優(P156)",
            33 => "派遣社員(P156)",
            34 => "犯罪者(P157)",
            35 => "バンドマン(P157)",
            36 => "バーテンダー(P157)",
            44 => "ヒモ(P157)",
            45 => "ホスト(P157)",
            46 => "ホテルマン(P157)",
            55 => "無職(P158)",
            56 => "用心棒(P158)",
            66 => "料理人(P158)"
          }
        ),
        "DT" => DiceTable::Table.new(
          "ダメージ表",
          "1D6",
          [
            "疲れ",
            "痛み",
            "焦り",
            "不調",
            "ショック",
            "ケガ"
          ]
        ),
        "FT" => DiceTable::Table.new(
          "失敗表",
          "1D6",
          [
            "任意のアイテムを一つ失う",
            "１ダメージを受ける",
            "【所持金ランク】が１減少する（最低０）",
            "２ダメージを受ける",
            "【所持金ランク】が２減少する（最低０）",
            "標的レベルが１増加する"
          ]
        ),
        "GJT" => DiceTable::Table.new(
          "大成功表",
          "1D6",
          [
            "主人からお褒めの言葉をいただく",
            "ダメージを１回復する",
            "ダメージを１回復する",
            "関係のチェックを一つ消す",
            "ダメージを２回復する",
            "【所持金ランク】が１増加する"
          ]
        ),
        "ITT" => DiceTable::Table.new(
          "移動トラブル表",
          "1D6",
          [
            "検問（P220)",
            "急な腹痛（P220)",
            "黒煙（P221)",
            "蚊（P221)",
            "落とし物（P222)",
            "空腹（P222)"
          ]
        ),
        "NTT" => DiceTable::Table.new(
          "任務トラブル表",
          "1D6",
          [
            "通報（P223)",
            "プレッシャー（P223)",
            "マナー違反（P224)",
            "志願者（P224)",
            "仲間割れ（P225)",
            "狩人の噂（P225)"
          ]
        ),
        "STT" => DiceTable::Table.new(
          "襲撃トラブル表",
          "1D6",
          [
            "孤独な追跡者（P226)",
            "地元の若者たち（P226)",
            "V-FILES（P227)",
            "チンピラの群れ（P227)",
            "孤独な狩人（P228)",
            "狩人の群れ（P228)"
          ]
        ),
        "HTT" => DiceTable::D66Table.new(
          "変身トラブル表",
          D66SortType::NO_SORT,
          {
            11 => "あれを食べたい(P214)",
            12 => "あれを着たい(P214)",
            13 => "あれを見たい(P215)",
            14 => "あれを狩りたい(P215)",
            15 => "あれを踊りたい(P216)",
            16 => "あれに入りたい(P216)",
            21 => "強奪(P217)",
            22 => "暴行(P217)",
            23 => "虐殺(P218)",
            24 => "誘拐(P218)",
            25 => "無精(P219)",
            26 => "失踪(P219)",
            31 => "あれを食べたい(P214)",
            32 => "あれを着たい(P214)",
            33 => "あれを見たい(P215)",
            34 => "あれを狩りたい(P215)",
            35 => "あれを踊りたい(P216)",
            36 => "あれに入りたい(P216)",
            41 => "強奪(P217)",
            42 => "暴行(P217)",
            43 => "虐殺(P218)",
            44 => "誘拐(P218)",
            45 => "無精(P219)",
            46 => "失踪(P219)",
            51 => "あれを食べたい(P214)",
            52 => "あれを着たい(P214)",
            53 => "あれを見たい(P215)",
            54 => "あれを狩りたい(P215)",
            55 => "あれを踊りたい(P216)",
            56 => "あれに入りたい(P216)",
            61 => "強奪(P217)",
            62 => "暴行(P217)",
            63 => "虐殺(P218)",
            64 => "誘拐(P218)",
            65 => "無精(P219)",
            66 => "失踪(P219)"
          }
        ),
        "DET" => DiceTable::Table.new(
          "ドライブイベント表",
          "1D6",
          [
            "身の上話をする。目標が背景分野で選択している特技がドライブ判定の指定特技になる。",
            "スキル自慢をする。目標が仕事分野で選択している特技がドライブ判定の指定特技になる。",
            "むかし行った場所の話をする。目標が捜索分野で選択している特技がドライブ判定の指定特技になる。",
            "趣味の話をする。目標が趣味分野で選択している特技がドライブ判定の指定特技になる。",
            "テーマがない雑談をする。目標が雰囲気分野で選択している特技がドライブ判定の指定特技になる。",
            "物騒な話をする。目標が戦闘法分野で選択している特技がドライブ判定の指定特技になる。"
          ]
        ),
        "BET" => DiceTable::Table.new(
          "ブレイクイベント表",
          "1D6",
          [
            "イケメンの車は風光明美な場所に到着する。197ページの「観光地」を参照。",
            "イケメンの車は明るい光に照らされた小さな店に到着する。197ページの「コンビニ」を参照。",
            "イケメンの車は巨大かつ何でも売っている店に到着する。198ページの「ホームセンター」を参照。",
            "イケメンの車はドライバーたちの憩いの地に到着する。198ページの「サービスエリア」を参照。",
            "イケメンの車は大きなサービスエリアのような場所に到着する。199ページの「道の駅」を参照。",
            "イケメンの車は闇の底に隠された秘密の場所に到着する。199ページの「友愛会支部」を参照。"
          ]
        ),
        "CT" => DiceTable::Table.new(
          "キャンプ表",
          "1D6",
          [
            "無料仮眠所・いい感じの空き地：定員無制限／居住性-2／価格0／発見率2",
            "カプセルホテル：定員1／居住性-1／価格3／発見率2",
            "ラブホテル：定員2／居住性0／価格4／発見率1",
            "ビジネスホテル：定員2／居住性0／価格4／発見率1",
            "観光ホテル：定員4／居住性1／価格5／発見率1",
            "高級ホテル：定員4／居住性2／価格6／発見率0"
          ]
        ),
        "KZT" => DiceTable::Table.new(
          "関係属性表",
          "1D6",
          [
            "軽蔑",
            "反感",
            "混乱",
            "興味",
            "共感",
            "憧れ"
          ]
        ),
        "IA" => DiceTable::D66Table.new(
          "イケメンアクション決定表",
          D66SortType::ASC,
          {
            11 => "遠距離(IAA)",
            12 => "遠距離(IAA)",
            13 => "移動(IAB)",
            14 => "移動(IAB)",
            15 => "近距離(IAC)",
            16 => "近距離(IAC)",
            22 => "善人(IAD)",
            23 => "善人(IAD)",
            24 => "悪人(IAE)",
            25 => "悪人(IAE)",
            26 => "幼い(IAF)",
            33 => "幼い(IAF)",
            34 => "バカ(IAG)",
            35 => "バカ(IAG)",
            36 => "渋い(IAH)",
            44 => "渋い(IAH)",
            45 => "賢い(IAI)",
            46 => "賢い(IAI)",
            55 => "超自然(IAJ)",
            56 => "超自然(IAJ)",
            66 => "振り直しor自由選択"
          }
        ),
        "IAA" => DiceTable::Table.new(
          "イケメンアクション（遠距離）表(P172)",
          "1D6",
          [
            "目を合わせて微笑む（かっこよさ：4）",
            "場所を譲る（かっこよさ：4）",
            "髪をかきあげる（かっこよさ：5）",
            "複雑なポーズで座る（かっこよさ：5）",
            "物憂げな表情で振り返る（かっこよさ：6）",
            "ものを上に持つ（かっこよさ：6）"
          ]
        ),
        "IAB" => DiceTable::Table.new(
          "イケメンアクション（移動）表(P172)",
          "1D6",
          [
            "車道側を歩く（かっこよさ：4）",
            "乗り物から降りる（かっこよさ：4）",
            "真剣な表情で近づく（かっこよさ：4）",
            "馬に乗る（かっこよさ：6）",
            "ダメージを受けつつ移動（かっこよさ：6）",
            "瞬間移動（かっこよさ：6）"
          ]
        ),
        "IAC" => DiceTable::Table.new(
          "イケメンアクション（近距離）表(P173)",
          "1D6",
          [
            "黙って見つめる（かっこよさ：3）",
            "ちょっとしたプレゼント（かっこよさ：3）",
            "顎クイ（かっこよさ：5）",
            "壁ドン（かっこよさ：5）",
            "お姫様抱っこ（かっこよさ：7）",
            "床ドン（かっこよさ：7）"
          ]
        ),
        "IAD" => DiceTable::Table.new(
          "イケメンアクション（善人）表(P173)",
          "1D6",
          [
            "手を引いて逃げる（かっこよさ：4）",
            "毛布を掛ける（かっこよさ：4）",
            "守る（かっこよさ：5）",
            "笑って去る（かっこよさ：5）",
            "全てを捧げる（かっこよさ：6）",
            "悪堕ち（かっこよさ：6）"
          ]
        ),
        "IAE" => DiceTable::Table.new(
          "イケメンアクション（悪人）表(P174)",
          "1D6",
          [
            "攻撃する（かっこよさ：4）",
            "暗く笑う（かっこよさ：4）",
            "奪う（かっこよさ：4）",
            "目論見を口にする（かっこよさ：6）",
            "罠にかける（かっこよさ：6）",
            "改心する（かっこよさ：6）"
          ]
        ),
        "IAF" => DiceTable::Table.new(
          "イケメンアクション（幼い）表(P174)",
          "1D6",
          [
            "甘える（かっこよさ：3）",
            "疲れる（かっこよさ：3）",
            "無邪気な発言（かっこよさ：5）",
            "おねだり（かっこよさ：5）",
            "上目遣い（かっこよさ：7）",
            "抱きつく（かっこよさ：7）"
          ]
        ),
        "IAG" => DiceTable::Table.new(
          "イケメンアクション（バカ）表(P175)",
          "1D6",
          [
            "苦悩する（かっこよさ：4）",
            "屈託のない笑顔（かっこよさ：4）",
            "転ぶ（かっこよさ：4）",
            "叫ぶ（かっこよさ：6）",
            "間違える（かっこよさ：6）",
            "怖がる（かっこよさ：6）"
          ]
        ),
        "IAH" => DiceTable::Table.new(
          "イケメンアクション（渋い）表(P175)",
          "1D6",
          [
            "説教（かっこよさ：4）",
            "気づかせる（かっこよさ：4）",
            "見守る（かっこよさ：5）",
            "残心（かっこよさ：5）",
            "称える（かっこよさ：6）",
            "いい位置を取る（かっこよさ：6）"
          ]
        ),
        "IAI" => DiceTable::Table.new(
          "イケメンアクション（賢い）表(P176)",
          "1D6",
          [
            "難しい本を読む（かっこよさ：3）",
            "アドバイスをする（かっこよさ：3）",
            "眼鏡を持ち上げる（かっこよさ：5）",
            "状況を解説する（かっこよさ：5）",
            "計算できなくなる（かっこよさ：7）",
            "大丈夫だと言う（かっこよさ：7）"
          ]
        ),
        "IAJ" => DiceTable::Table.new(
          "イケメンアクション（超自然）表(P176)",
          "1D6",
          [
            "水に濡れる（かっこよさ：4）",
            "風を纏う（かっこよさ：4）",
            "地割れ（かっこよさ：5）",
            "火を放つ（かっこよさ：5）",
            "闇を生み出す（かっこよさ：6）",
            "光る（かっこよさ：6）"
          ]
        ),
        "CAC" => DiceTable::Table.new(
          "センターの行動決定表",
          "1d6",
          [
            "逃走",
            "不意打ち",
            "連続行動",
            "対話",
           "威嚇",
          "攻撃"
          ]
          ) ,
        "DDC" => DiceTable::Table.new(
          "対話ダメージ表",
          "1d6",
          [
            "焦り",
            "焦り",
            "不調",
            "不調",
            "ショック",
            "ショック",
          ]
        )
      }.freeze

      register_prefix(RTT.prefixes, TABLES.keys)
    end
  end
end
