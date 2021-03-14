# frozen_string_literal: true

module BCDice
  module GameSystem
    class FilledWith < Base
      # ゲームシステムの識別子
      ID = 'FilledWith'

      # ゲームシステム名
      NAME = 'フィルトウィズ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふいるとういす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定 (3FW@x#y<=z or z-3FW@x#y)
         3個の6面ダイスを振る判定。
         @x:xにクリティカル値を入力。省略可。(省略時クリティカル値4)
         #y:yにファンブル値を入力。省略可(省略時ファンブル値17)
         <=z or z-:zに目標値を入力。±の計算に対応。省略可。
        ・【必殺技！】 (HST)
         ホムンクルス特技【必殺技！】表。
        ・マジカルクッキング (COOKx)
         マジカルクッキングのシェフのおすすめコース。
         xにクッキングレベルを入力。(1-8)
        ・ナンバーワンくじ (LOTN or LOTP)
         LOTNでノーマルくじ、LOTPでプレミアムくじ。(GURPS-FW版)
        ----------夢幻の迷宮用----------
        ・共通書式
         a:aに地形(1-6の数字)を入力。省略可。(省略時ランダム決定)
          (1:洞窟 2:遺跡 3:山岳 4:水辺 5:森林 6:墓場)
         d:dに難易度を入力。(E:初級 N:中級 H:上級 L:悪夢 X:伝説)
        ・ランダムイベント表 (RANDda)
        ・ランダムエンカウント表 (RENCda)
        ・エネミーデータ表 (REDde)
         エネミーデータ参照表。
         GMがシークレットダイスで参照するとPLに知られずにエネミーデータを参照可能。
         e:3桁のイベントダイスを入力(D666の結果)。
        ・トラップ表 (TRAPd)
        ・財宝表 (TRSr±x)
         r:rに財宝ランクを入力。
         ±x:xに財宝ランク修正値を入力。省略可。
        ・迷宮追加オプション表(ROPd)
      MESSAGETEXT

      register_prefix('3FW', '[\+\-\d]*-3FW', 'LOT[NP]', 'HST', 'COOK[1-8]', 'RAND', 'RENC', 'RED', 'TRS', 'TRAP[ENHLX]', 'ROP[ENHLX]')

      def initialize(command)
        super(command)
        @d66_sort_type = D66SortType::NO_SORT; # d66の差し替え
      end

      # @param command [String] コマンド
      # @return [Result, nil] 固有コマンドの評価結果
      def eval_game_system_specific_command(command)
        # ダイスロールコマンド
        result = checkRoll(command)
        return result unless result.nil?

        tableName = ""
        number = 0

        # 各種コマンド
        case command
        when "LOTN"
          return roll_jump_table("ナンバーワンノーマルくじ", LOT_NORMAL_TABLES[1])

        when "LOTP"
          return roll_jump_table("ナンバーワンプレミアムくじ", LOT_PREMIUM_TABLES[1])

        when "HST"
          tableName = "【必殺技！】"
          result, number = getSpecialResult

        when /COOK([1-8])/
          lv = Regexp.last_match(1).to_i
          return roll_jump_table("マジカルクッキング", COOK_TABLES[lv])

        when /TRAP[ENHLX]/
          return roll_trap_table(command)

        when /TRS.*/i
          return getTresureResult(command)

        when /RAND.*/
          return roll_random_event_table(command)

        when /RENC.*/
          return roll_random_event_table(command)

        when /RED.*/i
          return fetch_enemy_data(command)

        when /ROP[ENHLX]/
          return roll_random_option_table(command)

        else
          return nil
        end

        return Result.new(format_table_roll_result(tableName, number, result))
      end

      # 表を振った結果を独自の書式で整形する
      # @param table_name [String] 表の名前
      # @param number [String] 出目の文字列
      # @param result [String] 結果の文章
      # @return [String]
      def format_table_roll_result(table_name, number, result)
        "#{table_name}(#{number}):#{result}"
      end

      # ジャンプする項目を含む表を振る
      # @param table_name [String] 表の名前
      # @param table [DiceTable::RangeTable] 振る対象の表
      # @return [Result]
      def roll_jump_table(table_name, table)
        # 出目の配列
        values = []

        loop do
          roll_result = table.roll(@randomizer)
          values.concat(roll_result.values)

          content = roll_result.content
          case content
          when String
            return Result.new(format_table_roll_result(table_name, values.join, content))
          when Proc
            # 次の繰り返しで指定された表を参照する
            table = content.call
          else
            raise TypeError
          end
        end
      end

      def checkRoll(command)
        crt = 4
        fmb = 17

        if command =~ /(\d[+\-\d]*)-(\d+)FW(@(\d+))?(\#(\d+))?/i
          difficultyText = Regexp.last_match(1)
          diceCount = Regexp.last_match(2).to_i
          crt = Regexp.last_match(4).to_i unless Regexp.last_match(3).nil?
          fmb = Regexp.last_match(6).to_i unless Regexp.last_match(5).nil?
        elsif command =~ /(\d+)FW(@(\d+))?(\#(\d+))?(<=([+\-\d]*))?/i
          diceCount = Regexp.last_match(1).to_i
          crt = Regexp.last_match(3).to_i unless Regexp.last_match(2).nil?
          fmb = Regexp.last_match(5).to_i unless Regexp.last_match(4).nil?
          difficultyText = Regexp.last_match(7)
        else
          return nil
        end

        # 目標値の計算
        difficulty = getValue(difficultyText, nil)

        # ダイスロール
        dice_list = @randomizer.roll_barabara(diceCount, 6)
        dice = dice_list.sum()
        dice_str = dice_list.join(",")

        # 出力用ダイスコマンドを生成
        command = "#{diceCount}FW"
        command += "@#{crt}" unless crt == 4
        command += "##{fmb}" unless fmb == 17
        command += "<=#{difficulty}" unless difficulty.nil?

        # 出力文の生成
        result = "(#{command}) ＞ #{dice}[#{dice_str}]"

        # クリティカル・ファンブルチェック
        if dice <= crt
          result += " ＞ クリティカル！"
        elsif dice >= fmb
          result += " ＞ ファンブル！"
        else
          # 成否判定
          unless difficultyText.nil?
            success = difficulty - dice
            if dice <= difficulty
              result += " ＞ 成功(成功度:#{success})"
            else
              result += " ＞ 失敗(失敗度:#{success})"
            end
          end
        end

        return result
      end

      def getValue(text, defaultValue)
        return defaultValue if text.nil? || text.empty?

        ArithmeticEvaluator.eval(text)
      end

      def getAdjustNumber(number, table)
        min = table.first.first
        return min if number < min

        max = table.last.first
        return max if number > max

        return number
      end

      # 必殺技表
      def getSpecialResult
        table = [
          '〔命中〕判定に出目[1,1,1]でクリティカル。更に致傷力に「SLv×20」のボーナスを得る。',
          '〔命中〕判定と致傷力に「SLv×10」のボーナスを得る。',
          '致傷力に「SLv×10」のボーナスを得る。',
          '攻撃が命中するとバッドステータス「転倒」を与える。',
          '通常攻撃。',
          '〔命中〕判定に[6,6,6]でファンブル。更に、使用者がバッドステータス「転倒」を受ける。',
        ]
        return get_table_by_1d6(table)
      end

      class Row
        def initialize(body, *args)
          @body = body
          @args = args
        end

        def format(difficulty)
          args = @args.map { |e| e[difficulty.index] }
          Kernel.format(@body, *args)
        end
      end

      class Difficulty
        DIFFICULTYS = ["E", "N", "H", "L", "X"].freeze

        NAMES = {
          "E" => "初級",
          "N" => "中級",
          "H" => "上級",
          "L" => "悪夢",
          "X" => "伝説",
        }.freeze

        def initialize(sign)
          @sign = sign
        end

        def index
          @index ||= DIFFICULTYS.find_index(@sign)
        end

        def name
          @name ||= NAMES[@sign]
        end
      end

      TRAP_TABLE = [
        Row.new("トライディザスター:宝箱から広範囲に火炎・冷気・電撃が放たれる罠。PC全員に「%s」の「火炎」「冷気」「電撃」属性ダメージ。", ['3D6+3', '3D6+50', '3D6+70', '3D6+100', '300']),
        Row.new("ペトロブラスター:広範囲に石化光線を放つ罠。PC全員[抵抗-%s]判定を行い、失敗したPCはBS「石化」を受ける。", [2, 4, 6, 8, 10]),
        Row.new("クロスボウストリーム:宝箱から矢の嵐が放たれる罠。PC全員に「%s」の「刺突」属性ダメージ。「ドッジ-%s」で〔回避〕が可能。", ['3D6+20', '3D6+40', '3D6+60', '3D6+90', '200'], [4, 6, 8, 10, 20]),
        Row.new("フォーチュンイーター:PC全員の幸運を食らい、Ftを%s点減少させる。Ftが0の場合「%s」点の防護点無視ダメージ。", [1, 2, 3, 4, 5], ['3D6+30', '3D6+50', '3D6+70', '3D6+100', '300']),
        Row.new("スロット:解除に失敗しても害はないが、スロットが揃うまで開かない宝箱。スロットを1回まわすには%sGPが必要。行動を消費して[感覚-%s]判定に成功すればスロットは揃う。有利な特異点「ビビット反射」があれば判定に+4のボーナス。", [100, 300, 600, 1000, 10000], [4, 6, 8, 10, 15]),
        Row.new("テレポーター:PC全員(とエンカウントしているエネミー)を転送して道に迷わせる。「財宝ランク」が1段階減少する。"),
        Row.new("アイスコフィン:宝箱を開けようとしたキャラクターを氷漬けにする罠。対象1体に「%s」の「冷気」属性ダメージ。更にFPにも%s点の防護点無視ダメージ。", ['3D6+30', '3D6+50', '3D6+70', '3D6+100', '300'], [5, 10, 15, 20, 30]),
        Row.new("クロスボウ:宝箱を開けようとしたキャラクターに強力な矢が放たれる罠。対象1体に「%s」の「刺突」属性ダメージ。「ドッジ-%s」", ['3D6+20', '3D6+40', '3D6+60', '3D6+90', '200'], [4, 6, 8, 10, 20]),
        Row.new("毒針:宝箱を開けようとしたキャラクターに毒針を突き刺す罠対象1体に%s点の防護点無視ダメージ。更に[抵抗-%s]判定に失敗するとシナリオ終了まであらゆる判定に-2のペナルティ。", [15, 30, 45, 60, 150], [4, 6, 8, 10, 15]),
        Row.new("アラーム:即座にその地形のエンカウント表を振って、それに対応したエネミーが出現する。出現したエネミーはそのターンから行動順に組み込まれる。出現するエネミー以外の記述は無視する。"),
        Row.new("殺人鬼の斧:宝箱を開けようとしたキャラクターに斧が振り下ろされる罠。対象1体に「%s」の「打撃」「斬撃」属性ダメージ。「ドッジ-%s」か「シールド-%s」で〔回避〕が可能。", ['3D6+30', '3D6+50', '3D6+70', '3D6+100', '300'], [4, 6, 8, 10, 20], [4, 6, 8, 10, -20]),
        Row.new("死神:宝箱を開けようとしたキャラクターに死神を取り憑かせる罠。4ラウンド目が終了するまであらゆる判定に-3のペナルティを受け、4ラウンド目の終了と同時に「%s」の防護点無視ダメージ。", ['3D6+30', '3D6+50', '3D6+70', '3D6+100', '300']),
        Row.new("幻の宝:宝箱に偽の財宝を入れ、本物の財宝を入手させない罠。トラップが発動すると価値の無い偽の宝物「幻の宝」を入手してしまう。「幻の宝」はアイテム欄を3つ占有し、シナリオ終了まで捨てられない。アイテム欄に空きがない場合は、何かを捨てて誰かが必ず持たなくてはならない。"),
        Row.new("エクスプロージョン:宝箱が大爆発を起こし、中身を粉々にしてしまう罠。宝箱の中身は消滅する。PC全員に「%s」の「打撃」「火炎」属性ダメージ。", ['3D6+10', '3D6+30', '3D6+50', '3D6+80', '200']),
        Row.new("レインボーポイズン:宝箱から七色の毒ガスが放たれる罠。PC全員に「%s」の防護点無視ダメージ。更にシナリオ終了まであらゆる判定に-2のペナルティ。[抵抗-%s]判定に成功すれば無効。", ['3D6+10', '3D6+30', '3D6+50', '3D6+80', '200'], [4, 6, 8, 10, 15]),
        Row.new("デスクラウド:宝箱から致死性の毒ガスを放つ罠。PC全員を即死させる。[抵抗-%s]判定に成功すれば無効。", [2, 4, 6, 8, 12]),
      ].freeze

      # 夢幻の迷宮トラップ表
      def roll_trap_table(command)
        m = /^TRAP([ENHLX])$/.match(command)
        unless m
          return nil
        end

        difficality = Difficulty.new(m[1])
        number = @randomizer.roll_sum(3, 6)
        chosen = TRAP_TABLE[number - 3]

        return "トラップ表<#{difficality.name}>(#{number}):#{chosen.format(difficality)}"
      end

      class D66Table
        def initialize(name, rows)
          @name = name
          @rows = rows
        end

        def roll(randomizer, difficality)
          value = randomizer.roll_d66(D66SortType::NO_SORT)
          chosen = @rows[value]

          "#{@name}<#{difficality.name}>(#{value}):#{chosen.format(difficality)}"
        end
      end

      OPTION_TABLE = D66Table.new(
        "迷宮追加オプション表",
        {
          11 => Row.new("黄金の迷宮(財宝ランク+2):全てが黄金で彩られた迷宮。財宝ランクが大きく上昇する。"),
          12 => Row.new("密林の迷宮(財宝ランク+1):密林の中にひっそりとたたずむ迷宮。分類が「魔獣」「獣人」「霊獣」のエネミーが行うあらゆる判定に+2のボーナス。"),
          13 => Row.new("カラクリの迷宮:複雑なカラクリが周囲で絶え間なく動いている迷宮。分類「ギア」のエネミーが行うあらゆる判定に+2のボーナス。クリア時に「アタッチメント割引券」を全員が%s枚獲得。", [1, 2, 3, 5, 10]),
          14 => Row.new("フラウの舞踏会:あちこちに花畑のある迷宮。フラウが発生するランダムイベントが発生した際、「この迷宮を制覇して、私達が舞踏会を開けるようにしてね」とお願いされ、クリア時の報酬に%sが追加される。", ['「キノコの帽子」(装飾品)', '「猛毒の花」(装飾品)', '「フルブロウン」(鎧)', '「緊急召喚の宝珠」(装飾品)', '魔将樹の大剣（剣）']),
          15 => Row.new("アズマ風の迷宮:風流なアズマ風の迷宮。武器に「刀」を持つエネミーが行うあらゆる判定に+2のボーナス。クリア時に「アタッチメント割引券」を全員が%s枚獲得。", [1, 2, 3, 5, 10]),
          16 => Row.new("枯れた泉の迷宮:「全地形1-1」の回復の泉が全て枯れており、回復効果を得ることができない。「山岳1-6」の貴重な水源や、「水辺1-6」の毒の泉などはそのまま存在する。"),
          21 => Row.new("天空への道(財宝ランク+1):上へ上へと果てしなく登っていく迷宮。空気が薄くなって疲労しやすくなる。【特技】特技などによるFP消費が全て+3。"),
          22 => Row.new("灼熱焦土の迷宮(財宝ランク+1):とてつもなく暑く、あちこちで炎が燃え盛る迷宮。エネミーが行う「火炎」属性を含む攻撃の致傷力に+%sのボーナス。", [10, 20, 30, 50, 100]),
          23 => Row.new("灼熱焦土の迷宮(財宝ランク+1):とてつもなく寒く、気温が氷点下の迷宮。エネミーが行う「冷気」属性を含む攻撃の致傷力に+%sのボーナス。", [10, 20, 30, 50, 100]),
          24 => Row.new("盗賊王の迷宮:迷宮内での罠や鍵を解除する[感覚]判定に-3のペナルティ。4ラウンドまでに出現した宝箱の「財宝ランク」+1。"),
          25 => Row.new("ミミック狂暴化:「全地形2-5」のミミックの致傷力に+%sのボーナス。ミミックを見破った場合に得られるGPが%sGP増加する。", [20, 30, 50, 80, 150], [500, 1000, 3000, 5000, 20000]),
          26 => Row.new("トレジャーイーター狂暴化:「全地形2-6」のトレジャーイーターを見破る[知力]判定に-3のペナルティ。4ラウンドまでに出現した宝箱の「財宝ランク」+1。"),
          31 => Row.new("暗闇の迷宮:どこもかしこも真っ暗な迷宮。「猫の目」などがなければ視覚に関する[感覚]判定に-5のペナルティ。"),
          32 => Row.new("騒音の迷宮:常に大音量で謎の音楽(BGM)が鳴っている迷宮。聴覚に関する[感覚]判定に-5のペナルティ。"),
          33 => Row.new("未知の怪物の迷宮(財宝ランク+1):エネミーの姿がシルエットのみになる迷宮。エネミーのデータがいかなる手段でも判明させられなくなる。(通常通り〔HP〕〔FP〕〔先制〕は判明する)"),
          34 => Row.new("氾濫中の迷宮:大雨が降っており、川などが氾濫している迷宮。水泳を行う際の[敏捷]判定に-5のペナルティ。「森林3-6」の山火事イベントの効果は無視できる。"),
          35 => Row.new("間抜けの迷宮(財宝ランク+1):頭がおかしくなりそうな極彩色の迷宮。[知力][意志]判定に-2のペナルティ。[知力]や[意志]そのものが下がるわけではない。"),
          36 => Row.new("瘴気の迷宮(財宝ランク+1):生命力を奪う紫の霧で満ちた迷宮。〔HP〕の最大値に-%sのペナルティ。", [10, 20, 30, 40, 50]),
          41 => Row.new("加速する迷宮:狂ったように針の動く時計が多数された迷宮。「CT:安息の日」以外の【特技】が「CT:なし」になる。"),
          42 => Row.new("停滞する迷宮(財宝ランク+1):動かない時計が多数設置された迷宮。「CT:安息の日」以外のCTの存在する【特技】が「CT:シナリオ終了」になる。この効果はシナリオ終了まで持続する。"),
          43 => Row.new("猛毒の迷宮(財宝ランク+1):見るからに毒々しい紫色の沼があちこちにある迷宮。エネミーが行う、名称に「毒」もしくは「ポイズン」が入る【特技】や、名称に「毒」もしくは「ポイズン」が入るトラップの致傷力に+%sのボーナス。", [10, 20, 40, 50, 100]),
          44 => Row.new("死の迷宮(財宝ランク+2):死の運命から逃れることのできない、血まみれの迷宮。「生命保険証」の効果が適用されない。"),
          45 => Row.new("幸運の迷宮:何者かの加護を感じる迷宮。PC全員のFtの最大値と現在値に+1のボーナス。この効果はシナリオ終了まで持続する。"),
          46 => Row.new("不運の迷宮:PC全員のFt最大値と現在値に-1のペナルティ。この効果はシナリオ終了まで持続する。"),
          51 => Row.new("レアメタルの迷宮:非常にレアなエネミー「レアメタルキャンディー」「レアメタルクラウン」が生息している迷宮。キャンディークラウン(CL40)、ゴールデンクラウン(CL177)から獲得できる通常ドロップのGPが5倍になる。"),
          52 => Row.new("魔力の泉:PCとエネミーの双方が、〔FP〕を消費せずに【魔法】を使用できるようになる。最終的な消費〔FP〕が最大〔FP〕より大きい【魔法】は使用できない。"),
          53 => Row.new("ブルーの迷宮:陰鬱な気分になり、他のキャラクターと関わる気力を失う。PC全員が不利な特異点「嫌な奴」を1段階得る。"),
          54 => Row.new("レッドの迷宮:なぜか興奮して非常に好戦的になる。PC全員が不利な特異点「脳みそ筋肉」を得る。交戦中に「1:回復系」のイベントが発生しても戦闘を終了させることができない。"),
          55 => Row.new("ピンクの迷宮:なんだか身近な異性(同性も?)が気になって仕方なくなる。PC全員が不利な特異点「英雄色を好む」を得る。魔族も戦闘意欲を失い、「分類:魔族」のエネミーが出現するイベントは無視する。"),
          56 => Row.new("ハズレの迷宮(財宝ランク-1):ツギハギだらけの壁などでできた、ハリボテのような貧相な迷宮。宝箱の中身もなんだか貧相になる。"),
          61 => Row.new("ラダマンティスの迷宮(財宝ランク+2):第一魔将ラダマンティスの像が入口に設置された迷宮。全てのエネミーが行うあらゆる判定に+2のボーナス。また、「遺跡6-6」のイベントのダメージ+%s。", [20, 40, 60, 80, 150]),
          62 => Row.new("グレイヴディガーの迷宮(財宝ランク+2):第二魔将グレイヴディガーの像が入口に設置された迷宮。「分類:アンデッド」のエネミーが行うあらゆる判定に+5のボーナス。"),
          63 => Row.new("ハイペリオンの迷宮(財宝ランク+2):第三魔将ハイペリオンの像が入口に設置された迷宮。全てのエネミーが「ターン開始」時に〔HP〕を全回復する。"),
          64 => Row.new("ムスペルニヴルの迷宮(財宝ランク+2):勇ましくも美しい女性の像が設置された迷宮。エネミーが行う「火炎」もしくは「冷気」属性を含む攻撃の致傷力に+%sのボーナス。", [20, 40, 60, 80, 150]),
          65 => Row.new("ウェルスの迷宮:人懐っこそうなアズマ風の青年が設置された迷宮。シナリオ上で第五魔将の正体が明らかに鳴っている場合のみ、PC全員のFtの最大値と現在値に+5のボーナス。この効果はシナリオ終了まで持続する。"),
          66 => Row.new("バロールの迷宮(財宝ランク+2):第六魔将バロールの像が入口に設置された迷宮。「分類:ギア」のエネミーが行うあらゆる判定に+5のボーナス。"),
        }
      )

      # 夢幻の迷宮追加オプション表
      def roll_random_option_table(command)
        m = /^ROP([ENHLX])$/.match(command)
        unless m
          return nil
        end

        difficality = Difficulty.new(m[1])
        return OPTION_TABLE.roll(@randomizer, difficality)
      end

      # 夢幻の迷宮ランダムイベント表
      def roll_random_event_table(command)
        m = /^(RAND|RENC)([ENHLX])([1-6])?$/.match(command)
        unless m
          return nil
        end

        type = m[1] == "RAND" ? nil : 4
        difficulty = Difficulty.new(m[2])
        area = m[3]&.to_i || @randomizer.roll_once(6)

        table = EVENT_TABLES[area - 1]
        return table.roll(@randomizer, difficulty, type: type)
      end
    end
  end
end

require "bcdice/game_system/filled_with/lot_tables"
require "bcdice/game_system/filled_with/enemy_data_tables"
require "bcdice/game_system/filled_with/event_tables"
require "bcdice/game_system/filled_with/cook_tables"
require "bcdice/game_system/filled_with/tresure_tables"
