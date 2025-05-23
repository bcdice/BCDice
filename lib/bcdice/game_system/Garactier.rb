# frozen_string_literal: true

module BCDice
  module GameSystem
    class Garactier < Base
      # ゲームシステムの識別子
      ID = "Garactier"

      # ゲームシステム名
      NAME = "ガラクティア"

      # ゲームシステム名の読みがな
      SORT_KEY = "からくていあ"

      HELP_MESSAGE = <<~TEXT
        ガラクティアVer1.04
        x:基準値
        y:目標値
        x, yについては四則演算の入力が可能

        ■達成値の算出(GRx)
          クリティカル・ファンブルの判定、達成値の表示を行う。
        ■通常判定(GRx>=y)
          通常の判定を行う。
        ■命中判定(GRHx>=y)
          命中判定を行う。
        ■回避判定(GRDx>=y)
          回避判定を行う。
        ■抵抗判定(GRMx>=y)
          抵抗判定を行う。
        ■探索成功マスレベル算出(GRSx)
          探索・索敵判定時の最大成功マスレベル(ML)を算出する
        ■ 表
          アイテム決定表(ITMn)
            ランクnのアイテム表を振る。例)ITM2 ランク２アイテム表
            上級アイテムの判定も行います。
          命中部位決定表(BUI)
            命中時の部位を決定します。
          増強可能施設決定表(SST)
            報告フェイズの増強可能施設を決定します。
      TEXT

      #  アイテム用テーブル
      ITEM_TABLES = {
        'ITM2' => DiceTable::D66Table.new(
          'ランク２アイテム決定表',
          D66SortType::NO_SORT,
          {
            11 => 'リペアスプレー',
            12 => '防壁シャボン',
            13 => '応援ボットちゃん',
            14 => '偵察ボットちゃん',
            15 => '回収ボットちゃん',
            16 => 'ブラストチャージャー',
            21 => '仕掛け爆弾',
            22 => 'おなじみドリル',
            23 => '清掃ボットちゃん',
            24 => '突撃ボットちゃん',
            25 => '修繕ボットちゃん',
            26 => 'アンプリファイア',
            31 => 'コバルトエール',
            32 => 'カステラ',
            33 => 'エアガン',
            34 => '安全靴',
            35 => 'ヘルメット',
            36 => 'フラッシュバルブ',
            41 => 'クリアワックス',
            42 => '目薬',
            43 => 'ラプチャーヒール',
            44 => '防弾盾',
            45 => 'プレートアーマー',
            46 => 'ホーリーチャーム',
            51 => 'カーネルシガー',
            52 => 'ニトロギャンディー',
            53 => '鉱樹の花飾り',
            54 => 'アンプルシューター',
            55 => 'メタル包帯',
            56 => '炸裂発煙筒',
            61 => 'シグナルドラッグ',
            62 => '毒手',
            63 => 'グルーガン',
            64 => '縫い針',
            65 => 'パイロン',
            66 => '☆上級品☆',
          }
        ),
        'ITM3' => DiceTable::D66Table.new(
          'ランク３アイテム決定表',
          D66SortType::NO_SORT,
          {
            11 => 'バナナ',
            12 => 'イージーバズーカ',
            13 => 'マルチバーニア',
            14 => '赤い鉢巻き',
            15 => 'カクテルポイズン',
            16 => 'リペアジェル',
            21 => '金砕棒',
            22 => 'オシャレステッキ',
            23 => '掃除機',
            24 => 'ソーラーキャップ',
            25 => 'タクティカルベスト',
            26 => 'ホイッスル',
            31 => 'パノラマバイザー',
            32 => 'フリーズランチャー',
            33 => 'オシャレスーツ',
            34 => '暗器',
            35 => '無限軌道',
            36 => 'イルミネーション',
            41 => '光線銃',
            42 => '十手',
            43 => '銅鑼',
            44 => 'オシャレハット',
            45 => '忍び足',
            46 => '釣り竿',
            51 => 'ブラックパウダー',
            52 => 'ダーティーマント',
            53 => 'バッテリーケイン',
            54 => 'バンデッドショルダー',
            55 => 'オシャレシューズ',
            56 => 'サテライト',
            61 => 'キーパーゴーレム',
            62 => '混迷香',
            63 => '応援旗',
            64 => '黒子頭巾',
            65 => 'バーナーランス',
            66 => '☆上級品☆',
          }
        ),
        'ITM4' => DiceTable::D66Table.new(
          'ランク４アイテム決定表',
          D66SortType::NO_SORT,
          {
            11 => '金塊',
            12 => 'パラボラアンテナ',
            13 => 'くらましの敷布',
            14 => '無影灯',
            15 => '油圧ショベル',
            16 => 'マシンテール',
            21 => '黒曜石の像',
            22 => '黄金のクローバー',
            23 => '朝霧の箒',
            24 => 'ヘッドキャノン',
            25 => 'レッグバルカン',
            26 => 'ダイナモブロック',
            31 => 'ジョウロ',
            32 => 'スナイパーライフル',
            33 => 'おてがるスコープ',
            34 => 'ドーザーブレード',
            35 => 'テツゲタ',
            36 => 'ジェットスラスター',
            41 => '宝剣',
            42 => '指揮棒',
            43 => '大兜',
            44 => '妖精さん',
            45 => 'ロングホーン',
            46 => '鎖がま',
            51 => '鳥籠',
            52 => 'カタパルトアーム',
            53 => 'スタンドマイク',
            54 => '臆病なカカシ',
            55 => 'ローラーダッシュ',
            56 => 'モミジ',
            61 => 'マスターキー',
            62 => '隠れ蓑',
            63 => '番傘',
            64 => '駆動甲冑',
            65 => '波紋の杖',
            66 => '☆上級品☆',
          }
        ),
        'ITM5' => DiceTable::D66Table.new(
          'ランク５アイテム決定表',
          D66SortType::NO_SORT,
          {
            11 => '因果の卵',
            12 => 'ランプ',
            13 => '常盤の琥珀',
            14 => '新緑の冠',
            15 => '萌芽の靴',
            16 => '星の骸',
            21 => '夜の帳',
            22 => 'スリップブローチ',
            23 => '拳法着',
            24 => 'めがね',
            25 => '白旗',
            26 => 'ディラックナイフ',
            31 => 'エレキドレッサー',
            32 => 'ネイルガン',
            33 => '木漏れ日のポプリ',
            34 => 'ミスリルピッケル',
            35 => 'デスマッチカフス',
            36 => 'アダムスキースカート',
            41 => '主砲',
            42 => 'マイクロポッド',
            43 => '樹皮の円盤',
            44 => 'リンゴと蛇の紋章',
            45 => 'セントリーガンナー',
            46 => '化生の仮面',
            51 => 'ガトリング',
            52 => 'オカモチ',
            53 => '芭蕉扇',
            54 => 'ハッピートリガー',
            55 => '蠢く湿布',
            56 => 'メガホン',
            61 => 'トランシーバー',
            62 => '好奇の鋲',
            63 => 'スレッジハンマー',
            64 => 'セントール',
            65 => 'ケーブルナイト',
            66 => '☆上級品☆',
          }
        ),
        'ITM6' => DiceTable::D66Table.new(
          'ランク６アイテム決定表',
          D66SortType::NO_SORT,
          {
            11 => '禍福の勾玉',
            12 => '祭壇',
            13 => 'ネジまき心臓',
            14 => 'まどろみの頭蓋',
            15 => '猛進拍車',
            16 => '炉心結晶',
            21 => '狂奔の鞭',
            22 => '暁のベル',
            23 => 'ネコシッポ',
            24 => '鬼蜘蛛',
            25 => '戦上手の脚',
            26 => '薄絹の外套',
            31 => 'ネコクロー',
            32 => 'クライムチャンバー',
            33 => '古の灯火',
            34 => 'かしこい触手',
            35 => 'オペラグラス',
            36 => '大鉄拳',
            41 => '妖刀',
            42 => 'ヘビーライター',
            43 => '緋緋色の針',
            44 => 'バーサクシール',
            45 => '光芒のアンクレット',
            46 => 'ネコブーツ',
            51 => '旅するコイン',
            52 => '光子鏡壁',
            53 => 'フェザージャケット',
            54 => 'レーザーミニオン',
            55 => 'マニピュレーター',
            56 => 'ランパートシールド',
            61 => '選定者の瞳',
            62 => '打ち上げ花火',
            63 => '魔笛',
            64 => '指輪',
            65 => 'ネコミミ',
            66 => '☆上級品☆',
          }
        ),
      }.freeze()

      # 施設表
      SISETSU_TABLES = {
        "SST" => DiceTable::Table.new(
          "増強可能施設決定表",
          "1D6",
          [
            '広場　マーケット　楽団',
            '広場　ガレージ　鉄工所',
            '広場　訓練場　農園　保健所',
            '広場　学舎　骨董屋',
            '広場　塗装工　菓子屋　貯蔵庫',
            '広場　診療所　礼拝堂',
          ]
        ),
      }.freeze

      # 部位表
      BUI_TABLES = {
        "BUI" => DiceTable::Table.new(
          "命中部位決定表",
          "1D6",
          [
            '頭部',
            '胴体',
            '右腕',
            '左腕',
            '脚部',
            '任意部位',
          ]
        ),
      }.freeze

      register_prefix('^GR[HDMS]?', 'ITM[2-6]', 'BUI', 'SST')

      def eval_game_system_specific_command(command)
        cmd_gr(command) ||
          roll_item(command) ||
          roll_tables(command, BUI_TABLES) ||
          roll_tables(command, SISETSU_TABLES)
      end

      # GR系コマンドの分割
      def cmd_gr(command)
        case command
        when /^GRS/
          roll_search(command)
        when /^GR[HDM]/
          roll_target(command)
        when /^GR/
          roll_gr(command)
        end
      end

      # 探索・索敵判定
      def roll_search(command)
        m = %r{^GRS([+-/*\d]+)?$}.match(command)
        unless m
          return nil
        end

        modifier = Arithmetic.eval(m[1] || "", RoundType::FLOOR) || 0

        dice_result = roll_dice_with_modifier(modifier)
        r = determine_no_target_result("S", dice_result[:total], dice_result[:critical], dice_result[:fumble])

        r.text = "(#{m[0]}) ＞ #{dice_result[:dice_sum]}[#{dice_result[:dice_list].join(',')}]#{m[1]} ＞ #{dice_result[:total]} ＞ #{r.text}"
        return r
      end

      # 目標値を持つ判定ロール
      def roll_target(command)
        m = %r{^GR([HDM])([+-/*\d]+)?(?:>=?([+-/*\d]+)+)$}.match(command)
        unless m
          return nil
        end

        roll_type = m[1].to_str
        modifier = Arithmetic.eval(m[2] || "", RoundType::FLOOR) || 0
        target = Arithmetic.eval(m[3] || "", RoundType::FLOOR) || 0

        dice_result = roll_dice_with_modifier(modifier)
        r = determine_target_result(roll_type, dice_result[:total], target, dice_result[:critical], dice_result[:fumble])

        r.text = "(#{m[0]}) ＞ #{dice_result[:dice_sum]}[#{dice_result[:dice_list].join(',')}]#{m[2]} ＞ #{dice_result[:total]} ＞ #{r.text}"
        return r
      end

      # GRのみの基本判定
      def roll_gr(command)
        m = %r{^GR([+-/*\d]+)?(>=)?\(?([+-/*\d]+)?\)?$}.match(command)
        unless m
          return nil
        end

        modifier = Arithmetic.eval(m[1] || "", RoundType::FLOOR) || 0

        target_flag = !m[2].nil?
        dice_result = roll_dice_with_modifier(modifier)

        if target_flag
          target = Arithmetic.eval(m[3] || "", RoundType::FLOOR) || 0
          r = determine_target_result("", dice_result[:total], target, dice_result[:critical], dice_result[:fumble])
        else
          r = determine_no_target_result("", dice_result[:total], dice_result[:critical], dice_result[:fumble])
        end
        r.text = "(#{m[0]}) ＞ #{dice_result[:dice_sum]}[#{dice_result[:dice_list].join(',')}]#{m[1]} ＞ #{dice_result[:total]} ＞ #{r.text}"
        return r
      end

      # 基準値(modifier)をもとに2d6+基準値の判定を行う
      def roll_dice_with_modifier(modifier)
        dice_list = randomizer.roll_barabara(2, 6)
        dice_sum = dice_list.sum
        total = dice_sum + modifier
        critical_flag = dice_list.count(6) == 2
        fumble_flag = dice_list.count(1) == 2
        return {dice_list: dice_list, dice_sum: dice_sum, total: total, critical: critical_flag, fumble: fumble_flag}
      end

      # roll_typeごとにResultを作成（目標値あり）
      def determine_target_result(roll_type, total, target, critical, fumble)
        case roll_type
        when "H"
          if critical
            Result.critical("クリティカル命中")
          elsif fumble
            Result.fumble("ファンブル")
          elsif total >= target + 4
            Result.success("急所命中")
          elsif total >= target
            Result.success("命中")
          else
            Result.failure("失敗")
          end
        when "D"
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          elsif total >= target
            Result.success("回避成功")
          elsif total >= target - 4
            Result.failure("半減命中")
          else
            Result.failure("失敗")
          end
        when "M"
          # 抵抗判定は基準値以上(激情)のほうが悪い効果のことが多いためResultを反転[6,6]の場合にファンブル
          if critical
            Result.fumble("必ず激情")
          elsif fumble
            Result.critical("必ず平静")
          elsif total >= target
            Result.failure("激情")
          else
            Result.success("平静")
          end
        else
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          elsif total >= target
            Result.success("成功")
          else
            Result.failure("失敗")
          end
        end
      end

      # roll_typeごとにResultを作成（目標値なし）
      def determine_no_target_result(roll_type, total, critical, fumble)
        case roll_type
        when "S"
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          else
            success_level = (total - 4) / 2
            if success_level >= 11
              success_level = 11
            elsif success_level <= 0
              success_level = 1
            end
            r = Result.new
            r.text = "成功ML #{success_level}"
            return r
          end
        else
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          else
            r = Result.new
            r.text = "達成値 #{total}"
            return r
          end
        end
      end

      ## アイテム表ロール ランク
      def roll_item(command)
        unless command.include?("ITM")
          return nil
        end

        # 1回目のアイテムロール
        result = roll_tables(command, ITEM_TABLES)
        # 上級判定
        if result.include?("(66)")
          result = roll_tables(command, ITEM_TABLES) + "*上級アイテム*"
        end
        # 選択判定
        if result.include?("(66)")
          result = "上級アイテムを自由選択！！"
        end
        return result
      end
    end
  end
end
