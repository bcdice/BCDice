# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class Yggdrasill < Base
      ID = "Yggdrasill"

      NAME = "鋼鉄のユグドラシル"

      SORT_KEY = "こうてつのゆくとらしる"

      HELP_MESSAGE = <<~HELP_MESSAGE
        ■ 行為判定 (CFx+nD6)
          クリティカルとファンブルによるダイス追加を行う
          先頭のcfを変更することで、動作が変更される
          hcf: 達成値が半減
          cfl: 付加効果【幸運】を付与
          cfg: 付加効果【ギャンブル】を付与
          cft: 【応急処置】判定 (tは末尾に記入してください)
          例）
            CF10+1D6, HCFL6+2D6, CFG11+1D6-2, cfgt10+1D6

        ■ 暴走ロール (RAx)
          暴走率xの暴走ロールおよび臨界ロールを行う
          例）
            RA50, RA110, RA150

        ■ SOペナルティ表 (SOx)
          スペック数がxオーバーした際のペナルティロールを行う
          例）
            SO1, SO5

        ■ 【応急処置】 (TREATx)
          達成値xの【応急処置】による回復量を決定する
          例）
            TREAT1, TREAT18

        ■ その他の判定および表
          down：気絶判定
          cont：コンティニュー判定
          risk：リスク判定
          guki：偶奇判定
          cond：コンディションロール
          allr：オールレンジ発動ロール
          pafe：パーフェクト発動ロール
          stag：ステージ決定（電脳ロワイヤル用）
          fatal1：後遺症
          fatal2：因子変化ロール
          mikuzi：浅草寺みくじ。1d100であなたの運勢を占います
      HELP_MESSAGE

      register_prefix(
        'H?CF', 'RA', 'SO', 'DOWN', 'CO(NT)?',
        'RISK', 'GUKI', 'COND', 'TREAT',
        'ALLR', 'PAFE', 'FATAL', 'STAG', 'MIKUZI'
      )

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES) ||
          roll_cf(command) ||
          roll_ra(command) ||
          roll_treat(command) ||
          roll_down(command) ||
          roll_cond(command) ||
          roll_guki(command) ||
          roll_cont(command) ||
          roll_allr(command) ||
          roll_pafe(command)
      end

      private

      def roll_cf(command)
        # マイナス補正にダイスロールを用いることはシステム上ありえないため、正規表現ではじく
        m = /^(H)?CF([LG])?(T)?((?:[+-]*\d+|\+?\d+D\d+)(?:[+-]+\d+|\++\d+D\d+)*)$/.match(command)
        return nil unless m

        hoge = !m[1].nil?
        lucky_state = m[2]
        treat_flg = !m[3].nil?

        expr = m[4]

        node = CommonCommand::AddDice::Parser.parse(expr)
        return nil unless node

        add_dice_randomizer = CommonCommand::AddDice::Randomizer.new(@randomizer, self)
        total = node.lhs.eval(self, add_dice_randomizer)
        rand_values = add_dice_randomizer.rand_results.map(&:value)

        n1 = count_fumble(rand_values, lucky_state)
        n_max = count_critical(rand_values, lucky_state)

        # ファンブルロール
        fa_list = @randomizer.roll_barabara(n1, 6)
        fa1 = fa_list.sum
        fa2 = fa_list.join(",")

        critical_rerolls = []
        rerolls = n_max
        while rerolls > 0
          list = @randomizer.roll_barabara(rerolls, 6)
          critical_rerolls.push(list)

          rerolls = list.count(6)
        end
        # crの達成値を合計する・cr出目を見易く
        cr1 = critical_rerolls.flatten.sum
        cr2 = critical_rerolls.map { |x| "[#{x.join(',')}]" }.join()

        # 修正値&一投目出目 -ファンブル +クリティカル
        total_n = total - fa1 + cr1
        total_n /= 2 if hoge == true
        # 最終達成値
        result = "計【 #{total_n} 】"

        text = "(#{command}) ＞ #{result} ： #{node.lhs.output}"
        # クリファン有無に応じて表示の追加
        text += " (fa:#{n1})-#{fa1}[#{fa2}]" if n1 > 0
        text += " (cr:#{n_max})+#{cr1}#{cr2} (cr:計#{critical_rerolls.flatten.size}回)" if cr1 > 0

        if treat_flg == true
          # TREAT追加処理
          heal = eval_game_system_specific_command("TREAT#{total_n}")
          text += "\n ＞ #{heal}"
        end

        return text
      end

      def count_critical(dice_list, lucky_state)
        threshold =
          if lucky_state == "G"
            4
          elsif lucky_state
            5
          else
            6
          end

        dice_list.count { |x| x >= threshold }
      end

      def count_fumble(dice_list, lucky_state)
        threshold =
          if lucky_state == "G"
            3
          elsif lucky_state
            2
          else
            1
          end

        dice_list.count { |x| x <= threshold }
      end

      def roll_ra(command)
        m = /^RA(\d+)?$/.match(command)
        return nil unless m

        body =
          case m[1]&.to_i
          when 50
            RA50.roll(@randomizer)
          when 70
            RA70.roll(@randomizer)
          when 90
            RA90.roll(@randomizer)
          when 110, 120, 130, 140
            RA110.roll(@randomizer)
          when 150
            "＞ 因子崩壊【キャラロスト】"
          when nil
            "＞ このコマンドは数値を付けてください"
          else
            "＞ 指定の暴走率の暴走ロールはありません"
          end

        "(#{command}) #{body}"
      end

      def roll_treat(command)
        m = /^TREAT(-?\d+)?$/.match(command)
        return nil unless m

        unless m[1]
          return "ＡＥ【応急処置】 ＞ このコマンドは数値を付けてください"
        end

        value = m[1]&.to_i

        recovery =
          if value <= 5
            0
          elsif value <= 7
            1
          elsif value <= 11
            dice = @randomizer.roll_once(6)
            total = dice / 2
            "#{total}(#{dice}[#{dice}]/2)"
          elsif value <= 14
            dice = @randomizer.roll_once(6)
            "#{dice}(#{dice}[#{dice}])"
          elsif value <= 17
            dice = @randomizer.roll_once(6)
            total = dice + 3
            "#{total}(#{dice}[#{dice}]+3)"
          else
            list = @randomizer.roll_barabara(2, 6)
            dice = list.sum()
            total = dice + 2
            "#{total}(#{dice}[#{list.join(',')}]+2)"
          end

        "ＡＥ【応急処置】 ＞ HPが#{recovery}回復"
      end

      def roll_down(command)
        return nil unless command == 'DOWN'

        dice = @randomizer.roll_once(6)

        result =
          if dice.even?
            "回避"
          else
            fell = @randomizer.roll_once(6)
            "気絶【#{fell}R行動不能】"
          end

        "気絶判定 ＞ #{dice} ＞ #{result}"
      end

      def roll_cond(command)
        return nil unless command == 'COND'

        hp_list = @randomizer.roll_barabara(2, 6)
        hp_total = hp_list.sum
        hp_str = hp_list.join(",")

        pp_list = @randomizer.roll_barabara(2, 6)
        pp_total = pp_list.sum
        pp_str = pp_list.join(",")

        return "(#{command}) ＞ HP#{hp_total}[#{hp_str}] 、 PP#{pp_total}[#{pp_str}]"
      end

      def roll_guki(command)
        return nil unless command == 'GUKI'

        dice = @randomizer.roll_once(6)
        result = dice.even? ? "成功" : "失敗"

        "(GUKI) ＞ #{dice} ＞ #{result}"
      end

      def roll_cont(command)
        return nil unless /CO(NT)?/.match?(command)

        dice = @randomizer.roll_once(6)
        text = dice <= 4 ? "1R追加" : "2R追加"

        "コンティニュー判定 ＞ #{dice} ＞ #{text}"
      end

      def roll_allr(command)
        return nil unless command == 'ALLR'

        dice = @randomizer.roll_once(6)
        text =
          if dice == 1
            "発動失敗【技対象が敵味方含めた全員となる】"
          else
            "発動成功"
          end

        "オールレンジ判定 ＞ #{dice} ＞ #{text}"
      end

      def roll_pafe(command)
        return nil unless command == "PAFE"

        dice = @randomizer.roll_once(6)
        text =
          if dice == 1
            "発動失敗【通常命中・回避判定となり、発動時のアクション内の命中力＆回避力が半減する】"
          else
            "発動成功"
          end

        "発動ロール ＞ #{dice} ＞ #{text}"
      end

      class YggTable < DiceTable::Table
        def initialize(name, type, items, additonal_type:, additonal_format:, additonal_index:, out_of_control: nil)
          super(name, type, items)

          m = /(\d+)D(\d+)/i.match(additonal_type)
          unless m
            raise ArgumentError, "Unexpected table type: #{additonal_type}"
          end

          @additonal_times = m[1].to_i
          @additonal_sides = m[2].to_i
          @format = additonal_format
          @index = additonal_index
          @out_of_control = out_of_control
        end

        def roll(randomizer)
          value = randomizer.roll_sum(@times, @sides)
          chosen = choice(value)

          return chosen unless @index.include?(value) || @out_of_control == value

          body =
            if @out_of_control == value
              "#{chosen.body} ： #{RA90.roll(randomizer)}"
            else
              list = randomizer.roll_barabara(@additonal_times, @additonal_sides)
              chosen.body + format(@format, total: list.sum(), list: list.join(","))
            end

          DiceTable::RollResult.new(chosen.table_name, chosen.value, body)
        end
      end

      PSY_TABLE = DiceTable::Table.new(
        "能力タイプ",
        "1D6",
        [
          'サイキッカー',
          'エスパー',
          'トランサー',
          'クリエイター',
          'アンノウン',
          '好きな能力タイプを選択。ノーマル選択でも可'
        ]
      )

      RA50 = YggTable.new(
        "暴走Lv.1",
        "1D6",
        [
          '発作【自爆÷2ダメージ。（自身に能力攻撃ロールダメージ÷2）。防御無視】',
          '高揚【1D6暴走率上昇】',
          '高揚【1D6暴走率上昇】',
          '自制【暴走なし】',
          '自制【暴走なし】',
          '自制【暴走なし】',
        ],
        additonal_type: "1D6",
        additonal_format: " ： %{total}[%{list}] ％",
        additonal_index: [2, 3]
      )

      RA70 = YggTable.new(
        "暴走Lv.3",
        "1D6",
        [
          '自爆【自爆ダメージ。自身に能力攻撃ロールダメージ。防御無視】',
          '自爆【自爆ダメージ。自身に能力攻撃ロールダメージ。防御無視】',
          '暴発【ランダム攻撃。基本的に能力攻撃。対象は自分、キャラ、オブジェクトの三種類】',
          '連鎖【2D6暴走率上昇】',
          '発症',
          '自制【暴走無し】'
        ],
        additonal_type: "2D6",
        additonal_format: " ： %{total}[%{list}] ％",
        additonal_index: [4],
        out_of_control: 5
      )

      RA90 = DiceTable::D66ParityTable.new(
        "暴走状態表",
        [
          '能力異常【能力使用時に偶奇判定。奇数の場合は消費だけ行い能力発動失敗。暴走チェックごとに+2％される（発症時も発生）。能力精度の判定結果が半減】',
          '言語異常【AE使用時に偶奇判定。奇数の場合は消費だけ行いAE発動失敗。話術の判定結果が半減】',
          '記憶異常【命中判定結果が半減する。知識の判定結果が半減】',
          '精神異常【自分のリアクション（回避判定など）で偶奇判定。奇数の場合は行動自動失敗。隠密、読心の判定結果が半減】',
          '忘我【自プリアクション時に偶奇判定。奇数の場合は宣言せずにターン終了。あらゆる技能判定結果が半減】',
          '自制【暴走無し】'
        ],
        [
          '制御異常【自プリアクション毎（行動決定前）に偶奇判定。奇数の場合は暴発によるランダム攻撃。（発症時も発生）。技術、幸運の判定結果が半減】',
          '過負荷【ワンアクション毎に能力精度÷3の防御無視ダメージ（発症時も発生）。閃きの判定結果が半減】',
          '聴覚異常【回避判定結果が半減する。察知の半減結果が半減】',
          '視覚異常【SS＆命中力＆回避力が半減する※判定結果は半減しない。観察眼の判定結果が半減】',
          '身体異常【防御を差し引く前のダメージロールが半減する。力技、俊敏の判定結果が半減】',
          '自制【暴走なし】'
        ]
      )

      RA110 = YggTable.new(
        "臨界ロール",
        "1D6",
        [
          '自壊【自爆ダメージ。自身の最も高い攻撃ロールダメージ。防御無視】',
          '超活性【HP・PPを2D6回復】',
          '自壊【自爆ダメージ。自身の最も高い攻撃ロールダメージ。防御無視】',
          '超活性【HP・PPを2D6回復】',
          '自壊【自爆ダメージ。自身の最も高い攻撃ロールダメージ。防御無視】',
          '超活性【HP・PPを2D6回復】'
        ],
        additonal_type: "2D6",
        additonal_format: " ： %{total}[%{list}] 回復",
        additonal_index: [2, 4, 6]
      )

      TABLES = {
        "MIKUZI" => DiceTable::RangeTable.new(
          "おみくじ",
          "1D100",
          [
            [1..17, "大吉"],
            [18..52, "吉"],
            [53..57, "半吉"],
            [58..61, "小吉"],
            [62..64, "末小吉"],
            [65..70, "末吉"],
            [71..100, "凶"],
          ]
        ),
        "SO1" => YggTable.new(
          "SOペナルティ表 1オーバー",
          "1D6",
          [
            '消費負荷【ＰＰ２倍消費　※ＡＥ消費は含まない】',
            '消費負荷【ＰＰ２倍消費　※ＡＥ消費は含まない】',
            '消費負荷【ＰＰ２倍消費　※ＡＥ消費は含まない】',
            '反動',
            '反動',
            '制御成功【発動成功　ペナルティ無し】'
          ],
          additonal_type: "1D6",
          additonal_format: "【命中＆回避－１Ｄ６（%{total}[%{list}]）　１ラウンド継続】",
          additonal_index: [4, 5]
        ),
        "SO2" => YggTable.new(
          "SOペナルティ表 2オーバー",
          "1D6",
          [
            '自爆【自分へ能力攻撃ダメージ　※防御無視】',
            '消費負荷【ＰＰ２倍消費　※ＡＥ消費は含まない】',
            '消費負荷【ＰＰ２倍消費　※ＡＥ消費は含まない】',
            '反動',
            '反動',
            '制御成功【発動成功　ペナルティ無し】'
          ],
          additonal_type: "1D6",
          additonal_format: "【命中＆回避－１Ｄ６（%{total}[%{list}]）　１ラウンド継続】",
          additonal_index: [4, 5]
        ),
        "SO3" => YggTable.new(
          "SOペナルティ表 3オーバー",
          "1D6",
          [
            '自爆【自分へ能力攻撃ダメージ　※防御無視】',
            '自爆【自分へ能力攻撃ダメージ　※防御無視】',
            '消費負荷【ＰＰ２倍消費　※ＡＥ消費は含まない】',
            '過反動',
            '過反動',
            '制御成功【発動成功　ペナルティ無し】'
          ],
          additonal_type: "2D6",
          additonal_format: "【命中＆回避－２Ｄ６（%{total}[%{list}]）　１ラウンド継続】",
          additonal_index: [4, 5]
        ),
        "SO4" => YggTable.new(
          "SOペナルティ表 4オーバー",
          "1D6",
          [
            '崩壊【自爆ダメージ×２　※防御無視】',
            '崩壊【自爆ダメージ×２　※防御無視】',
            '超負荷【ＰＰ３倍消費　※ＡＥ消費は含まない】',
            '過反動',
            '過反動',
            '制御成功【発動成功　ペナルティ無し】',
          ],
          additonal_type: "2D6",
          additonal_format: "【命中＆回避－２Ｄ６（%{total}[%{list}]）　１ラウンド継続】",
          additonal_index: [4, 5]
        ),
        "SO5" => DiceTable::Table.new(
          "SOペナルティ表 5オーバー",
          "1D6",
          [
            '崩壊【自爆ダメージ×２　※防御無視】',
            '崩壊【自爆ダメージ×２　※防御無視】',
            '崩壊【自爆ダメージ×２　※防御無視】',
            '超負荷【ＰＰ３倍消費　※ＡＥ消費は含まない】',
            '超負荷【ＰＰ３倍消費　※ＡＥ消費は含まない】',
            '制御成功【発動成功　ペナルティ無し】'
          ]
        ),
        "RISK" => DiceTable::Table.new(
          "リスク判定",
          "1D6",
          [
            '能力自爆【能力は発動せず、ＰＰを２倍消費する。併用ＡＥのＰＰは含まない。それに加え【自爆】する。能力攻撃力分を自身へ防御無視ダメージ】',
            '能力不発【能力は発動せず、ＰＰを２倍消費する。併用ＡＥのＰＰは含まない】',
            '効果不発【リスクの効果はゼロで能力発動】',
            '通常発動【（能力精度÷３）＋１Ｄ６を加える】',
            '活性発動【（能力精度÷３）＋２Ｄ６を加える】',
            '覚醒発動【（能力精度÷３）＋３Ｄ６を加える】'
          ]
        ),
        "FATAL1" => DiceTable::Table.new(
          "後遺症判定",
          "1D6",
          [
            '聴覚崩壊【聴覚に異常が起きる。幻聴、難聴、失聴、など】',
            '視覚崩壊【視覚に異常が起こる。幻覚、色盲、失明、など】',
            '言語崩壊【言語の認識に異常が起きる。しゃべる事に支障をきたす。吃音、失語症、失読症、など】',
            '身体崩壊【身体に異常が起こる。欠損、異形化、麻痺、など】',
            '精神崩壊【精神に異常が起こる。人格破綻、性格変化、妄想・幻覚による異常行動、など】',
            '記憶崩壊【記憶に異常が起こる。記憶障害、記憶喪失、など】'
          ]
        ),
        "FATAL2" => DiceTable::ChainTable.new(
          "因子変化判定",
          "1D6",
          [
            DiceTable::ChainWithText.new('能力変化【能力がまったく別ものに変化する】', PSY_TABLE),
            DiceTable::ChainWithText.new('能力変化【能力がまったく別ものに変化する】', PSY_TABLE),
            '因子抑制【能力変化は起こらない】',
            '因子抑制【能力変化は起こらない】',
            DiceTable::ChainWithText.new('能力喪失・能力覚醒【能力を持つものは失い、ノーマルは能力に覚醒する。喪失者はノーマルのキャラ特性ポイントを1p獲得する。覚醒者はノーマルのキャラ特性ポイントを1p失い、キャラ特性を6つ取得していた場合は1つ喪失する】', PSY_TABLE),
            DiceTable::ChainWithText.new('能力喪失・能力覚醒【能力を持つものは失い、ノーマルは能力に覚醒する。喪失者はノーマルのキャラ特性ポイントを1p獲得する。覚醒者はノーマルのキャラ特性ポイントを1p失い、キャラ特性を6つ取得していた場合は1つ喪失する】', PSY_TABLE),
          ]
        ),
        "STAG" => DiceTable::D66Table.new(
          "ステージ決定",
          D66SortType::NO_SORT,
          {
            11 => 'ロシアンルーレット【幸運にて判定。参加者は銃をこめかみにあて、１発の銃弾をひかないように祈る。 敗者は３Ｄ６ダメージ】',
            12 => 'チキンレース【察知にて判定。に向ってバイクでダッシュだ。敗者は２Ｄ６ダメージ。落ちても大丈夫です、電脳だから】',
            13 => '取り立て【力技or威圧にて判定。あのモヒカン借金払わないんですよ。よろしくお願いしますね。電脳を通しての実際の取り立てらしい】',
            14 => '舌戦【威圧or話術にて判定。参加者同士で舌戦で勝者を決めろ！敗者は心に２Ｄ６ダメージ】',
            15 => 'ギャンブル【読心or幸運にて判定。ポーカー、ルーレット、麻雀、好きなものを選べ。勝利の鍵は運か、それとも人の心か】',
            16 => 'トラップ【ＳＳにて判定。君達の目の前に広がるのはそう、地雷原だ。敗者は３Ｄ６ダメージ】',

            21 => 'サバゲー【隠密or俊敏にて判定。軍人となって、相手を屠れ！敗者は死ぬ。敗者は２Ｄ６ダメージ】',
            22 => '追跡【察知or隠密にて判定。ニンジャの姿となって下手人を追え！コアな人気を誇るステージ。ニンジャ人気すごい】',
            23 => '推理【閃きにて判定。あなたたちは探偵となり、事件を解決に導く。犯人は、お前だ！２時間放送になるのが玉に瑕】',
            24 => '潜入【隠密にて判定。スパイとなり、機密情報を盗め！あれ、これ実際の企業の機密情報じゃ・・・？】',
            25 => 'かくれんぼ【隠密or読心にて判定。あなたを追うのはホラーな化け物・・・。スリリングなかくれんぼをどうぞ堪能下さい】',
            26 => '絶対絶命！【回避力にて判定。君達はマフィアにおびき出されたのだ。大勢の銃が君を狙う。敗者は３Ｄ６ダメージ】',

            31 => 'クイズ【知識にて判定。己の知識を存分に披露しろ！負けたら奈落に落されます。敗者は１Ｄ６ダメージ】',
            32 => '迷路【察知or幸運にて判定。巨大迷路をクリアしろ！あれ、なんでこんなところに骸骨が・・・】',
            33 => 'パズル【知識or閃きにて判定。３Ｄの難解パズルを解き明かせ！！時折金庫破りのパスワードがターゲットになってたり】',
            34 => '間違い探し【観察眼or閃きにて判定。大量の鍵から正しい鍵を。美女の中からオカマを。そんな間違いを見つけるのだ！】',
            35 => '目利き【観察眼or知識にて判定。あなたの鑑定で値段を当てろ！はずれたらかっこ悪いです】',
            36 => 'スナイパー【命中力にて判定。一撃必殺でターゲットを仕留めろ！なお、ターゲットはお互いだ。敗者は２Ｄ６ダメージ】',

            41 => '腕相撲【力技にて判定。必要なのは、力のみ！！敗者は２Ｄ６ダメージ】',
            42 => 'インディジョーンズ【俊敏にて判定。なぜか大岩が後ろから！逃げろー！敗者は３Ｄ６ダメージ】',
            43 => 'ＰＫ【力技or察知にて判定。見極め、ゴールしろ！パワーで破ってもいい】',
            44 => 'ダンス【技術or俊敏にて判定。己の舞を魅せろ！ジャンル問わず】',
            45 => 'ボディコンテスト【威圧にて判定。魅せるのはマッスルか、それとも美しい肢体か！容姿ボーナスはつきません】',
            46 => '突破しろ！【ダメージ量にて判定。立ちはだかる扉をぶち破れ！扉は防御１０】',

            51 => '早食い【力技or俊敏にて判定。くって！くって！！くいまくれ！！敗者は胃に２Ｄ６ダメージ】',
            52 => 'ナンパ天国【話術or読心にて判定。電脳世界で老若男女を口説き落せ！相手はプログラムだったり電脳に入っているアバターだったり】',
            53 => 'スリーサイズ【観察眼にて判定。魅惑のボディをなめまわせ！勝利者はある意味で尊敬され、ある意味で嫌われる】',
            54 => 'ワサビ寿司【観察眼or幸運にて判定。高級寿司の中に、死ぬほどの刺激が・・・！敗者は２Ｄ６ダメージ】',
            55 => 'じゃんけん【読心にて判定。じゃんけんとは運ではない、読み合いなのだ！】',
            56 => '瓦割り【ダメージ量にて判定。どんな方法でもいい。とにかく枚数を割れ！！！ダメージ量の２倍くらいが割った枚数】',

            61 => '料理対決【知識or技術にて判定。胃袋をつかめ！絶品料理対決！料理によってはＲ１８Ｇ指定になる場合がある】',
            62 => '歌合戦【威圧or技術にて判定。その歌唱力で心をつかめ！アイドルデビューも夢じゃない！電脳なのでお好きな衣装でどうぞ】',
            63 => '漫才【話術or閃きにて判定。即興漫才で画面の向こうを爆笑の渦へ！相方が必要な方は漫才プログラムアバターをレンタル。有料】',
            64 => '画伯【技術にて判定。テーマをもとに、あなたの画力を見せつけろ！時々下手うまな人が勝つことも】',
            65 => 'プレゼンテーション【話術にて判定。本日の商品は、こちら！！実際に販売します。してもらいます】',
            66 => '無双撃破！【ダメージ量にて判定。た、大量のモヒカンだぁ～！ダメージ量の２倍くらいが倒した数。敗者は２Ｄ６ダメージ。ＳＥ【オールレンジ】技は成功で判定＋１０】'
          }
        )
      }.freeze
    end
  end
end
