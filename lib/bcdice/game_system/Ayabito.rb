# frozen_string_literal: true

require 'bcdice/command/parser'

module BCDice
  module GameSystem
    class Ayabito < Base
      # ゲームシステムの識別子
      ID = "Ayabito"

      # ゲームシステム名
      NAME = "あやびと"

      # ゲームシステム名の読みがな
      SORT_KEY = "あやひと"

      HELP_MESSAGE = <<~TEXT
        ・判定コマンド(xAB±y@c>=z)
          x：サイコロの数(10以上の場合9個振り、それ以降を成功数2として加算する)
          ±y：成功数への補正(省略可)
          c：クリティカル値(@ごと省略可。省略時は6)
          z：目標値(妨害値など。>=ごと省略可)
          (例) 4AB
               11AB>=5
               5AB+1
               6AB@5>=3

        ・各種表
          感情表 ET
          帝都東京シーン表 TST / 場面演出シーン表 BST
          交流表 CET
          ファンブル表 FT
          封印期間表 LT
      TEXT

      def initialize(command)
        super(command)
        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        return check_action(command) || roll_tables(command, TABLES)
      end

      def check_action(command)
        parser = Command::Parser.new("AB", round_type: RoundType::CEIL).has_prefix_number.enable_critical.restrict_cmp_op_to(nil, :>=)
        parsed = parser.parse(command)
        return nil if parsed.nil?

        if parsed.prefix_number < 10
          dice_cnt = parsed.prefix_number
          over_modify = 0
        else
          dice_cnt = 9
          over_modify = parsed.prefix_number - 9
        end
        modify = parsed.modify_number
        critical_target = parsed.critical || 6
        target = parsed.target_number

        dice_arr = @randomizer.roll_barabara(dice_cnt, 6).sort
        dice_str = dice_arr.join(",")
        has_critical = dice_arr.any? { |x| x >= critical_target }
        success_cnt = dice_arr.count { |x| x >= 4 } + dice_arr.count(6) + over_modify * 2
        has_fumble = success_cnt == 0 && dice_arr.include?(1)
        if has_fumble
          success_cnt = 0
        else
          success_cnt += modify
        end
        result = target.nil? ? success_cnt >= 1 : success_cnt > target

        Result.new.tap do |r|
          r.text = "(#{dice_cnt}B6>=4)#{over_modify > 0 ? "+#{over_modify * 2}" : ''} ＞ [#{dice_str}]#{over_modify > 0 ? "+#{over_modify * 2}" : ''} ＞ 成功数#{success_cnt} ＞ #{result ? '成功' : '失敗'}#{has_critical ? '(クリティカル)' : ''}#{has_fumble ? '(ファンブル)' : ''}"
          r.critical = has_critical
          r.fumble = has_fumble
          r.success = result
          r.failure = !result
        end
      end

      TABLES = {
        'ET' => DiceTable::D66Table.new(
          '感情表',
          D66SortType::NO_SORT,
          {
            11 => '信頼/不信感',
            12 => '好奇心/無関心',
            13 => '優越感/劣等感',
            14 => '好意/敵意',
            15 => '安心感/不安感',
            16 => '愛情/偏愛',
            21 => '同情/憐憫',
            22 => '親近感/疎外感',
            23 => '連帯感/隔意',
            24 => '尽力/面倒',
            25 => '貸し/借り',
            26 => '庇護欲/食傷',
            31 => '期待/反発',
            32 => '熱狂/心酔',
            33 => '幸福感/不快感',
            34 => '尊敬/軽蔑',
            35 => '憧憬/嫉妬',
            36 => '忠誠/服従',
            41 => '友情/侮蔑',
            42 => '競争心/警戒',
            43 => '感謝/後悔',
            44 => '感服/恐怖',
            45 => '興味/屈辱',
            46 => '誠意/憎悪',
            51 => '羨望/嫌悪',
            52 => '共感/懸念',
            53 => '傾倒/厭気',
            54 => '赦し/怒り',
            55 => '有為/苦手',
            56 => '恩義/不満',
            61 => '予感/困惑',
            62 => '懐旧/忘却',
            63 => '慕情/執着',
            64 => '夢中/退屈',
            65 => '贖罪/罪悪感',
            66 => '慈愛/殺意',
          }
        ),
        'TST' => DiceTable::D66LeftRangeTable.new(
          '帝都東京シーン表',
          D66SortType::NO_SORT,
          [
            [1..1, Array.new(6, "子～巳までの任意の十二支を選択する。")],
            [2..3, [
              "［子］帝国大学の赤門、学生たちが今日も勉学に励んでいる。",
              "［丑］吉原の歓楽街。昼間は静かだが、夜は活気を見せてくれる。",
              "［寅］上野公園。桜に新緑、紅葉など、季節の顔を見せてくれる。",
              "［卯］浅草六区は今日も賑やか。浅草寺や仲見世には、多くの人々が行き交う。",
              "［辰］凌雲閣。浅草十二階として親しまれる塔に昇り、周囲を一望する。",
              "［巳］丸の内の東京駅。構内の喧騒とは裏腹に、霞ヶ関は静かに時が流れる。",
            ]],
            [4..5, [
              "［午］銀座をぶらぶらと歩く。百貨店が立ち並ぶこの街では、何でも買うことができるらしい。",
              "［未］日比谷の帝国劇場。演目は、話題のトップスタアによる華やかなる歌劇のようだ。",
              "［申］皇居のほとり。水面にうかぶ蓮の葉が、しずかに揺れている。",
              "［酉］明治神宮の境内。神聖なる雰囲気を味わうことができる。",
              "［戌］新たな東京の名所である新宿。今では東西を二分する街である。",
              "［亥］日本帝国軍駐屯地。妖怪人間共同実働部隊の本部も敷地内にある。",
            ]],
            [6..6, Array.new(6, "午～亥まで任意の十二支を選択する。")],
          ]
        ),
        'BST' => DiceTable::D66LeftRangeTable.new(
          '場面演出シーン表',
          D66SortType::NO_SORT,
          [
            [1..1, Array.new(6, "子～巳までの任意の十二支を選択する。")],
            [2..3, [
              "［子］人々が寝静まる帝都の夜。月に雲がかかるとともに、魔の香りが漂っている。",
              "［丑］草木も眠る静けさの中、犬の遠吠えだけが聞こえてくる。",
              "［寅］一陣の風が吹き抜ける。風に乗った匂いが、妙に鼻をくすぐってきた。",
              "［卯］霧や朝もやに包まれる。向こうに見える姿は誰だろうか……",
              "［辰］帝都に朝日が射す。人々は起き出し、日々の営みを始める。",
              "［巳］清廉な雰囲気の風景。鳥や虫の声、風にそよぐ木々の音が聞こえてくる。",
            ]],
            [4..5, [
              "［午］時計の針がある時間を指し示す。刻を告げるチャイムや鐘が響き渡る。",
              "［未］昼間の大通り。自動車や路面電車が走り、行き交う人々の雑踏が至るところで見られる。",
              "［申］夕刻、どこからともなく、定かではない声や物音が漏れてくる。",
              "［酉］瓦斯灯（がすとう）が通りを鮮やかに照らす。夜が街のもうひとつの顔を出し始める。",
              "［戌］星空の下、月明かりが微かに夜道を照らしている。",
              "［亥］光ひとつない暗闇の中。何者かの気配が蠢いている……",
            ]],
            [6..6, Array.new(6, "午～亥まで任意の十二支を選択する。")],
          ]
        ),
        'CET' => DiceTable::D66LeftRangeTable.new(
          '交流表',
          D66SortType::NO_SORT,
          [
            [1..1, Array.new(6, "感情～性格までの任意のテーマを選択する。")],
            [2..3, [
              "［感情］相手に抱いている感情、伝えるべきか伝えないべきか。",
              "［人間］相手に人間という存在をどう思うか、聞いてみるとしよう。",
              "［友達］相手に友人や仲間について語ろう。話すことで分かる想いもあるだろう。",
              "［告白］相手に話していいか分からないが、自分の秘めたる想いを語ろう。",
              "［思い出］相手に、過去の思い出を話してみよう。相手から昔話をきけるかもしれない。",
              "［性格］相手に自身の性格を語ろう。表向きのみ話すか、奥底まで話してしまうかは、事と次第による。",
            ]],
            [4..5, [
              "［関係性］相手とは、いつからこうした関係だったのか。相手と関係性について話そう。",
              "［妖怪］相手に妖怪という存在をどう思うか、聞いてみるとしよう。",
              "［あやびと］相手に、自分があやびとである意味や意義を語ってみよう。",
              "［想い］相手が今、何かしら想う人や物事について聞いてみよう。",
              "［夢］相手に自分の夢を語ろう。未来の夢、かつて捨てた夢かもしれない。",
              "［半生］相手に自身の半生を語ろう。半生こそが、今の自分となるきっかけなのだから……",
            ]],
            [6..6, Array.new(6, "関係性～半生までの任意のテーマを選択する。")],
          ]
        ),
        'FT' => DiceTable::Table.new(
          'ファンブル表',
          '1D6',
          [
            'PCの【耐久値】を-5する(最低1)。',
            'PCの【活力値】を-5する(最低1)',
            'PCは戦闘ないしフェイズが終了するまで《アビリティ》を使用できない。',
            'PCは戦闘ないしフェイズが終了するまで[絆]を使用できない。',
            'セッション終了時まで、登場するエネミーすべての【耐久値】を+3する',
            'セッション終了時まで、登場するエネミーすべてのダメージを+2する。',
          ]
        ),
        'LT' => DiceTable::Table.new(
          '封印期間表',
          '1D6',
          [
            # '1日',
            '1週間',
            '1ヶ月',
            '1年',
            '10年',
            '50年',
            '100年',
            # '500年',
          ]
        ),
      }.freeze

      register_prefix('\d*AB', TABLES.keys)
    end
  end
end
