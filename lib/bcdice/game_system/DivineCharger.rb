# frozen_string_literal: true

module BCDice
  module GameSystem
    class DivineCharger < Base
      # ゲームシステムの識別子
      ID = 'DivineCharger'

      # ゲームシステム名
      NAME = '神聖課金RPGディヴァインチャージャー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しんせいかきんRPGていうあいんちやあしやあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　　nD6>=t          n:能力値 t:目標値
        　もしくはnD>=t
        例)3D6>=7: ダイスを3個振って、目標値7で判定。その結果(達成値,成功・失敗,クリティカル,ファンブル)を表示
        　 3D6>=?: 　同上　目標値が不明なので、達成値,クリティカル,ファンブルのみ表示。

        ■反転判定　　REV[n]>=t   n:ダイス目(カンマなし) t:目標値
        例)REV[123]>=7: 振ったダイスが[1,2,3]で、目標値7で反転判定。その結果(達成値,成功・失敗,クリティカル,ファンブル)を表示


        ■ランダムイベント　　RET
        ■神器　　　　　　　　aksT a:表(AかB) k:種別(K:近接, S:射撃, M:魔法, Y:鎧, T:盾, A:装飾品) s:ランク(1～5)
      INFO_MESSAGETEXT

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) ||
          resolute_reverse(command) ||
          roll_tables(command, TABLES)
      end

      private

      # 通常判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /^(\d+)D(6)?>=(\d+|[?])$/.match(command)
        return nil unless m

        num_dice = m[1].to_i
        target = m[3]

        dice = @randomizer.roll_barabara(num_dice, 6).sort
        dice_text = dice.join(",")
        output = "(#{num_dice}D6>=#{target}) ＞ #{dice_text}"
        action = Action_data.new(output, dice, target)

        return action_result(action)
      end

      Action_data = Struct.new(:text, :dice, :target)
      def action_result(action)
        output = action.text
        dice = action.dice
        target = action.target

        count6 = dice.count(6)
        count1 = dice.count(1)
        success_num = dice.sum()
        if count6 >= 2
          output += " ＞ 達成値#{success_num}"
          output += " ＞ クリティカル"
          return Result.critical(output)
        elsif count1 >= 2
          output += " ＞ 達成値0"
          output += " ＞ ファンブル([神聖石]5個)"
          return Result.fumble(output)
        end

        output += " ＞ 達成値#{success_num}"

        if target == "?"
          return Result.new(output)
        else
          if success_num >= target.to_i
            output += " ＞ 成功"
            return Result.success(output)
          else
            output += " ＞ 失敗"
            return Result.failure(output)
          end
        end
      end

      # 反転判定
      # @param [String] command
      # @return [Result]
      def resolute_reverse(command)
        m = /^REV\[([\d,]+)\]>=(\d+|[?])$/.match(command)
        return nil unless m

        raw_dice = m[1]
        target = m[2]
        raw_dice = raw_dice.delete(',')

        dice = reverse_dice(raw_dice.split(''))
        dice_text = dice.join(",")
        output = "(REV[#{raw_dice}]>=#{target}) ＞ #{dice_text}"
        action = Action_data.new(output, dice, target)

        return action_result(action)
      end

      def reverse_dice(array_dice)
        reverse_array_dice = []
        array_dice.each do |val|
          reverse_array_dice.push(6) if val == '1'
          reverse_array_dice.push(5) if val == '2'
          reverse_array_dice.push(4) if val == '3'
          reverse_array_dice.push(3) if val == '4'
          reverse_array_dice.push(2) if val == '5'
          reverse_array_dice.push(1) if val == '6'
        end
        return reverse_array_dice.sort
      end

      TABLES = {
        "RET" => DiceTable::D66Table.new(
          "ランダムイベント",
          D66SortType::NO_SORT,
          {
            11 => '[描写]:辺りには何もなく、がらんとした部屋だ。近くに宝箱がある。[予測]:こういう場所では運動神経を試される罠が仕掛けてあることが多い。宝箱の中には、当然ながら金目のものが眠っているはずだ。[探索時間:4]',
            12 => '[描写]:辺りには何もなく、がらんとした部屋だ。近くに宝箱がある。[予測]:こういう場所では運動神経を試される罠が仕掛けてあることが多い。宝箱の中には、当然ながら金目のものが眠っているはずだ。[探索時間:4]',
            13 => '[描写]:辺りには何もなく、がらんとした部屋だ。向こう側に宝箱がある。[予測]:悪い予感がする。妙なトラップに遭遇するかもしれない。心の準備をしておいた方がいいだろう。宝箱には何かアイテムがあるような気がする。[探索時間:4]',
            14 => '[描写]:辺りには何もなく、がらんとした部屋だ。向こう側に宝箱がある。[予測]:悪い予感がする。妙なトラップに遭遇するかもしれない。心の準備をしておいた方がいいだろう。宝箱には何かアイテムがあるような気がする。[探索時間:4]',
            15 => '[描写]:辺りには何もなく、がらんとした部屋だ。中央に宝箱がある。[予測]:一見何もないように見える場所こそ注意が必要だ。いつでも立ち回れるようにした方がいいだろう。宝箱の中から光がにじみ出している。まさか〈神聖石〉が入っているのでは。[探索時間:4]',
            16 => '[描写]:辺りには何もなく、がらんとした部屋だ。中央に宝箱がある。[予測]:一見何もないように見える場所こそ注意が必要だ。いつでも立ち回れるようにした方がいいだろう。宝箱の中から光がにじみ出している。まさか〈神聖石〉が入っているのでは。[探索時間:4]',
            21 => '[描写]:石の壁で覆われた部屋だ。壁には幾何学的な模様が彫ってある。天井も無数の石のブロックで形成されている。[予測]:天井が崩れそうな予感がする。素早く探索しないと怪我しそうだ。ここには〈神聖石〉がある気がする。[探索時間:5]',
            22 => '[描写]:石の壁で覆われた部屋だ。壁には幾何学的な模様が彫ってある。天井も無数の石のブロックで形成されている。[予測]:天井が崩れそうな予感がする。素早く探索しないと怪我しそうだ。ここには〈神聖石〉がある気がする。[探索時間:5]',
            23 => '[描写]:石の壁で覆われた部屋だ。壁には様々なe壁画が彫ってある。[予測]:何か違和感がある。己の感覚を研ぎ澄まし注意した方がいいだろう。部屋の中央には宝箱が置いてある。[探索時間:5]',
            24 => '[描写]:石の壁で覆われた部屋だ。壁には様々なe壁画が彫ってある。[予測]:何か違和感がある。己の感覚を研ぎ澄まし注意した方がいいだろう。部屋の中央には宝箱が置いてある。[探索時間:5]',
            25 => '[描写]:石の壁で覆われた部屋だ。壁は光苔に覆われて輝いている。探せば何かあるかもしれない。[予測]:何か違和感を覚える。この違和感を押さえ込まないと、今後の行動に支障が出てきそうだ。部屋の端には薬棚があり、魔法薬が置いてある。[探索時間:5]',
            26 => '[描写]:石の壁で覆われた部屋だ。壁は光苔に覆われて輝いている。探せば何かあるかもしれない。[予測]:何か違和感を覚える。この違和感を押さえ込まないと、今後の行動に支障が出てきそうだ。部屋の端には薬棚があり、魔法薬が置いてある。[探索時間:5]',
            31 => '[描写]:小さな部屋だ。雑多に物がちらかっている。ガラクタから、何かを見つけることができるかもしれない。[予測]:こういうところでこそ、油断してはいけない。隙を突くようなトラップが仕掛けている場合がある。俊敏に動こう。ガラクタの中には、魔法薬の瓶がある。[探索時間:4]',
            32 => '[描写]:小さな部屋だ。雑多に物がちらかっている。ガラクタから、何かを見つけることができるかもしれない。[予測]:こういうところでこそ、油断してはいけない。隙を突くようなトラップが仕掛けている場合がある。俊敏に動こう。ガラクタの中には、魔法薬の瓶がある。[探索時間:4]',
            33 => '[描写]:小さな部屋だ。雑多に物がちらかっている。ガラクタの中から、何かいいものが落ちているかもしれない。[予測]:こういう場所には大体トラップが置いてあるはずだが、今のところその気配はない。感覚を研ぎ澄ませて慎重に行こう。隅に光る石がある。〈神聖石〉だろうか。[探索時間:3]',
            34 => '[描写]:小さな部屋だ。雑多に物がちらかっている。ガラクタの中から、何かいいものが落ちているかもしれない。[予測]:こういう場所には大体トラップが置いてあるはずだが、今のところその気配はない。感覚を研ぎ澄ませて慎重に行こう。隅に光る石がある。〈神聖石〉だろうか。[探索時間:3]',
            35 => '[描写]:小さな部屋だ。雑多に物がちらかっている。隅には宝箱が見える。[予測]:何やらすえた匂いがする。酸を使ったトラップがあるかもしれない。機敏に動こう。宝箱には金目の物があるだろう。[探索時間:3]',
            36 => '[描写]:小さな部屋だ。雑多に物がちらかっている。隅には宝箱が見える。[予測]:何やらすえた匂いがする。酸を使ったトラップがあるかもしれない。機敏に動こう。宝箱には金目の物があるだろう。[探索時間:3]',
            41 => '[描写]:光が差し込みにくい、薄暗い部屋だ。伸ばした自分の手の先もよく見えない。[予測]:このような場所ではうかつに動くと怪我をしてしまう。感覚を研ぎ澄まして動いた方がいいだろう。ここには〈神聖石〉がある気がする。[探索時間:4]',
            42 => '[描写]:光が差し込みにくい、薄暗い部屋だ。伸ばした自分の手の先もよく見えない。[予測]:このような場所ではうかつに動くと怪我をしてしまう。感覚を研ぎ澄まして動いた方がいいだろう。ここには〈神聖石〉がある気がする。[探索時間:4]',
            43 => '[描写]:光が差し込みにくい暗い部屋だ。探索には骨が折れるかもしれない。[予測]:このような場所では何が起きるかわからない。何が起きても動じない心構えが必要だ。身につけてるものもちゃんと管理しておこう。ここには宝がある気がする。[探索時間:4]',
            44 => '[描写]:光が差し込みにくい暗い部屋だ。探索には骨が折れるかもしれない。[予測]:このような場所では何が起きるかわからない。何が起きても動じない心構えが必要だ。身につけてるものもちゃんと管理しておこう。ここには宝がある気がする。[探索時間:4]',
            45 => '[描写]:光が差し込みにくい薄暗い部屋だ。何やら生き物の気配も感じる。[予測]:どんな生物がいるのか、探っておく必要があるだろう。対処方法につながる。ここには霊薬が置いてある気がする。[探索時間:4]',
            46 => '[描写]:光が差し込みにくい薄暗い部屋だ。何やら生き物の気配も感じる。[予測]:どんな生物がいるのか、探っておく必要があるだろう。対処方法につながる。ここには霊薬が置いてある気がする。[探索時間:4]',
            51 => '[描写]:床や天井におどろおどろしい魔法陣が描かれている部屋だ。四方の壁には棚が置かれている。何か見つかればいいのだが。[予測]:魔法陣は明らかに怪しい。いつでも対応できるよう感覚を研ぎ澄ませ、装備にも気を配っておこう。棚には魔法の薬が置いてあるようだ。[探索時間:4]',
            52 => '[描写]:床や天井におどろおどろしい魔法陣が描かれている部屋だ。四方の壁には棚が置かれている。何か見つかればいいのだが。[予測]:魔法陣は明らかに怪しい。いつでも対応できるよう感覚を研ぎ澄ませ、装備にも気を配っておこう。棚には魔法の薬が置いてあるようだ。[探索時間:4]',
            53 => '[描写]:床や天井におどろおどろしい魔法陣が描かれている部屋だ。探索すれば何かあるかもしれない。[予測]:魔法陣は明らかに怪しい。これに罠があるとするなら、知性を試されるようなものに違いない。注意しておこう。この部屋には〈神聖石〉がある気がする。[探索時間:4]',
            54 => '[描写]:床や天井におどろおどろしい魔法陣が描かれている部屋だ。探索すれば何かあるかもしれない。[予測]:魔法陣は明らかに怪しい。これに罠があるとするなら、知性を試されるようなものに違いない。注意しておこう。この部屋には〈神聖石〉がある気がする。[探索時間:4]',
            55 => '[描写]:床や天井におどろおどろしい魔法陣が描かれている部屋だ。探索すれば何かあるかもしれない。[予測]:この魔法陣が罠であるのは間違いない。いつでも対応できるように俊敏に行動しよう。部屋の隅には宝箱があり、金目の物が入ってそうだ。[探索時間:4]',
            56 => '[描写]:床や天井におどろおどろしい魔法陣が描かれている部屋だ。探索すれば何かあるかもしれない。[予測]:この魔法陣が罠であるのは間違いない。いつでも対応できるように俊敏に行動しよう。部屋の隅には宝箱があり、金目の物が入ってそうだ。[探索時間:4]',
            61 => '[描写]:静謐な部屋だ。中央には泉があり、清らかな空気を放っている。泉のそばにはキノコが生えている。慎重に食べた方がいいだろう。[予測]:キノコは魔法のキノコで、何かしらの効果が期待されるが、キノコの魔法成分を受け止める精神力が必要だ。また、泉の中には金貨が見える。[探索時間:3]',
            62 => '[描写]:静謐な部屋だ。中央には泉があり、清らかな空気を放っている。泉のそばにはキノコが生えている。慎重に食べた方がいいだろう。[予測]:キノコは魔法のキノコで、何かしらの効果が期待されるが、キノコの魔法成分を受け止める精神力が必要だ。また、泉の中には金貨が見える。[探索時間:3]',
            63 => '[描写]:神聖な雰囲気の漂う部屋だ。中央には泉があり、清らかな空気を放っている。とりあえず飲んでみるべきだろう。[予測]:泉の水には何らかの効果が期待できそうだが、もしもの時のために体力があった方がいいだろう。また、泉の中には〈神聖石〉が見える。[探索時間:3]',
            64 => '[描写]:神聖な雰囲気の漂う部屋だ。中央には泉があり、清らかな空気を放っている。とりあえず飲んでみるべきだろう。[予測]:泉の水には何らかの効果が期待できそうだが、もしもの時のために体力があった方がいいだろう。また、泉の中には〈神聖石〉が見える。[探索時間:3]',
            65 => '[描写]:静謐な部屋だ。中央には泉があり、清らかな空気を放っている。泉の中には何かあるかも知れない。[予測]:泉の中には何かが潜んでいるかもしれない。俊敏に対応できるように注意するべきだろう。また、泉の中には薬瓶が見える。[探索時間:3]',
            66 => '[描写]:静謐な部屋だ。中央には泉があり、清らかな空気を放っている。泉の中には何かあるかも知れない。[予測]:泉の中には何かが潜んでいるかもしれない。俊敏に対応できるように注意するべきだろう。また、泉の中には薬瓶が見える。[探索時間:3]',
          }
        ),

        "AK1T" => DiceTable::Table.new(
          "[神器:近接]表A☆1",
          "1D6",
          [
            'フレイムソード P.82',
            'サンダースピア P.82',
            'ディフェンダー P.82',
            'ビッグロック P.82',
            'ブラックジャック P.82',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "AK2T" => DiceTable::Table.new(
          "[神器:近接]表A☆2",
          "1D6",
          [
            'イチモンジブレード P.82',
            'レオソード P.82',
            'ブラッドアックス P.82',
            'ウッドバスター P.82',
            'クラブライブ P.82',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "AK3T" => DiceTable::Table.new(
          "[神器:近接]表A☆3",
          "1D6",
          [
            'ソニックブレード P.83',
            'アブソリュートゼロ P.83',
            'ブライトアックス P.83',
            'ブレスメイス P.83',
            'レッドソード P.83',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "AK4T" => DiceTable::Table.new(
          "[神器:近接]表A☆4",
          "1D6",
          [
            'ディヴァインブレード P.83',
            'ゴリラソード P.83',
            'ジャホコ P.83',
            'ゴローマサムネ P.83',
            'ドンキードンキ P.83',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "AK5T" => DiceTable::Table.new(
          "[神器:近接]表A☆5",
          "1D1",
          [
            'カタストロフ P.83',
          ]
        ),

        "AS1T" => DiceTable::Table.new(
          "[神器:射撃]表A☆1",
          "1D6",
          [
            'ライトボウ P.84',
            'ウィンドブレイカー P.84',
            'マシンクロスボウ P.84',
            'マッハボウ P.84',
            'シャープチャクラム P.84',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "AS2T" => DiceTable::Table.new(
          "[神器:射撃]表A☆2",
          "1D6",
          [
            'ラストシューター P.84',
            'マグネットボウ P.84',
            'ビッグブーメラン P.84',
            'ホーミングシューター P.84',
            'アサシンチャクラム P.84',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "AS3T" => DiceTable::Table.new(
          "[神器:射撃]表A☆3",
          "1D6",
          [
            'パワーライフル P.85',
            'フレイムガン P.85',
            'エレクトロスター P.85',
            'ナパームシューター P.85',
            'ラインヒーラー P.85',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "AS4T" => DiceTable::Table.new(
          "[神器:射撃]表A☆4",
          "1D6",
          [
            'ストーカーボウ P.85',
            'ビームチャクラム P.85',
            'アストラルボウ P.85',
            'フォーチュンガン P.85',
            'ウォークライボウ P.85',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "AS5T" => DiceTable::Table.new(
          "[神器:射撃]表A☆5",
          "1D1",
          [
            'オートリピーター P.85',
          ]
        ),

        "AM1T" => DiceTable::Table.new(
          "[神器:魔法]表A☆1",
          "1D6",
          [
            'スカーレットワンド P.86',
            'クラウドスタッフ P.86',
            'アイスジュエル P.86',
            'パワーワンド P.86',
            'ジーニアスブック P.86',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "AM2T" => DiceTable::Table.new(
          "[神器:魔法]表A☆2",
          "1D6",
          [
            'ヘルアポカリプス P.86',
            'シャーマニックスカル P.86',
            'カーズタスク P.86',
            'バリアロッド P.86',
            'ホーリーベル P.86',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "AM3T" => DiceTable::Table.new(
          "[神器:魔法]表A☆3",
          "1D6",
          [
            'オーシャンワンド P.87',
            'ダーククラウド P.87',
            'ワイズマン P.87',
            'エンシェントワンド P.87',
            'ゴッドゴブレット P.87',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "AM4T" => DiceTable::Table.new(
          "[神器:魔法]表A☆4",
          "1D6",
          [
            'テンペストロッド P.87',
            'セイバースタッフ P.87',
            'ダークスカッター P.87',
            'ルーラーズレイ P.87',
            'デモンズホーン P.87',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "AM5T" => DiceTable::Table.new(
          "[神器:魔法]表A☆5",
          "1D1",
          [
            'スターコンプレッサ P.87',
          ]
        ),

        "AY1T" => DiceTable::Table.new(
          "[神器:鎧]表A☆1",
          "1D6",
          [
            'ハードアーマー P.88',
            'シーヴスローブ P.88',
            'マジックアーマー P.88',
            'ナイトアーマー P.88',
            'フェザーキルト P.88',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "AY2T" => DiceTable::Table.new(
          "[神器:鎧]表A☆2",
          "1D6",
          [
            'トワイライトアーマー P.88',
            'ヒューマンガーター P.88',
            'ソルトメイル P.88',
            'ライトムーヴ P.88',
            'キャプテンアーマー P.88',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "AY3T" => DiceTable::Table.new(
          "[神器:鎧]表A☆3",
          "1D6",
          [
            'ジェットアーマー P.89',
            'ドラゴンアーマー P.89',
            'ホーリーケープ P.89',
            'ビーストエイジ P.89',
            'クロスフォートレス P.89',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "AY4T" => DiceTable::Table.new(
          "[神器:鎧]表A☆4",
          "1D6",
          [
            'フェニックスアーマー P.89',
            'マジックゲイナー P.89',
            'インシュランスメイル P.89',
            'ジャイアントメイル P.89',
            'バンブーメイル P.89',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "AY5T" => DiceTable::Table.new(
          "[神器:鎧]表A☆5",
          "1D1",
          [
            'ディヴァインクロス P.89',
          ]
        ),

        "AT1T" => DiceTable::Table.new(
          "[神器:盾]表A☆1",
          "1D6",
          [
            'スパイクシールド P.90',
            'ウェーブシールド P.90',
            'レアメタルシールド P.90',
            'バインドシールド P.90',
            'ゲイルシールド P.90',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "AT2T" => DiceTable::Table.new(
          "[神器:盾]表A☆2",
          "1D6",
          [
            'アースシールド P.90',
            'フレイムレジスター P.90',
            'ポラリゼーショナー P.90',
            'グレートシールド P.90',
            'センサーシールド P.90',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "AT3T" => DiceTable::Table.new(
          "[神器:盾]表A☆3",
          "1D6",
          [
            'ヒールボード P.91',
            'フレッシュガーダー P.91',
            'タフシールド P.91',
            'ワイズモノリス P.91',
            'エールポンポン P.91',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "AT4T" => DiceTable::Table.new(
          "[神器:盾]表A☆4",
          "1D6",
          [
            'ガッデスミラー P.91',
            'ラックエムブレム P.91',
            'バトルドレイナー P.91',
            'グランドソーサー P.91',
            'オートドール P.91',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "AT5T" => DiceTable::Table.new(
          "[神器:盾]表A☆5",
          "1D1",
          [
            'ダークマター P.91',
          ]
        ),

        "AA1T" => DiceTable::Table.new(
          "[神器:装飾品]表A☆1",
          "1D6",
          [
            'エナジーブレス P.92',
            'ホークガントレット P.92',
            'ライトアミュレット P.92',
            'センシングブレス P.92',
            'レジストマント P.92',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "AA2T" => DiceTable::Table.new(
          "[神器:装飾品]表A☆2",
          "1D6",
          [
            'ドリルブレス P.92',
            'ルーンマント P.92',
            'バランスビット P.92',
            'ベストサングラス P.92',
            'シルバーペンダント P.92',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "AA3T" => DiceTable::Table.new(
          "[神器:装飾品]表A☆3",
          "1D6",
          [
            'ミスティックマスク P.93',
            'ガードブレス P.93',
            'マジックピアス P.93',
            'ミラージュブレス P.93',
            'キャットフード P.93',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "AA4T" => DiceTable::Table.new(
          "[神器:装飾品]表A☆4",
          "1D6",
          [
            'ショルダーアーム P.93',
            'ナイトコート P.93',
            'エンジェルバックル P.93',
            'オラクルピアス P.93',
            'センサーリング P.93',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "AA5T" => DiceTable::Table.new(
          "[神器:装飾品]表A☆5",
          "1D1",
          [
            'ノーブルスフィア P.93',
          ]
        ),

        "BK1T" => DiceTable::Table.new(
          "[神器:近接]表B☆1",
          "1D6",
          [
            'マンイーター P.94',
            'アイスメイス P.94',
            'エクステンダー P.94',
            'スラッグカッター P.94',
            'フィアーギロチン P.94',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "BK2T" => DiceTable::Table.new(
          "[神器:近接]表B☆2",
          "1D6",
          [
            'ツインランサー P.94',
            'メディシンランス P.94',
            'レイスラッシャー P.94',
            'シザーソード P.94',
            'エナジーヨーヨー P.94',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "BK3T" => DiceTable::Table.new(
          "[神器:近接]表B☆3",
          "1D6",
          [
            'ラディオランサー P.95',
            'マシンキラー P.95',
            'ニンジャハンマー P.95',
            'ストームブレード P.95',
            'オートバランサー P.95',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "BK4T" => DiceTable::Table.new(
          "[神器:近接]表B☆4",
          "1D6",
          [
            'ラムダセイバー P.95',
            'エクスカリアックス P.95',
            'ゴッドロック P.95',
            'バスターメイス P.95',
            'グルメランサー P.95',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "BK5T" => DiceTable::Table.new(
          "[神器:近接]表B☆5",
          "1D1",
          [
            'カタストロフ P.95',
          ]
        ),

        "BS1T" => DiceTable::Table.new(
          "[神器:射撃]表B☆1",
          "1D6",
          [
            'ホーリースリング P.96',
            'ハンターボウ P.96',
            'ミラージュダーツ P.96',
            'ベストダーツ P.96',
            'エイミングボウ P.96',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "BS2T" => DiceTable::Table.new(
          "[神器:射撃]表B☆2",
          "1D6",
          [
            'ラビットボウ P.96',
            'スティングダーツ P.96',
            'ビジネスカード P.96',
            'エクスプロードボウ P.96',
            'インパクトエアガン P.96',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "BS3T" => DiceTable::Table.new(
          "[神器:射撃]表B☆3",
          "1D6",
          [
            'オーガシューター P.97',
            'マーダーボウガン P.97',
            'メンタルドレイナー P.97',
            'スタナーガン P.97',
            'ニードルシューター P.97',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "BS4T" => DiceTable::Table.new(
          "[神器:射撃]表B☆4",
          "1D6",
          [
            'ガーディアンボウ P.97',
            'フォトンブーメラン P.97',
            'ダンスマシンガン P.97',
            'スリリングスリング P.97',
            'アルケミストガン P.97',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "BS5T" => DiceTable::Table.new(
          "[神器:射撃]表B☆5",
          "1D1",
          [
            'オートリピーター P.97',
          ]
        ),

        "BM1T" => DiceTable::Table.new(
          "[神器:魔法]表B☆1",
          "1D6",
          [
            'ソニックスタッフ P.98',
            'ホーリーワンド P.98',
            'ライフメイカー P.98',
            'ゴリラワンド P.98',
            'コンセントレイター P.98',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "BM2T" => DiceTable::Table.new(
          "[神器:魔法]表B☆2",
          "1D6",
          [
            'ポイズンワンド P.98',
            'キーンタロー P.98',
            'マジックビースト P.98',
            'オープニングスタッフ P.98',
            'ディヴァイドジュエル P.98',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "BM3T" => DiceTable::Table.new(
          "[神器:魔法]表B☆3",
          "1D6",
          [
            'サイクロンアイ P.99',
            'クリムゾンオーブ P.99',
            'ルーインスタッフ P.99',
            'アジリティオーブ P.99',
            'キングステッキ P.99',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "BM4T" => DiceTable::Table.new(
          "[神器:魔法]表B☆4",
          "1D6",
          [
            'ディヴァインドラム P.99',
            'エンリッチオーブ P.99',
            'ヒールアミュレット P.99',
            'マナインヘイラー P.99',
            'ライトライト P.99',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "BM5T" => DiceTable::Table.new(
          "[神器:魔法]表B☆5",
          "1D1",
          [
            'スターコンプレッサ P.99',
          ]
        ),

        "BY1T" => DiceTable::Table.new(
          "[神器:鎧]表B☆1",
          "1D6",
          [
            'ダンボールボックス P.100',
            'マーチャントクロス P.100',
            'ウィザードローブ P.100',
            'バランスアーマー P.100',
            'レジストローブ P.100',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "BY2T" => DiceTable::Table.new(
          "[神器:鎧]表B☆2",
          "1D6",
          [
            'スカウトローブ P.100',
            'ランプアーマー P.100',
            'フィールドローブ P.100',
            'ケミカルアーマー P.100',
            'ビジネススーツ P.100',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "BY3T" => DiceTable::Table.new(
          "[神器:鎧]表B☆3",
          "1D6",
          [
            'セージアーマー P.101',
            'トータスアーマー P.101',
            'ブレスブレスト P.101',
            'ラビットスーツ P.101',
            'サクリファイスメイル P.101',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "BY4T" => DiceTable::Table.new(
          "[神器:鎧]表B☆4",
          "1D6",
          [
            'ファルコンアーマー P.101',
            'ガッツアーマー P.101',
            'ゴットカーボン P.101',
            'パワードアーマー P.101',
            'グラビティガード P.101',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "BY5T" => DiceTable::Table.new(
          "[神器:鎧]表B☆5",
          "1D1",
          [
            'ディヴァインクロス P.101',
          ]
        ),

        "BT1T" => DiceTable::Table.new(
          "[神器:盾]表B☆1",
          "1D6",
          [
            'ルーンボード P.102',
            'ラブリーペット P.102',
            'ハリケーンシールド P.102',
            'ジュークシールド P.102',
            'ミラーシールド P.102',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "BT2T" => DiceTable::Table.new(
          "[神器:盾]表B☆2",
          "1D6",
          [
            'フリーズカウンター P.102',
            'ゲイルガーダー P.102',
            'フォースバックラー P.102',
            'ロードシールド P.102',
            'ビッグドーナツ P.102',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "BT3T" => DiceTable::Table.new(
          "[神器:盾]表B☆3",
          "1D6",
          [
            'ナイスボード P.103',
            'シニスターシールド P.103',
            'ノーブルソーサー P.103',
            'ミサイルシールド P.103',
            'ゴリラシールド P.103',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "BT4T" => DiceTable::Table.new(
          "[神器:盾]表B☆4",
          "1D6",
          [
            'ビームバックラー P.103',
            'オールドシールド P.103',
            'サニーガード P.103',
            'ゴッドクロック P.103',
            'ミストシールド P.103',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "BT5T" => DiceTable::Table.new(
          "[神器:盾]表B☆5",
          "1D1",
          [
            'ダークマター P.103',
          ]
        ),

        "BA1T" => DiceTable::Table.new(
          "[神器:装飾品]表B☆1",
          "1D6",
          [
            'ラックデビルアイ P.104',
            'ビームリング P.104',
            'ダッシューズ P.104',
            'エレガンダイ P.104',
            'スキルブック P.104',
            'ランクアップ？([神聖石]10個)',
          ]
        ),
        "BA2T" => DiceTable::Table.new(
          "[神器:装飾品]表B☆2",
          "1D6",
          [
            'ブレスアイドル P.104',
            'アロマピアス P.104',
            'スピードリング P.104',
            'ハイホーリーシンボル P.104',
            'ノーブルマント P.104',
            'ランクアップ？([神聖石]20個)',
          ]
        ),
        "BA3T" => DiceTable::Table.new(
          "[神器:装飾品]表B☆3",
          "1D6",
          [
            'シュルダーバード P.105',
            'フェアリードール P.105',
            'フレッシュブレス P.105',
            'ラビットフット P.105',
            'ファストブレス P.105',
            'ランクアップ？([神聖石]30個)',
          ]
        ),
        "BA4T" => DiceTable::Table.new(
          "[神器:装飾品]表B☆4",
          "1D6",
          [
            'ヒールグラス P.105',
            'テレポートブレス P.105',
            'ブラッドチェンジャー P.105',
            'ルーンブレス P.105',
            'コンディショナー P.105',
            'ランクアップ？([神聖石]40個)',
          ]
        ),
        "BA5T" => DiceTable::Table.new(
          "[神器:装飾品]表B☆5",
          "1D1",
          [
            'ノーブルスフィア P.105',
          ]
        ),

      }.freeze

      register_prefix('\d+D6>=(\d+|[?])', 'REV\[[\d,]+\]>=(\d+|[?])', TABLES.keys)
    end
  end
end
