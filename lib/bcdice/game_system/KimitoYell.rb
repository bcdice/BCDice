# frozen_string_literal: true

module BCDice
  module GameSystem
    class KimitoYell < Base
      # ゲームシステムの識別子
      ID = "KimitoYell"

      # ゲームシステム名
      NAME = "キミトエール！"

      # ゲームシステム名の読みがな
      SORT_KEY = "きみとええる"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 （nKY6 / nKY10）
        指定された能力値分（n個）のダイスを使って判定を行います。
        ・nKY6…「有利」を得ていない場合、6面ダイスをn個振って判定します。
        ・nKY10…「有利」を得ている場合、10面ダイスをn個振って判定します。
        6もしくは10の出目があればスペシャル。1の出目があればファンブル。
        スペシャルとファンブルは同時に発生した場合、両方の処理を行う。

        ■ 表
        ─ ファンブル表（FT）
          ファンブル時の処理を決定します。

        ─ 新しい出会いを求める
          ─ 一括 新しい出会い表（NMTA） # New Meet Table
            その後の表を含めてすべて同時に決定します。
            ひとつひとつ振る場合には下記のコマンドを使用してください。
          ─ 新しい出会い表（NMT） # New Meet Table
          ─ 偶然出会った表（MCT） # Meet by Chance Table
          ─ 交流のなかった身近な人表（CIT） # someone Close to you but no Interaction Table
          ─ 助けてくれた人表（HYT） # someone Help You table
          ─ どんな人だったか表（TLT） # what's They Like Table
          ─ 変わった人だった表（EPT） # Eccentric Person Table

        ─ ランダム命名表
          ─ フルネーム一括生成（FNG） # Full Name Generation
          ─ 名字表（LNT） # LastName Table
          ─ 名前表（FNT） # FirstName Table
          ─ 日本名字表1（JLTO） # Japanese Lastname Table One
          ─ 日本名字表2（JLTT） # Japanese Lastname Table Two
          ─ カタカナ名字表（FLT） # Foreien Lastname Table
          ─ 日本名前表1（JFTO） # Japanese Firstname Table One
          ─ 日本名前表2（JFTT） # Japanese Firstname Table Two
          ─ カタカナ名前表（FFT） # Foreien Firstname Table
      TEXT

      register_prefix('\d+KY[6|10]', 'FT', 'NMTA', 'NMT', 'MCT', 'CIT', 'HYT', 'TLT', 'EPT', 'FNG', 'LNT', 'FNT', 'JLTO', 'JLTT', 'FLT', 'JFTO', 'JFTT', 'FFT')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        if /^(\d+)KY(6|10)$/.match(command).nil? != true
          roll_ky_judge(command)
        elsif /FT/.match(command).nil? != true && /JFTO|JFTT|FFT/.match(command).nil? == true
          roll_fumble(command)
        elsif /NMTA|NMT|MCT|CIT|HYT|TLT|EPT/.match(command).nil? != true
          generate_new_encounter(command)
        elsif /FNG|LNT|FNT|JLTO|JLTT|FLT|JFTO|JFTT|FFT/.match(command).nil? != true
          generate_new_name(command)
        end
      end

      private

      def roll_ky_judge(command)
        # m[1]にダイス数、m[2]に6/10面がはいる
        m = /^(\d+)KY(6|10)$/.match(command)

        unless m
          return nil
        end

        # d6、d10の設定
        n_of_diceside = m[2].to_i == 10 ? 10 : 6

        # 振るさいころの数
        n_of_rolldice = m[1].to_i

        # 成功となる出目
        success_dices = [4, 5, 6, 7, 8, 9, 10]

        # スペシャルとなる出目
        special_dices = [6, 10]

        # ファンブルとなる出目
        fumble_dices = [1]

        # 各種テキストとResultに持っていくための初期値
        txt_special = "スペシャル（がんばりが1点上昇！）"
        txt_fumble = "ファンブル（ファンブル表：FTを振る）"
        txt_success = "成功"
        txt_failure = "失敗"

        result_txts = []
        is_critical = false
        is_fumble = false
        is_success = false
        is_failure = false

        # ダイスを振る
        dice_list = @randomizer.roll_barabara(n_of_rolldice, n_of_diceside)

        # 結果チェック
        is_critical = dice_list.intersection(special_dices).empty? ? false : true
        is_fumble = dice_list.intersection(fumble_dices).empty? ?  false : true
        is_success = dice_list.intersection(success_dices).empty? ?  false : true
        is_failure = dice_list.intersection(success_dices).empty? ?  true : false

        # 結果用テキストの生成
        if is_success == true
          result_txts.push(txt_success)
        end
        if is_failure == true
          result_txts.push(txt_failure)
        end
        if is_critical == true
          result_txts.push(txt_special)
        end
        if is_fumble == true
          result_txts.push(txt_fumble)
        end

        return Result.new.tap do |r|
          # 最終的に表示するテキスト
          r.text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{result_txts.join('・')}"

          # 各種パラメータ
          r.success = is_success
          r.failure = is_failure
          r.critical = is_critical
          r.fumble = is_fumble
        end
      end

      def roll_fumble(command)
        fumbledice = @randomizer.roll_once(6)
        fumbletext = FTABLE[fumbledice - 1]

        return "ファンブル表(#{command}:#{fumbledice}) ＞ #{fumbletext}"
      end

      def generate_new_encounter(command)
        # 新しい出会い表（一括生成用もいったんまとめて振る）
        if /NMTA|NMT/.match(command).nil? != true
          table0 = NMTABLE
          table0dice = @randomizer.roll_once(6)
          table0txt = table0[table0dice]
          if table0dice == 1
            table1 = MCTABLE
            table2 = TLTABLE
          elsif table0dice == 2
            table1 = MCTABLE
            table2 = EPTABLE
          elsif table0dice == 3
            table1 = CITABLE
            table2 = TLTABLE
          elsif table0dice == 4
            table1 = CITABLE
            table2 = EPTABLE
          elsif table0dice == 5
            table1 = HYTABLE
            table2 = TLTABLE
          else
            table1 = HYTABLE
            table2 = EPTABLE
          end
        else
          # その他の表だけ用ダイス
          table0dice = @randomizer.roll_once(10)
        end

        # 新しい出会いを求める際のランダム表個別
        if /MCT/.match(command).nil? != true
          table0 = MCTABLE
          table0txt = table0[table0dice]
        elsif /CIT/.match(command).nil? != true
          table0 = CITABLE
          table0txt = table0[table0dice]
        elsif /HYT/.match(command).nil? != true
          table0 = HYTABLE
          table0txt = table0[table0dice]
        elsif /TLT/.match(command).nil? != true
          table0 = TLTABLE
          table0txt = table0[table0dice]
        elsif /EPT/.match(command).nil? != true
          table0 = EPTABLE
          table0txt = table0[table0dice]
        end

        # 新しい出会い表の一括振り分残りの表決定と結果用テキスト生成
        if /NMTA/.match(command).nil? != true
          table1dice = @randomizer.roll_once(10)
          table1txt = table1[table1dice]
          table2dice = @randomizer.roll_once(10)
          table2txt = table2[table2dice]

          resulttxt = "#{table0[0]}(#{table0dice}) ＞ #{table0txt}\n#{table1[0]}(#{table1dice}) ＞ #{table1txt}\n#{table2[0]}(#{table2dice}) ＞ #{table2txt}"
        else
          # 一括じゃない場合は表1枚分なので結果用テキスト生成処理まとめて
          resulttxt = "#{table0[0]}(#{table0dice}) ＞ #{table0txt}"
        end

        return resulttxt
      end

      def generate_new_name(command)
        # 登録したD66のテーブル振るならroll_tables(command, TABLES)
        # フルネーム一括生成
        if /FNG/.match(command).nil? != true
          nametabledice1 = @randomizer.roll_once(6)
          result1 = "#{LNTABLE[0]}(#{nametabledice1}) ＞ #{LNTABLE[nametabledice1]}"
          nametabledice2 = @randomizer.roll_once(6)
          result2 = "#{FNTABLE[0]}(#{nametabledice2}) ＞ #{FNTABLE[nametabledice2]}"
          if [1, 2].include?(nametabledice1)
            result3 = roll_tables("JLTO", TABLES)
          elsif [3, 4].include?(nametabledice1)
            result3 = roll_tables("JLTT", TABLES)
          else
            result3 = roll_tables("FLT", TABLES)
          end
          if [1, 2].include?(nametabledice1)
            result4 = roll_tables("JFTO", TABLES)
          elsif [3, 4].include?(nametabledice1)
            result4 = roll_tables("JFTT", TABLES)
          else
            result4 = roll_tables("FFT", TABLES)
          end
        end

        # 名字表or名前表（その後の表も振る）
        if /LNT/.match(command).nil? != true
          nametabledice1 = @randomizer.roll_once(6)
          result1 = "#{LNTABLE[0]}(#{nametabledice1}) ＞ #{LNTABLE[nametabledice1]}"
          if [1, 2].include?(nametabledice1)
            result2 = roll_tables("JLTO", TABLES)
          elsif [3, 4].include?(nametabledice1)
            result2 = roll_tables("JLTT", TABLES)
          else
            result2 = roll_tables("FLT", TABLES)
          end
        elsif /FNT/.match(command).nil? != true
          nametabledice1 = @randomizer.roll_once(6)
          result1 = "#{FNTABLE[0]}(#{nametabledice1}) ＞ #{FNTABLE[nametabledice1]}"
          if [1, 2].include?(nametabledice1)
            result2 = roll_tables("JFTO", TABLES)
          elsif [3, 4].include?(nametabledice1)
            result2 = roll_tables("JFTT", TABLES)
          else
            result2 = roll_tables("FFT", TABLES)
          end
        end

        # 各表単発
        if /JLTO|JLTT|FLT|JFTO|JFTT|FFT/.match(command).nil? != true
          result1 = roll_tables(command, TABLES)
        end

        # 結果表示用テキスト生成
        if result4.nil? != true
          resulttxt = result1 + "\n" + result3 + "\n" + result2 + "\n" + result4
        elsif result2.nil? != true
          resulttxt = result1 + "\n" + result2
        else
          resulttxt = result1
        end

        return resulttxt
      end

      # Fumble Table
      FTABLE = [
        "とんでもない大失敗！　魔法でないと取り返しがつかない！　出目にかかわらず、「魔法の提案」をしない限り判定は失敗になる。",
        "もうちょっと何かが足りない。自分の【がんばり】を1点消費することで、出目にかかわらず判定を成功にできる。【がんばり】を消費しなければ出目にかかわらず判定が失敗になる。",
        "トラブルが発生したけど「大切な想い」を思い出して何とか乗り切った。大切だと思う世界から学んだこと、大切だと思いたい世界に対する気持ちを思い出して、なんとかしよう。自分の持っているカードの「大切な想い」を1つ選んで〇で囲む。〇で囲めない場合、判定は出目にかかわらず失敗になる。",
        "トラブルが発生した。こんな自分を、あの人が見たらどう思うかな。自分が持っているカードに、「大切な想い」を考えて1つ書き込む。",
        "トラブルが発生したけど、偶然にも自分の「守りたい人」が助けてくれた。あるいは、「守りたい人」の教えてくれたことが役立った。ありがとう……。",
        "ちょっとヒヤリとする瞬間があったけど、何も起こらなかった。よかった。",
      ].freeze

      # New Meet Table
      NMTABLE = [
        "新しい出会い表",
        "「偶然出会った表（MCT）」と「どんな人だったか表（TLT）」を使用してNPCを作成する。",
        "「偶然出会った表（MCT）」と「変わった人だった表（EPT）」を使用してNPCを作成する。",
        "「交流のなかった身近な人表（CIT）」と「どんな人だったか表（TLT）」を使用してNPCを作成する。",
        "「交流のなかった身近な人表（CIT）」と「変わった人だった表（EPT）」を使用してNPCを作成する。",
        "「助けてくれた人表（HYT）」と「どんな人だったか表（TLT）」を使用してNPCを作成する。",
        "「助けてくれた人表（HYT）」と「変わった人だった表（EPT）」を使用してNPCを作成する。",
      ].freeze

      # Meet by Chance Table
      MCTABLE = [
        "偶然出会った表",
        "何らかの事件や事故が起こり、それに巻き込まれた人を助けるために動いた。そのお礼をしたいと声をかけられた。",
        "急に振り出した雨。屋根のある所に雨宿りをした際に、同じく雨宿りをしていた人物と話をした。",
        "図書館の資料を集めていたところ、偶然にも同じ資料を借りようとしていた人物とバッティングしてしまった。どちらが先にするか話し合った。",
        "魔法やオカルトの事を調べるのが趣味らしく、ちょっとした魔法の事件が起こった場所をうろついていた。巻き込まれないように声をかけたら、自分が怪しまれた。",
        "街を歩いている時に、うずくまっている人を見つけた。何があったのかと声をかけてみると、何か困っていることがあるらしい。それを助けた。",
        "偶然にも稼働していない魔具を見つけたので、回収するために持ち主と話をすることになった。",
        "以前、魔具関係の事件で駆け回った時の自分を見かけた人がいたらしい。その時の顔が印象に残ったらしく、何をしていたのか聞かれた。",
        "「MAGIA」にたちよったところ、知らない店員がいた。新しく雇ったアルバイトらしく、何をしていたのか聞かれた。",
        "たまたま立ち寄った飲食店の店長から、試供品が提供されて、味の感想を求められた。どうやら新メニューを作りたいらしく、いろいろな人の意見を聞いているらしい。",
        "「守りたい人」に会いに行ったら、「守りたい人」の親友と名乗る人と出会った。自分の知らない「守りたい人」について話してくれた。",
      ].freeze

      # someone Close to you but no Interaction Table
      CITABLE = [
        "交流のなかった身近な人表",
        "その人は自分の親戚で、家の用事で出かけたときに親などから紹介をされた。話をしてみたら、自分の興味と同じものを研究していた。",
        "親などに頼まれて、ご近所に挨拶へ伺った。その人は近所で見かけることがあったが、不思議と今まで交流がなく、よくわからない人だった。",
        "「守りたい人」がたまに話題に出す友人と、「守りたい人」に紹介される形で会う機会ができた。この人はどんな人なのか、見てみよう。",
        "きょうだいの知り合いで、挨拶ぐらいはしていたけど、二人きりになったのは初めてだった。きょうだいも用事でいないし、どう話したものか。",
        "学業やスポーツの関係で、遠くの国で暮らしていたきょうだい（あるいはいとこ）が帰ってきた。優秀な成績を修めて、世間からも注目されている人物にどう接しようか。",
        "昔はずっと一緒に遊んでいた幼馴染だったけど、事情があって最近まで遠くに出かけていた。数日前に帰ってきたらしく、挨拶しにやってきた。",
        "「MAGIA」に立ち寄ったところ、店長から話しかけられた。どうも今は暇らしく、話し相手になってほしいとのことだ。",
        "SNSなどで知り合い、趣味が合ってネット上の友人となれた人物と、外でも会うことになった。",
        "クラスや職場で人気の人が、たまたま一人でいるところを見かけた。向こうもこちらに気づいたらしく、話しかけてきた。さて、どうするかな。",
        "趣味の集いに行ったら、クラスメイトや元クラスメイトがいた。趣味の場で会ってみると教室との印象が違った。",
      ].freeze

      # someone Help You table
      HYTABLE = [
        "助けてくれた人表",
        "忘れ物をしたが、それを届けてくれた。その際に少し話をしたが、優しく丁寧で好感の持てる人だった。",
        "自分が転びそうになった、あるいは轢かれそうになった時に、助けてくれた。",
        "用事があって普段行かない場所に行ったとき、迷子になった自分を助けてくれた。",
        "自分がケガをした子供の対処に困っている時、一緒になって子供の面倒を診てくれた。",
        "自分は幼い頃、外でケガをしてしまったことがある。その時に応急処置をして、病院まで運んでくれた人がいる。その人と偶然再会した。",
        "自分は幼い頃、何かしらの事情で孤独になり、辛かった時期がある。そんな時に、声をかけて一緒に遊んでくれた人がいた。その人と再会した。",
        "自分が不良や話しかけられたくないタイプの人に絡まれた時、声をかけて助けてくれた人がいる。",
        "図書館などで資料集めをしている際に、声をかけて助けてくれた人がいた。",
        "魔具や財布など重要なものを失くしてしまい、探している必死そうな自分を見て助けてくれた。",
        "昔、魔法関係で困った時に、助けてくれた魔法使いがいた。その人が何かの用事で「MAGIA」に立ち寄っており、その時に声をかけた。",
      ].freeze

      # what's They Like Table
      TLTABLE = [
        "どんな人だったか表",
        "「守りたい人」によく似ている。",
        "不良っぽいファッションだけど、単にそういう格好が好きなだけで丁寧な人だった。",
        "パリッとした服装、きちんとした身なりで優等生あるいは真面目な人という感じ。",
        "活発そうな人物で、スポーツに打ち込んでいそうな体格と口調。いかにも体育会系。",
        "サバサバとした性格で、いろいろな人の悩み事を聞いては解決しようとしていた兄貴分（姉貴分）。",
        "細かいことが気になるタイプのようで、何かとチェックしてそうな視線を感じた。",
        "優しい性格で、自分の言葉を待って聞いてくれる人だった。",
        "おしゃべりな人物で、いろいろなことをしゃべってくれる。そのうえで、こちらの話も聞いてくれた。",
        "不思議と小動物のような印象を受けた。懐いてきて、自分の反応を楽しみにしているような、そんな人だ。",
        "「守りたい人」の知り合いで、共通の知り合いの話題ができた。",
      ].freeze

      # Eccentric Person Table
      EPTABLE = [
        "変わった人だった表",
        "元気すぎる。声も大きいし、自分は振り回されるし。ちょっと疲れる。",
        "優しそうだけど、どこか底知れない、何を考えているのかわからない人物だった。",
        "見るからに遊び人で、言動も軽く見える。どこか一定以上親しくなるのを恐れている部分が垣間見えた。",
        "ぶっきらぼうで一見とっつきづらい印象だけど、こちらのことをよく見ていて、助けようとしている。たぶん、寂しがり屋。",
        "トレンドを着こなしていて、いかにもおしゃれな人だった。ファッションだけでなく、あらゆることを調べて理解しようと動いている。努力の人なんだと思う。",
        "自分がその人にとって大事な人に似ているらしく、世話を焼こうとしてくれている。",
        "お菓子職人や料理人を目指しているらしく、試食を頼んでくる。",
        "誰かを助けなければならない、という理念があり、とにかく人助けをして回っている人だった。自分のことは二の次のようだ。",
        "すごい資産家の一族らしく、身に着けている物はすべて高級で、教養もあった。",
        "常に何かのアルバイトをしている。掛け持ちだから忙しくしているらしい。",
      ].freeze

      # LastName Table
      LNTABLE = [
        "名字表",
        "日本名字表1（JLTO）を使用する。",
        "日本名字表1（JLTO）を使用する。",
        "日本名字表2（JLTT）を使用する。",
        "日本名字表2（JLTT）を使用する。",
        "カタカナ名字表（FLT）を使用する。",
        "カタカナ名字表（FLT）を使用する。",
      ].freeze

      # FirstName Table
      FNTABLE = [
        "名前表",
        "日本名前表1（JFTO）を使用する。",
        "日本名前表1（JFTO）を使用する。",
        "日本名前表2（JFTT）を使用する。",
        "日本名前表2（JFTT）を使用する。",
        "カタカナ名前表（FFT）を使用する。",
        "カタカナ名前表（FFT）を使用する。",
      ].freeze

      TABLES = {
        # Japanese Lastname Table One
        "JLTO" => DiceTable::D66Table.new(
          "日本名字表1",
          D66SortType::ASC,
          {
            11 => "有栖（ありす）",
            12 => "佐藤（さとう）",
            13 => "鈴木（すずき）",
            14 => "葉月（はづき）",
            15 => "如月（きさらぎ）",
            16 => "皐月（さつき）",
            22 => "九重（ここのえ）",
            23 => "高橋（たかはし）",
            24 => "田中（たなか）",
            25 => "右京（うきょう）",
            26 => "七海（ななみ）",
            33 => "小春（こはる）",
            34 => "伊藤（いとう）",
            35 => "渡辺（わたなべ）",
            36 => "飛鳥（あすか）",
            44 => "渡井（わたらい）",
            45 => "井上（いのうえ）",
            46 => "氷室（ひむろ）",
            55 => "錦（にしき）",
            56 => "柳（やなぎ）",
            66 => "蓬莱（ほうらい）",
          }
        ),
        # Japanese Lastname Table Two
        "JLTT" => DiceTable::D66Table.new(
          "日本名字表2",
          D66SortType::ASC,
          {
            11 => "蜂須賀（はちすか）",
            12 => "山本（やまもと）",
            13 => "中村（なかむら）",
            14 => "御影（みかげ）",
            15 => "四季（しき）",
            16 => "常磐（ときわ）",
            22 => "栗栖（くりす）",
            23 => "小林（こばやし）",
            24 => "加藤（かとう）",
            25 => "花野井（はなのい）",
            26 => "綾瀬（あやせ）",
            33 => "乙女（おとめ）",
            34 => "吉田（よしだ）",
            35 => "山田（やまだ）",
            36 => "桐葉（きりは）",
            44 => "桔梗（ききょう）",
            45 => "松本（まつもと）",
            46 => "音羽（おとわ）",
            55 => "蓮見（はすみ）",
            56 => "桜森（さくらもり）",
            66 => "百合園（ゆりぞの）",
          }
        ),
        # Foreien Lastname Table
        "FLT" => DiceTable::D66Table.new(
          "カタカナ名字表",
          D66SortType::ASC,
          {
            11 => "レイエス",
            12 => "スミス",
            13 => "ジョンソン",
            14 => "ウィリアム",
            15 => "ブラウン",
            16 => "ジョーンズ",
            22 => "シュルツ",
            23 => "エメリヒ",
            24 => "ファル",
            25 => "クルツ",
            26 => "マイアー",
            33 => "コスキネン",
            34 => "モロー",
            35 => "ルノー",
            36 => "ロベール",
            44 => "ラ",
            45 => "エン",
            46 => "キョウ",
            55 => "ハン",
            56 => "ユン",
            66 => "ホン",
          }
        ),
        # Japanese Firstname Table One
        "JFTO" => DiceTable::D66Table.new(
          "日本名前表1",
          D66SortType::ASC,
          {
            11 => "涼太（りょうた）／八重（やえ）",
            12 => "蒼（あおい）／雅（みやび）",
            13 => "樹（いつき）／凛（りん）",
            14 => "蓮（れん）詩（うた）",
            15 => "翔（しょう）／舞（まい）",
            16 => "翼（つばさ）／鈴（すず）",
            22 => "遼（りょう）／瑠華（るか）",
            23 => "陽翔（はると）／結菜（ゆな）",
            24 => "律（りつ）／莉子（りこ）",
            25 => "輝（ひかる）／陽葵（ひまり）",
            26 => "仁（じん）／乃愛（のあ）",
            33 => "大夢（ひろむ）／阿澄（あすみ）",
            34 => "朝陽（あさひ）／結月（ゆづき）",
            35 => "大翔（ひろと）／結愛（ゆあ）",
            36 => "隼人（はやと）／萌花（もか）",
            44 => "公太（こうた）／春歌（はるか）",
            45 => "大和（やまと）／澪（みお）",
            46 => "拓真（たくま）／奈々（なな）",
            55 => "雄大（ゆうだい）／明日香（あすか）",
            56 => "悠（ゆう）／彩（あや）",
            66 => "秀助（しゅうすけ）／那留（なる）",
          }
        ),
        # Japanese Firstname Table Two
        "JFTT" => DiceTable::D66Table.new(
          "日本名前表2",
          D66SortType::ASC,
          {
            11 => "一郎（いちろう）／かぐや",
            12 => "太一（たいち）／さくら",
            13 => "颯太（そうた）／あかり",
            14 => "瑛斗（えいと）／こはる",
            15 => "俊輔（しゅんすけ）／ひなた",
            16 => "大地（だいち）／すみれ",
            22 => "健太（けんた）／里奈（りな）",
            23 => "歩（あゆむ）／春菜（はるな）",
            24 => "伊織（いおり）／芽衣（めい）",
            25 => "航（わたる）／愛美（あいみ）",
            26 => "優希（ゆうき）／綾乃（あやの）",
            33 => "直樹（なおき）／茜（あかね）",
            34 => "煌（こう）／もも",
            35 => "陽向（ひなた）／ひかり",
            36 => "将吾（しょうご）／ほのか",
            44 => "和也（かずや）／美穂（みほ）",
            45 => "巧（たくみ）／未来（みらい）",
            46 => "直哉（なおや）／朱里（しゅり）",
            55 => "亮（りょう）／瞳（ひとみ）",
            56 => "陸人（りくと）／心音（ここね）",
            66 => "康平（こうへい）／沙織（さおり）",
          }
        ),
        # Foreien Firstname Table
        "FFT" => DiceTable::D66Table.new(
          "カタカナ名前表",
          D66SortType::ASC,
          {
            11 => "カルロ／ビアンカ",
            12 => "リアム／オリビア",
            13 => "イライジャ／エイヴァ",
            14 => "オリバー／ミア",
            15 => "ジェームズ／アメリア",
            16 => "メイソン／シャーロット",
            22 => "オネスト／カルメン",
            23 => "ブルーノ／アンネ",
            24 => "エーミール／クラーラ",
            25 => "ラインハルト／エッダ",
            26 => "テオ／リア",
            33 => "ロメオ／ルチア",
            34 => "セドリック／マリアンヌ",
            35 => "コーム／リーズ",
            36 => "ギー／カトリーヌ",
            44 => "ハオユー／ルーシー",
            45 => "ハオラン／イーラン",
            46 => "イーチェン／シンイー",
            55 => "ウヌ／ハユン",
            56 => "ソジュン／ソア",
            66 => "ジュウォン／スピン",
          }
        ),
      }.freeze
    end
  end
end
