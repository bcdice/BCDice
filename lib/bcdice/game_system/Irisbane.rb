# frozen_string_literal: true

module BCDice
  module GameSystem
    class Irisbane < Base
      # ゲームシステムの識別子
      ID = 'Irisbane'

      # ゲームシステム名
      NAME = '瞳逸らさぬイリスベイン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひとみそらさぬいりすへいん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■攻撃判定（ ATTACKx@y<=z ）
        x: 攻撃力
        y: 判定数
        z: 目標値
        （※ ATTACK は ATK または AT と簡略化可能）
        例） ATTACK2@3<=5
        例） ATK10@2<=4
        例） AT8@3<=2

        上記 x y z にはそれぞれ四則演算を指定可能。
        例） ATTACK2+7@3*2<=5-1

        □攻撃判定のダメージ増減（ ATTACKx@y<=z[+a]  ATTACKx@y<=z[-a]）
        末尾に [+a] または [-a] と指定すると、最終的なダメージを増減できる。
        a: 増減量
        例） ATTACK2@3<=5[+10]
        例） ATK10@2<=4[-8]
        例） AT8@3<=2[-8+5]

        ■シチュエーション（p115）
        SceneSituation, SSi

        ■シルエットライン（p37）
        SilhouetteLineEye, SilhouetteLEye, SLineEye, SLEye 瞳の印象
        SilhouetteLineHair, SilhouetteLHair, SLineHair, SLHair 髪の長さ
        SilhouetteLineHeight, SilhouetteLHeight, SLineHeight, SLHeight 身長
        SilhouetteLineCon, SilhouetteLCon, SLineCon, SLCon 体型
        SilhouetteLineDress, SilhouetteLDress, SLineDress, SLDress 服飾
        SilhouetteLineTint, SilhouetteLTint, SLineTint, SLTint 色彩

        □シルエットライン一括
        SilhouetteLine, SilhouetteL, SLine

        ■そのほかの表
        CAge 年齢（p27）
        CGender 性別（p27）
        CFailure 欠落（p30）
        CDesire 願望（p31）
        CQuestion 問い掛け（p34-35）
        CEndblessStyle, CEndStyle 復讐者のスタイル（p40）
        CEmblaceStyle, CEmbStyle 掌握者のスタイル（p41）
        ExpectExecution, EEx 望む執行の方向性（p48）
      HELP

      ATTACK_ROLL_REG = %r{^AT(TACK|K)?([+\-*/()\d]+)@([+\-*/()\d]+)<=([+\-*/()\d]+)(\[([+\-])([+\-*/()\d]+)\])?}i.freeze
      register_prefix('AT(TACK|K)?')

      SILHOUETTE_LINE_REG = /^(S(ilhouette)?L(ine)?(Eye|Hair|Height|Constitution|Dress|Tint)|S(ilhouette)?Line|SilhouetteL)/i.freeze
      register_prefix('S(ilhouette)?L(ine)?')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command

        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[2], m[3], m[4], m[6], m[7])
        elsif (m = SILHOUETTE_LINE_REG.match(command))
          if m[4].nil?
            roll_silhouette_line_all
          else
            roll_silhouette_line(m[4])
          end
        else
          roll_tables(command, TABLES)
        end
      end

      private

      def roll_attack(power_expression, dice_count_expression, border_expression, modification_operator, modification_expression)
        power = Arithmetic.eval(power_expression, RoundType::CEIL)
        dice_count = Arithmetic.eval(dice_count_expression, RoundType::CEIL)
        border = Arithmetic.eval(border_expression, RoundType::CEIL)
        modification_value = modification_expression.nil? ? nil : Arithmetic.eval(modification_expression, RoundType::CEIL)
        return if power.nil? || dice_count.nil? || border.nil?
        return if modification_operator && modification_value.nil?

        power = 0 if power < 0
        border = border.clamp(1, 6)

        command = make_command_text(power, dice_count, border, modification_operator, modification_value)

        if dice_count <= 0
          return "#{command} ＞ 判定数が 0 です"
        end

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        success_dice_count = dices.count { |dice| dice <= border }
        damage = success_dice_count * power

        message_elements = []
        message_elements << command
        message_elements << dices.join(',')
        message_elements << "成功ダイス数 #{success_dice_count}"
        message_elements << "× 攻撃力 #{power}" if success_dice_count > 0

        if success_dice_count > 0
          if modification_operator && modification_value
            message_elements << "ダメージ #{damage}#{modification_operator}#{modification_value}"
            damage = parse_operator(modification_operator).call(damage, modification_value)
            damage = 0 if damage < 0
            message_elements << damage.to_s
          else
            message_elements << "ダメージ #{damage}"
          end
        end

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = success_dice_count > 0
        end
      end

      def make_command_text(power, dice_count, border, modification_operator, modification_value)
        text = "(ATTACK#{power}@#{dice_count}<=#{border}"
        text += "[#{modification_operator}#{modification_value}]" if modification_operator
        text += ")"
        text
      end

      def parse_operator(operator)
        case operator
        when '+'
          lambda { |x, y| x + y }
        when '-'
          lambda { |x, y| x - y }
        end
      end

      def roll_silhouette_line_all
        "シルエットライン：\n" + (SILHOUETTE_LINES.values.map do |sl|
          r = sl.roll(@randomizer)
          "#{r[:simple]} #{r[:name]}"
        end).join("\n")
      end

      def roll_silhouette_line(kind)
        SILHOUETTE_LINES[kind].roll(@randomizer)[:full]
      end

      class SilhouetteLine
        def initialize(name, left, right)
          @name = name.freeze
          @left = left.freeze
          @right = right.freeze
        end

        def roll(randomizer)
          dice = randomizer.roll_once(6)
          line = self.class.make_line(dice)

          {
            name: @name,
            full: "シルエットライン：#{@name}(#{dice}) ＞ 【#{@left}】 #{line} 【#{@right}】",
            simple: "【#{@left[0...2]}】 #{line} 【#{@right[0...2]}】",
          }
        end

        def self.make_line(dice)
          ("－" * (dice - 1)) + "○" + ("－" * (6 - dice))
        end
      end

      SILHOUETTE_LINES = {
        "Eye" => SilhouetteLine.new("瞳の印象", "鋭利", "柔和"),
        "Hair" => SilhouetteLine.new("髪の長さ", "短い", "長い"),
        "Height" => SilhouetteLine.new("身長", "低い", "高い"),
        "Constitution" => SilhouetteLine.new("体型", "小柄", "大柄"),
        "Dress" => SilhouetteLine.new("服飾", "簡素 / シンプル", "派手 / ゴージャス"),
        "Tint" => SilhouetteLine.new("色彩", "単色 / シンプル", "多色 / カラフル"),
      }.transform_keys(&:upcase).freeze

      TABLES = {
        "CAGE" => DiceTable::Table.new(
          "年齢",
          "1D6",
          [
            "【幼年】誕生から一桁代。",
            "【少年】十代真っ盛り。",
            "【青年】二十代から三十代。",
            "【壮年】三十代から五十代。",
            "【老年】六十代からそれ以上。",
            "【晩年】百歳またはそれ以上。",
          ]
        ),
        "CGENDER" => DiceTable::ParityTable.new(
          "性別",
          "1D6",
          "【男性 male】その種の雄性配偶体。それ以上でも、以下でも有り得ない。",
          "【女性 female】その種の雌性配偶体。それ以上でも、以下でも有り得ない。"
        ),
        "CFAILURE" => DiceTable::D66LeftRangeTable.new(
          "欠落",
          BCDice::D66SortType::NO_SORT,
          [
            [1..3, [
              "【想い人】あるいは、想われ人と呼ぶべきか。どう呼ぶにしろ、もう居ない――もう、居ない。",
              "【心】板に棒に器に杯に……例えなら色々あるけれど、壊れたらお終いなことに違いは無い。",
              "【親友】“友情”とは何か？　その定義の一つは、定義を捨て去り、笑い合えることだろう。",
              "【家族】義理でも疑似でも、何だって良い。一つになれたら、それだけで家族だったのだ。",
              "【上下の者】上司と部下、先輩と後輩、先生と生徒……縦割り社会の関係性も、大切なものだ。",
              "【隣人】視界の中に収まっていただけ……そう想いたくても、どうやら難しいようである。",
            ]],
            [4..6, [
              "【己の一部】肉との結びつきか、それとも心か。何にせよ、“貴方”を形作る要素は余りに多い。",
              "【道具】分かっていない者は、こう言うだろう。「また手に入れれば良いじゃないか」――と。",
              "【ペット】説明するなら、そうなってしまう。それでも確かに“繋がり”はあったのだ。",
              "【場所】何をするにも、空間は必要である。大地なくして、立ち上がることは不可能だ。",
              "【金銭】何かの価値の代わりの形。只の数字の羅列であると、０で無い者達なら言うだろうか。",
              "【資格】名誉、面子、地位、階級――無くても良いと言えるのは、喪ったことが無い者だけだ。",
            ]],
          ]
        ),
        "CDESIRE" => DiceTable::D66LeftRangeTable.new(
          "願望",
          BCDice::D66SortType::NO_SORT,
          [
            [1..3, [
              "【栄光】己が目指した、まともであれば届かぬ高みへ、もしもこの手が届くとしたら……",
              "【愛情】「愛こそはすべて」と皆が知っている。だからこそ、奪い取ってでも手に入れなければ。",
              "【闘争】誰かと戦い、何かを競い、持てる全てで打ち勝つことは、何にも代え難い喜びである。",
              "【逃避】大袈裟なことなんて誰も望んでいない。「何処かへ行きたい」、只それだけなのに……",
              "【報復】「目には目を」だと言うでは無いか。己の境遇を鑑みれば、この行いは正義であろう。",
              "【長寿】あるいは「生存」と言い換えても良い。“死にたくない”のは、誰だって一緒なのだ。",
            ]],
            [4..6, [
              "【黄金】価値あるものを、この手にしたい。何より輝く、不変不動の確かな価値を……",
              "【復活】喪ったものは、決して元には戻らない。だから、限り無く近しい奇跡を求めるのだ。",
              "【喝采】手が二つしか無い以上、一人の拍手は限界がある。やはり皆に認められねば。",
              "【笑顔】突き詰めるのなら、そう言うことだ。全員同じ想いなら、望んで悪い筈が無い。",
              "【悪事】それが“悪”だとは分かっている。だからこそ、求める必要が出てくるのだろう。",
              "【永遠】この世界に、そんなものは存在しない。だが、想像できる以上、片鱗なら有り得るのだ。",
            ]],
          ]
        ),
        "CQUESTION" => DiceTable::D66Table.new(
          "問い掛け",
          BCDice::D66SortType::NO_SORT,
          {
            11 => "【誰】を愛していましたか？",
            12 => "どんな【容姿】をしていましたか？",
            13 => "どんな【表情】をしていましたか？",
            14 => "どんな【格好】をしていましたか？",
            15 => "どんな【行動】をしていましたか？",
            16 => "印象的だったのは【何処】ですか？",

            21 => "好きなものは【何】でしたか？",
            22 => "欲しかったものは【何】ですか？",
            23 => "【何】を待っていましたか？",
            24 => "【何処】に暮らしていましたか？",
            25 => "【何】に乗っていましたか？",
            26 => "【何】が視界にありましたか？",

            31 => "最後に笑ったのは【いつ】ですか？",
            32 => "どんな【空】が広がっていましたか？",
            33 => "どんな【人々】が見えましたか？",
            34 => "どんな【生活】をしていましたか？",
            35 => "食べていたのは【何】ですか？",
            36 => "飼っていたのは【何】ですか？",

            41 => "【誰】を憎んでいましたか？",
            42 => "どんな【仕草】をしていましたか？",
            43 => "どんな【言葉】を交わしましたか？",
            44 => "【時刻】はいつのことでしたか？",
            45 => "【季節】はいつのことでしたか？",
            46 => "どれ位【昔】のことですか？",

            51 => "嫌いなものは【何】でしたか？",
            52 => "捨てたかったものは【何】ですか？",
            53 => "【何】を抱えていましたか？",
            54 => "【何処】へ向かっていましたか？",
            55 => "【何】に運ばれていましたか？",
            56 => "【何】が聞こえていましたか？",

            61 => "最後に泣いたのは【いつ】ですか？",
            62 => "どんな【海】が広がっていましたか？",
            63 => "どんな【町並み】が見えましたか？",
            64 => "どんな【仕事】をしていましたか？",
            65 => "飲んでいたのは【何】ですか？",
            66 => "離れて行ったのは【誰】ですか？",
          }
        ),
        "CEndblessStyle" => DiceTable::Table.new(
          "復讐者のスタイル",
          "1D6",
          [
            "【ルビー】（P58）――赤の焔を宿す瞳。復讐とは「激情の発露」である。",
            "【サファイア】（P59）――青の焔を宿す瞳。復讐とは「冴えたやり方」である。",
            "【トパーズ】（P60）――黄の焔を宿す瞳。復讐とは「ある種の冗句」である。",
            "【エメラルド】（P61）――緑の焔を宿す瞳。復讐とは「良く生きること」である。",
            "【オブシダン】（P62）――黒の焔を宿す瞳。復讐とは「沈黙の祈り」である。",
            "【パール】（P63）――白の焔を宿す瞳。復讐とは「正義の遵守」である。",
          ]
        ),
        "CEmblaceStyle" => DiceTable::Table.new(
          "掌握者のスタイル",
          "1D6",
          [
            "【キング】（P78／作成済み：P178）――王者の気質。他者とは「都合の良い手駒」である。",
            "【クイーン】（P79／作成済み：P180）――女王の気質。他者とは「返答する鏡」である。",
            "【ルーク】（P80／作成済み：P182）――戦車の気質。他者とは「歩く薪の束」である。",
            "【ビショップ】（P81／作成済み：P184）――司祭の気質。他者とは「計略の道具類」である。",
            "【ナイト】（P82／作成済み：P186）――騎士の気質。他者とは「伴侶と、それ以外」である。",
            "【ポーン】（P83／作成済み：P188）――軍勢の気質。他者とは「集団の一要素」である。",
          ]
        ),
        "ExpectExecution" => DiceTable::Table.new(
          "望む執行の方向性",
          "1D6",
          [
            "物理的な制裁を望む",
            "精神的な制裁を望む",
            "社会的な制裁を望む",
            "己の手による制裁を望む",
            "復讐者以外の制裁を望む",
            "贖罪と改心こそを望む",
          ]
        ),
        "SceneSituation" => DiceTable::D66LeftRangeTable.new(
          "シチュエーション",
          BCDice::D66SortType::NO_SORT,
          [
            [1..3, [
              "【日常】何一つ変わることの無い日々の一幕。移ろい易い世界では、それはとても大切である。",
              "【準備】何かを為すための用意をする一幕。情報収集、買物遠征、やるべきことは一杯だ。",
              "【趣味】自分の時間を、有効活用している一幕。必要に追われていない分、心は軽く晴れやかだ。",
              "【喫茶】一息入れ、嗜好品を嗜む時の一幕。穏やかな空気は、だが、往々にして変わりやすい。",
              "【鍛錬】体を鍛え、心を養う修練の一幕。己さえ良ければ、その方法も何だって良い。",
              "【職務】役割の元、仕事に精を出す時の一幕。目的が何であれ、為すべきことに変わりはない。",
            ]],
            [4..6, [
              "【移動】何処かから何処かへと向かう一幕。進んでいるなら、手段も目的地も関係あるまい。",
              "【墓前】故人が眠る場所へと赴く一幕。共に眠ることだけは無いように。",
              "【操作】何かを操り、望みを果たしている一幕。運転にせよ何にせよ、脇見には注意が必要だ。",
              "【食事】何かを糧とし、己の力を蓄える一幕。行動すれば消耗する。腹が減っては何とやらだ。",
              "【休息】日々の合間の、憩いの一幕。“何もしない”というのも、立派な行いである。",
              "【夢幻】現実に存在しない何かへと耽る一幕。時間帯に関わらず、何時かは必ず覚めるだろう。",
            ]],
          ]
        ),
      }.transform_keys(&:upcase).freeze

      ALIAS = {
        "CEndStyle" => "CEndblessStyle",
        "CEmbStyle" => "CEmblaceStyle",
        "EEx" => "ExpectExecution",
        "SSi" => "SceneSituation",
        "SilhouetteLineCon" => "SilhouetteLineConstitution",
        "SLineCon" => "SLineConstitution",
        "SilhouetteLCon" => "SilhouetteLConstitution",
        "SLCon" => "SLConstitution",
      }.transform_keys(&:upcase).transform_values(&:upcase).freeze

      register_prefix(TABLES.keys, ALIAS.keys)
    end
  end
end
