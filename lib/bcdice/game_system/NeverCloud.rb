# frozen_string_literal: true

require "bcdice/dice_table/table"

module BCDice
  module GameSystem
    class NeverCloud < Base
      # ゲームシステムの識別子
      ID = 'NeverCloud'

      # ゲームシステム名
      NAME = 'ネバークラウドTRPG'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'ねはあくらうとTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・LIST　のコマンドを入力して、ルールの解説・2D6表、一覧の表示

        ・判定(xNC±y>=z)
        　xD6の判定を行います。ファンブル、クリティカルの場合、その旨を出力します。
        　x：振るダイスの数。
        　±y：固定値・修正値。省略可能。
        　z：目標値。省略可能。
        　ダイスの出目ふたつが6ならクリティカル(自動成功)
        　ダイスの出目すべてが1ならファンブル(自動失敗)
        　例）　2NC+2>=5　1NC
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        if /^(\d+)(?:NC|D6?)((?:[-+]\d+)*)(>=(\d+))?$/i.match?(command)
          return check_action(command)
        elsif TEXTS.key?(command)
          return TEXTS[command].chomp
        elsif TABLES.key?(command)
          return roll_tables(command, TABLES)
        else
          return nil
        end
      end

      def check_action(command)
        m = /^(\d+)(?:NC|D6?)((?:[-+]\d+)*)(>=(\d+))?$/i.match(command)
        dice_count = m[1].to_i
        modify_str = m[2]
        modify_number = ArithmeticEvaluator.eval(modify_str)
        cmp_str = m[3]
        target = m[4]&.to_i

        if modify_number == 0
          modify_str = ''
        end

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        dice_value = dice_list.sum()
        dice_str = dice_list.join(",")

        total = dice_value + modify_number

        result =
          if dice_list.count(1) == dice_count
            total = 0
            "ファンブル"
          elsif dice_list.count(6) >= 2
            "クリティカル"
          elsif target
            total >= target ? "成功" : "失敗"
          end

        sequence = [
          "(#{dice_count}D6#{modify_str}#{cmp_str})",
          "#{dice_value}[#{dice_str}]#{modify_str}",
          total,
          result
        ].compact

        return sequence.join(" ＞ ")
      end

      TEXTS = {
        'LIST' => <<~TEXT,
          ※注記：このダイスボットデータは『ネバークラウドTRPG』公式『私立彩音学園』主導の下で制作されました。
          ・公式サイト：https://sion-academy.wixsite.com/nctrpg
          ・公式リプレイ：https://sion-academy.wixsite.com/nctrpg-kaleido
          ・キャラ作成アプリ：https://nctrpg.com/bloomi

          ・判定(xD6±y>=z)

          ()内のコマンドを入力して詳細を表示。

          2D6(CHAR1)　・所属表(2D6またはRoC。基本ルール書籍版P33)
          2D6(CHAR2)　・趣味表(2D6またはRoC。基本ルール書籍版P38)
          2D6(CHAR3)　・リビド武装形状表(2D6またはRoC。基本ルール書籍版P39)
          2D6(NAYA1)　悩みの詳細表・愛/Love:得意方向(正面)(2D6またはRoC。基本ルール書籍版P49)
          2D6(NAYA2)　悩みの詳細表・体/Figure:得意方向(正面)(2D6またはRoC。基本ルール書籍版P49)
          2D6(NAYA3)　悩みの詳細表・才/Talent:得意方向(背面)(2D6またはRoC。基本ルール書籍版P49)
          2D6(NAYA4)　悩みの詳細表・絆/Bonds:得意方向(側面)(2D6またはRoC。基本ルール書籍版P49)
          2D6(NAYA5)　悩みの詳細表・住/Home:得意方向(側面)(2D6またはRoC。基本ルール書籍版P49)

          各種2D6:RoC表はコマンドの最後にアルファベットのLを付けて一覧表示が可能(例:NAYA5→NAYA5L)

          (LIKE1)　LIKE(基本ルール書籍版P60)
          (RESE1)　リサーチカード(基本ルール書籍版P63)
          (RESE2)　インタビュー(基本ルール書籍版P62)
          (RESE3)　パイルドライヴ(基本ルール書籍版P64)
          (RESE4)　[決意]と[使命](基本ルール書籍版P61)

          (ARTS)　リビドアーツのデータ項目(基本ルール書籍版P40)
          (STAT1)　SSリスト(基本ルール書籍版P41)
          (STAT2)　LSリスト(基本ルール書籍版P411)
          (ACTI1)　タイミング:サブアクション(基本ルール書籍版P422)
          (ACTI2)　タイミング:メインアクション(基本ルール書籍版P42)
          (ACTI3)　タイミング:インスタント(基本ルール書籍版P42)
          (ACTI4)　サーヴァント共通アクション(基本ルール書籍版P42)

          (BATT1)　ラストパイル(基本ルール書籍版P67)
          (BATT2)　攻撃の手順(メインアクションで行う)01.攻撃宣言ステップ(基本ルール書籍版P74)
          (BATT3)　攻撃の手順(メインアクションで行う)02.命中判定ステップ(基本ルール書籍版P74)
          (BATT4)　攻撃の手順(メインアクションで行う)03.ダメージ決定ステップ(基本ルール書籍版P74)
          (BATT5)　攻撃の手順(メインアクションで行う)04.ダメージ適用ステップ(基本ルール書籍版P74)
          (BATT6)　[決意]の効果(基本ルール書籍版P61)
          (BATT7)　[使命]の効果(基本ルール書籍版P61)
          (BATT8)　パケット(基本ルール書籍版P69)
          (BATT9)　リビドストーム(基本ルール書籍版P71)
          (PIET1)　ピーターの基本的な性質(基本ルール書籍版P72)
          (PIET2)　《AoE》(Area_of_Effect)(基本ルール書籍版P72)
          (PIET3)　ピーターの「行動指針」((2D6またはRoC。基本ルール書籍版P110)

          (MINI1)　基本ルールからねばくらミニへの変更点(ねばくらミニ書籍版P05)
          (MINI2)　ねばくらミニでのリサーチのルール変更点(ねばくらミニ書籍版P11)
          (MINI3)　ねばくらミニでのバトル演出のルール(ねばくらミニ書籍版P12)
          (MINI4)　ねばくらミニでのアーツ(ねばくらミニ書籍版P13)
          (MINI5)　ねばくらミニでのスペシャルアーツ(ねばくらミニ書籍版P13)
          (MINI6)　ねばくらミニでのポータルとサーヴァント(ねばくらミニ書籍版P14)
        TEXT
        'LIKE1' => <<~TEXT,
          LIKE(基本ルール書籍版P60)
          ・全ての参加者(PLやGMや見学者)はセッション中にPCやGMのロールプレイや行動に、
          　共感や称賛や琴線に触れた時[LIKE:～]と言ってその内容と共に記述して蓄積して行く。
          ・リサーチ中では手番を消費せず[LIKE]1点ごとに対象の{HP}を[50]点回復させても良い。
        TEXT
        'RESE1' => <<~TEXT,
          リサーチカード(基本ルール書籍版P63)
          ・リサーチ中に捜査対象とされるもの。オモテ面に「名称」「難易度」「ピーターのバフ」「情景描写」が記述される。
          ・「ウラ面」には[Pコトノハ]「暴露描写」が記述される。「暴露描写」を閲覧したロールプレイは主に[LIKE]の創出に寄与する。
          ・リサーチカードの選択とWコトノハと使用能力値の提示→PCのロールプレイ→判定が成功の場合→GMから暴露描写の提示→PCのロールプレイ。
        TEXT
        'RESE2' => <<~TEXT,
          インタビュー(基本ルール書籍版P62)
          ・自分以外のPC1人の「悩みの詳細」「追加設定」または〈パイルドライヴ〉済みの暴露描写1つを対象とし、
          　その内容を拡張するような質問をする。対象となったPCまたはGMは「追加設定」を作成して公開する。
          ・質問者は「追加設定」から単語かフレーズ1つを切り出し[ワード]として記録する。
          ・これらの「追加設定」やロールプレイは主に[LIKE]の創出に寄与される。
        TEXT
        'RESE3' => <<~TEXT,
          パイルドライヴ(基本ルール書籍版P64)
          ・調査判定時にプリプレイで選択した[Wコトノハ]と「ウラ面」の[Pコトノハ]が同一ならば、
          　自動成功(レゾナンス・パイルドライヴ)として、PCは[30]のHPダメージを受け「ウラ面」を開示する。
          ・[Pコトノハ]が合っておらずとも「[RW能力値/知識/コミュ力/趣味]+2D」の判定で
          「難易度」以上ならば成功(パイルドライヴ)として、PCは[30]のHPダメージを受け「ウラ面」を開示し[Pコトノハ]を手に入れる。
          ・指定されたサイクル以内に「ウラ面」を開示できなかった、
          　リサーチカードの「ピーターのバフ」は戦闘シーンの〈ピーター〉に付与される。
        TEXT
        'RESE4' => <<~TEXT,
          [決意]と[使命](基本ルール書籍版P61)
          ・リサーチ終了時に[LIKE]を[決意]という戦闘時に使用する単位に変換する。
          ・この時[LIKE]が50個以上の場合、GMは[決意]を無制限に使用することにしても良い。
          ・これとは別にGMは[LIKE]の合計点を5で割った値を[使命]言う単位(最大5点)とする。
          　[決意]と[使命]は[Pコトノハ][Sコトノハ][ワード]の単語ごとに割り振られ、これらの単語を使用したロールプレイを推奨する。
        TEXT
        'ARTS' => <<~TEXT,
          リビドアーツのデータ項目(基本ルール書籍版P40)
          ・射程:起点から『ぴったり』に、何Sq離れたキャラクターを対象に取れるかを示す。射程0は自身のみのことである。
          ・威力:そのアーツを使用した結果に対象に及ぼす数値を示す。ダイスロールを含む場合「威力ロール」と呼ぶ。
          ・コスト/制限:コストとして実行者の{パケット}をn点上昇させる。
          ・スペシャルアーツ:「タイミング:インスタント」必ず[決意]1点を消費する。この時「[決意]の効果」は発生しない。
          ・アーツのリネーム:取得アーツはPCの設定に合わせ(他のアーツと誤解させないよう)名前を好きに変更しても良い。
        TEXT
        'STAT1' => <<~TEXT,
          SSリスト(基本ルール書籍版P41)
          　下記4つのショートステータス(SS)は準備プロセス終了時に解除される。
          ・[SS感覚障害]　全ての判定に-1D&{技量}が0になる(判定時のダイス目の1はファンブルになる)
          ・[SS混乱]　行動前に1Dを振り偶数だった場合は行動できない。
          ・[SS危機]　回避判定を行えず「致命的命中(ダメージ2倍)になる。
          ・[SSマーク]　「{パケット}の値が最も高いPC、[レッド]として扱う。
        TEXT
        'STAT2' => <<~TEXT,
          LSリスト(基本ルール書籍版P41)
          　下記4つのロングステータス(LS)は準備プロセス終了時に解除されない。
          ・[リフレクト]　ダメージを受けた時その2倍の値のダメージを相手に与え効果を解除する。
          ・[ブースト:ｎ]　[威力ロール]の前に消費を選択した場合は威力ロールに[+n]を与え効果を解除する。
          ・[DoT:xTn](Damage_on_Time)　準備プロセスにx点のHPダメージを受け、
          　nを1減らし0になると解除される。効果が累積した場合それぞれ大きい値になる。
          ・[行動不能]　HPが0になった時[未行動]でなくなり、全ての行動や判定を行うことができない。
          　{パケット}が0になり全てのSSが解除される。《助け起こす》または[フレンドシップ]1つ消費して[未行動]になることで解除できる。
        TEXT
        'ACTI1' => <<~TEXT,
          タイミング:サブアクション(基本ルール書籍版P42)
          ・《通常移動》{移動力}Sq数まで自分のコマを動かす。
          ・《全力移動》{移動力}+2Sq数まで自分のコマを動かす。メインアクションを行う権利を失う。
        TEXT
        'ACTI2' => <<~TEXT,
          タイミング:メインアクション(基本ルール書籍版P42)
          ・《かばう》射程0～2。次に対象が受けるダメージを1回だけ肩代わりする。
          ・《武装解除》即座にそのバトルシーンから退場する。そのシーンに復帰することができない。
          ・《助け起こす》射程:1。他のPCの[行動不能]を解除し{HP}を1まで回復する。
        TEXT
        'ACTI3' => <<~TEXT,
          タイミング:インスタント(基本ルール書籍版P42)
          　(行動権プロセスに使用する。1回のタイミングに行動は1回まで)
          ・《シフト》制限:シーン1回。即座に2Sqまで移動できる。
          ・《ギミック解除》射程1。制限:サイクル1回。「要求能力値」があるギミックに判定を行い[達成値]8以上だった場合これを除外する。
          ・《クイックロード》制限:シーン1回。バトルシーン最初の行動権プロセスでのみ使用できる。使用者の{パケット}を+3する。
        TEXT
        'ACTI4' => <<~TEXT,
          サーヴァント共通アクション(基本ルール書籍版P42)
          ・《リバース》タイミング:インスタントまたは戦闘開始時。射程:1。サーヴァントコマが無い場合新たに設置し{HP}10を譲り渡す。
          ・《相互移動》タイミング:サブアクション。サーヴァントと自身を合計4Sqまで移動できる。
          ・《複数視点》タイミング:インスタント。制限:サイクル1回&サーヴァントと分離中のみ。次の回避判定に+2の修正を得る。
        TEXT
        'BATT1' => <<~TEXT,
          ラストパイル(基本ルール書籍版P67)
          　各PCはそれまでに集まった[決意]や「ワード」から使いたい言葉を含んだロールプレイによって
          「戦う理由」を宣言すること。行わなければ次のバトルシーンのエンカウントシート上に登場することができない。
        TEXT
        'BATT2' => <<~TEXT,
          攻撃の手順(メインアクションで行う)01.攻撃宣言ステップ(基本ルール書籍版P74)
          ・攻撃側は攻撃に用いる行動と対象とコスト/制限の宣言を行う。
          ・GMが対象が適切であることを確認し(適切でないなら巻き戻す)をコスト/制限の支払いを確認する。
          ・攻撃側が〈ピーター〉なら、攻撃の対象に{正面}を向ける(向きを変えるのはこの場面のみ)
        TEXT
        'BATT3' => <<~TEXT,
          攻撃の手順(メインアクションで行う)02.命中判定ステップ(基本ルール書籍版P74)
          「判定」が「自動成功」「受動任意」の場合「命中」したとして、ダメージ決定ステップに移る。
          ・攻撃側は[命中値](=行動による固定値＋{技量}＋「ポータル」による修正値)を宣言する。
          ・防御側は[回避値](=2D6の値)を宣言する。
          ・攻撃側の1ゾロまたは防御側が6ゾロの場合「全回避」として、攻撃の終了に移る。
          ・[命中値]≦[回避値]の場合「半回避」になる。
          ・[命中値]＞[回避値]の場合「命中」になる。
          ・防御側が1ゾロの場合「致命的命中」として、03.ダメージ決定ステップに移る。
        TEXT
        'BATT4' => <<~TEXT,
          攻撃の手順(メインアクションで行う)03.ダメージ決定ステップ(基本ルール書籍版P74)
          　この手順は決して巻き戻さず下記の順で累積させて、04.ダメージ適用ステップに移る。
          ・攻撃側は[ブースト]を使用するか決定する。
          ・攻撃側は次に[威力ロール]を使うダメージを算出する。
          ・攻撃側は最後に[威力ロール]を使わない(特殊効果による)ダメージを算出する。
        TEXT
        'BATT5' => <<~TEXT,
          攻撃の手順(メインアクションで行う)04.ダメージ適用ステップ(基本ルール書籍版P74)
          ・攻撃側が「{得意方向}以外への攻撃」または「半回避」の場合、HPダメージ半減(切り捨て)+SS無効(DoTは数値共に半減)
          ・攻撃側が「{得意方向}以外への攻撃」かつ「半回避」の場合、2つの半減効果は累積しない。
          ・回避側が「致命的命中」の場合、HPダメージ2倍にする。
          ・攻撃側が「{得意方向}以外への攻撃」かつ回避側が「致命的命中」の場合、半減効果かつ2倍ダメージで元の数値に中和される。
          ・以上のHPダメージを防御側の{HP}から引く。
          ・防御側の{パケット}を1減らす。この時[リフレクト]をもっていた場合その2倍のHPダメージを攻撃側に与える。
          ・最後に「{得意方向}への攻撃」だった場合、攻撃側は[SS危機]を受ける。
        TEXT
        'BATT6' => <<~TEXT,
          [決意]の効果(基本ルール書籍版P61)
          ・〈ピーター〉の{アーツ}を1つ、または{HP}残量、または{行動指針}を公開させる。
          ・直前のPCまたは〈ピーター〉の判定を1回だけ振り直させる。
          ・行動権プロセスでPCの誰か1人の[SS危機]1つを即座に解除する。
        TEXT
        'BATT7' => <<~TEXT,
          [使命]の効果(基本ルール書籍版P61)
          ・行動権プロセスで〈ピーター〉のSS1つを解除する。
          ・行動権プロセスで〈ピーター〉の向きを90度変える(制限:サイクル中2回)
          ・行動権プロセスで[未行動]のPC1人を[レッド]にする(制限:シーン中1回)
          ・次の〈ピーター〉の手番で全PCの{パケット}が0とする(攻撃対象の基準が行動指針になる)(制限:シーン中1回)
        TEXT
        'BATT8' => <<~TEXT,
          パケット(基本ルール書籍版P69)
          　{パケット}に上限は無く最低値は0である。戦闘開始時と戦闘終了時に各PCの{パケット}を0にする。
          　{リビドアーツ}の使用時にコストとして上昇し、ダメージを受けたPCはダメージ適用ステップで「{パケット}を-1」する。
          　サーヴァントの{パケット}は自らのPCと同じくする。
        TEXT
        'BATT9' => <<~TEXT,
          リビドストーム(基本ルール書籍版P71)
          〈ピーター〉のナナメにあるSqを【リビドストーム】と呼ぶ。
          　このSqにいるキャラクターは攻撃の際に自身の{得意方向}の効果が無効になる。
        TEXT
        'PIET1' => <<~TEXT,
          ピーターの基本的な性質(基本ルール書籍版P72)
          ・《AoE》(Area_of_Effect)を持つ。{リビドタイプ}と{属性}と{得意方向}と{パケット}を持たず、移動しない。
          ・〈ピーター〉が攻撃対象を選択する場合、特別な記載が無い限り「{パケット}の値が最も高い[レッド]」のPCを優先的に選択し
          「向き」を変えて攻撃する(向きを変えるのはこの場面のみ)[レッド]が複数いる場合その中で[SS危機]を持つPCを特に優先する。
          　さらに対象が複数いる場合「行動指針」の影響を受ける。
          「行動指針」のリストの上下端に近いものほど処理が複雑化したり、PCの行動を制限するため推奨されない。
        TEXT
        'PIET2' => <<~TEXT,
          《AoE》(Area_of_Effect)(基本ルール書籍版P72)
          　選択したAoEエリア＿命中:自動成功＿威力:50+(10×{PR})
          　サイクル開始時に効果範囲を設置、終了時に起動して効果範囲内のPCにダメージを与える。
          　サイクル開始時に効果範囲内であっても起動時までに範囲外であればダメージは受けない。
        TEXT
        'PIET3' => <<~TEXT,
          ピーターの「行動指針」((2D6またはRoC。基本ルール書籍版P110)
          02:ストーカー     : 戦闘開始時にPCを1人指定し、そのPCを標的にする。
          03:強敵狙い       : 現在のサイクルで最も高い威力ロールを行ったPCを標的にする。
          04:近距離狙い     : このエネミーに最も近いPCを標的にする。
          05:マウンティング : このエネミーよりも行動力の低いPCを標的にする。
          06:同族狙い       : 〈ターゲット〉と同じ属性のPCを標的にする。
          07:遠距離狙い     : このエネミーから最も遠いPCを標的にする。
          08:ハンター       : SSを所持しているPCを標的にする。
          09:とどめ打ち     : {HP}が最大値の4分の1以下のPCを標的にする。
          10:臆病者狙い     : 現在のサイクルでピーターから距離をとったPCを標的にする。
          11:特定属性狙い   : 戦闘開始時に指定した属性のPCを標的にする。
          12:天の邪鬼       : [SS危機]を持たないPCを標的とし、持つPCは優先しなくなる。
        TEXT
        'MINI1' => <<~TEXT,
          基本ルールからねばくらミニへの変更点(ねばくらミニ書籍版P05)
          ・PLは3人(推定4時間)とする。人数を増やすのは構わないが所要時間を4人(5時間半)、5人(7時間半)とする。
          ・リサーチフェイズは戦闘も含めたクエストフェイズと呼び替える。バトルフェイズは存在しない。
          ・オープニングフェイズ、エンディングフェイズは1シーンのみとする。
          ・クエストフェイズは導入のシーンと、捜査・宣戦布告・戦闘の演出(総計3サイクル)のクエストシーンによって構成される。
          　1つの手番の(テキストセッションの）所要時間の目安は10分ほど。
          　ラストパイルも、インタビューも、1人あたり1回10分の持ち時間を想定している。
        TEXT
        'MINI2' => <<~TEXT,
          ねばくらミニでのリサーチのルール変更点(ねばくらミニ書籍版P11)
          ・[Wコトノハ]は宣言せず〈レゾナンス・パイルドライヴ〉は発生しない(プリプレイでも[Wコトノハ]を選択しない)
          ・「ピーターのバフ」は無効になる。
          ・《インタビュー》はPCごとにシーン1回10分とする。
        TEXT
        'MINI3' => <<~TEXT,
          ねばくらミニでのバトル演出のルール(ねばくらミニ書籍版P12)
          ・エンカウントシート(移動・射程・方角・方向・AoEのルール)を使用せず「サイクル制限:1サイクル」で行う。
          ・バトル演出中に全PCが出したHPダメージの値を累積して「ダメージ合計」に加算しサイクル終了時に「勝利値」以上であれば勝利する。
          ・勝利値:[300+「ウラ返しにされなかったリサーチカードの枚数」×50]
          ・PLが4人以上び場合、勝利値に[(人数-3)×100]をさらに加えてもよい。
        TEXT
        'MINI4' => <<~TEXT,
          ねばくらミニでのアーツ(ねばくらミニ書籍版P13)
          ・攻撃アーツ:アーツの効果がそのまま適用される。HPダメージを「ダメージ合計」に加える。
          ・DoTの選択ルール:使用者が望む場合(防御判定よりも前に宣言すること)
          　対象に適用された[DoT:xTn]を、[xかけるn÷2]のHPダメージとして扱う(対象が半回避した場合xとnの両方が半減する)
          ・支援アーツ:対象が次に与えるHPダメージを倍にする(名前の違うアーツによるものであっても効果は累積しない)
          《リフレクト》上記の支援アーツの効果のかわりに、元の効果文のとおりに対象に[リフレクト]を与えてもよい。
          ・支援アーツ:対象が次に受けるHPダメージを倍にする(名前の違うアーツによるものであっても効果は累積しない)
        TEXT
        'MINI5' => <<~TEXT,
          ねばくらミニでのスペシャルアーツ(ねばくらミニ書籍版P13)
          ・コストとして[決意]を消費し1度はRPをする必要がある。
          ・対象がPCなら、対象が次に与えるHPダメージを倍にする。他の「与えるHPダメージを倍にする」効果に累積する。
          ・対象がエネミーなら、対象が次に受けるHPダメージを倍にする。他の「受けるHPダメージを倍にする」効果に累積する。
        TEXT
        'MINI6' => <<~TEXT,
          ねばくらミニでのポータルとサーヴァント(ねばくらミニ書籍版P14)。
          ・「ポータル」なら威力ロールに+30してよい。
          ・「サーヴァント」は自身が攻撃の対象になったとき、対象を自身のサーヴァントに変更してよい。
        TEXT
        'CHAR1L' => <<~TEXT,
          ・所属表(2D6またはRoC。基本ルール書籍版P33)
          2, 無職/専業主婦/専業主夫
          3, パート・アルバイト
          4, 中学生
          5, 高校生
          6, 大学生
          7, 短大/専門学校生
          8, 会社員
          9, 公務員
          10, 個人事業主
          11, フリーランス
          12, 経営者
        TEXT
        'CHAR2L' => <<~TEXT,
          ・趣味表(2D6またはRoC。基本ルール書籍版P38)
          2, プログラミング/ハッキング
          3, テレビゲーム/ボードゲーム
          4, 楽器演奏/作曲/編曲/DTM
          5, 工芸/アクセサリー/プラモデル制作
          6, イラスト/モデリング/デザイン
          7, 電子工作/機械工作
          8, 野球/サッカー/バスケ/テニス/バレエ/
          9, ファッション
          10, 自転車/BMX/バイク/車
          11, ライトノベル/漫画/アニメ
          12, ペット/ピクシー育成/生物観察
        TEXT
        'CHAR3L' => <<~TEXT,
          ・リビド武装形状表(2D6またはRoC。基本ルール書籍版P39)
          2, 模様。輝く五芒星や、巨大な数字など
          3, 人型。想い人、アニメキャラ、衣服など
          4, 魔法または超能力。炎や、謎のオーラなど
          5, 獣。調教された犬、カラス、ヘビなど
          6, 銃。拳銃、ライフル、火縄銃など
          7, 近接武器。ナイフ、バールのようなものなど
          8, 異形。巨大化した体や鉤爪、伸びる腕など
          9, ドローン。航空機タイプや四足歩行タイプなど
          10, モンスター。ゴーレム、悪魔、動く植物など
          11, 乗り物(乗ることは出来ないので注意)。車、戦闘機など。
          12, 他のどれでもない君のオリジナルのなにか
        TEXT
        'NAYA1L' => <<~TEXT,
          ●悩みの詳細表・愛/Love:得意方向(正面)(2D6またはRoC。基本ルール書籍版P49)
          2, オレには彼女が居るはずなのに誰にも見えない
          3, 好きになった人が同性。でも将来的には子供がほしい……
          4, あいつの彼女が可愛い
          5, タレントを愛してしまったが当たり前だけど告白のしようもない
          6, 好きなのに、あの人に告白できない。自分なんかが告白していい人じゃない……!
          7, ●●のことが好き。でもそれを伝えてしまったら、今の関係が崩れてしまいそうで怖い
          8, 相手が異性として見てくれない
          9, 僕の彼女は遠く離れた大学への進学を悩んでいる。応援するべきか、引き止めるべきか
          10, 一緒に遊びたいだけなのに、ついそっけない態度やいたずらをしてしまう
          11, オレの彼女が可愛すぎてつらい
          12, 好きになった人がピクシー（拡張現実の身体を持つ高性能AI）
        TEXT
        'NAYA2L' => <<~TEXT,
          ●悩みの詳細表・体/Figure:得意方向(正面)(2D6またはRoC。基本ルール書籍版P49)
          2, 過去の出来事が痛烈すぎて今が色褪せて見える
          3, 我ながら醜い
          4, 学校に行きたいけど行けない
          5, 筋トレしてるけど筋肉がつかない。同じ部活のみんなはかっこいい体を手に入れているのに
          6, 体重が気になる……ダイエットしなきゃ……でも、ごはんおいしい……
          7, 身長があと数センチほしい。そしたらあいつを背を追い越せるのに！
          8, 背が高いんだけど、もっと可愛い体に育ちたかった
          9, 肌の白い人がうらやましい
          10, 食べても食べてもお肉が付かない
          11, 病気がちだ
          12, 自分の美しさに酔いしれてしまう
        TEXT
        'NAYA3L' => <<~TEXT,
          ●悩みの詳細表・才/Talent:得意方向(背面)(2D6またはRoC。基本ルール書籍版P49)
          2, 将来何になりたいかと言われてもなんにも思いつかない
          3, 俺様の能力はこんなものではないはずだ……！　きっと明日起きたら秘められた真なる力にm
          4, ああ妬ましい妬ましい。そう思ってしまう自分が嫌だが、わかっていてもやめられない
          5, 妹の方が優秀。私だってこんなに勉強を頑張ってるのに、あの子と私のなにが違うの？
          6, バカすぎて授業についていけない
          7, バズりてぇな～～～俺もよぉ～～～～
          8, アイツに勝てない!投手としても、バッターとしても！
          9, この3年間サッカーに全てを捧げてきたのに、レギュラーになれない
          10, 頑張りたいと思うけど気が多くて集中できない
          11, 頑張って勉強したところでそれが何になるんだろうと思うと虚しい
          12, 全力を出せる場所が欲しい。自分の才能がにくい
        TEXT
        'NAYA4L' => <<~TEXT,
          ●悩みの詳細表・絆/Bonds:得意方向(側面)(2D6またはRoC。基本ルール書籍版P49)
          2, 別に変な話をしているつもりはないのだけど同級生と会話が成立しない
          3, 兄貴分に依存してしまい、1人で行動するのが怖い。アニキから離れたくない！
          4, 飼っている犬が最近不機嫌。すぐ噛み付いてくる。なにかしてしまったのだろうか？
          5, 来年、引っ越すことが決まった。一緒の高校に行こうねって約束したのに
          6, いろんなことに首をつっこんでしまい、逆にうざがられてしまう
          7, 一緒に遊んでいた親友が、最近よそよそしい気がする
          8, なかなか友達ができない。できたとおもっても気づいたら話さなくなっている
          9, 会話しているとへとへとになってる自分に時々気づく
          10, 1人でいるほうがおちつくんだけど駄目なのか
          11, 正直、クラスの連中の興味がどれもくだらなく思える
          12, そもそも自分以外のヒトがなんで大事なのかさっぱり分からない
        TEXT
        'NAYA5L' => <<~TEXT,
          ●悩みの詳細表・住/Home:得意方向(側面)(2D6またはRoC。基本ルール書籍版P49)
          2, 親がもううるさくない
          3, 親がいない。奨学金とバイトで学費を稼がなければ学校にも通えない
          4, 学校を卒業したら家を出ることになっている。でも、親元を離れたくない
          5, 親の再婚相手と上手くいかない。何故かきつく当たってしまう
          6, 親と同じ仕事を目指しているけど認めてくれない、夢を否定される
          7, お母さんが不治の病に侵されている
          8, 家族の1人が家事が致命的に下手で家の内情がヤバい
          9, 間違った場所に産まれてきた気がしてならない
          10, 兄弟との仲が致命的に悪い。嫌われている
          11, ことあるごとに親が「おまえはどうしようもないやつだ」と言ってくる
          12, 門限が早い
        TEXT
      }.freeze

      TABLES = {
        'CHAR1' => DiceTable::Table.new(
          '所属表',
          '2D6',
          [
            '無職/専業主婦/専業主夫',
            'パート・アルバイト',
            '中学生',
            '高校生',
            '大学生',
            '短大/専門学校生',
            '会社員',
            '公務員',
            '個人事業主',
            'フリーランス',
            '経営者'
          ]
        ),
        'CHAR2' => DiceTable::Table.new(
          '趣味表',
          '2D6',
          [
            'プログラミング/ハッキング',
            'テレビゲーム/ボードゲーム',
            '楽器演奏/作曲/編曲/DTM',
            '工芸/アクセサリー/プラモデル制作',
            'イラスト/モデリング/デザイン',
            '電子工作/機械工作',
            '野球/サッカー/バスケ/テニス/バレエ/',
            'ファッション',
            '自転車/BMX/バイク/車',
            'ライトノベル/漫画/アニメ',
            'ペット/ピクシー育成/生物観察'
          ]
        ),
        'CHAR3' => DiceTable::Table.new(
          'リビド武装形状表',
          '2D6',
          [
            '模様。輝く五芒星や、巨大な数字など',
            '人型。想い人、アニメキャラ、衣服など',
            '魔法または超能力。炎や、謎のオーラなど',
            '獣。調教された犬、カラス、ヘビなど',
            '銃。拳銃、ライフル、火縄銃など',
            '近接武器。ナイフ、バールのようなものなど',
            '異形。巨大化した体や鉤爪、伸びる腕など',
            'ドローン。航空機タイプや四足歩行タイプなど',
            'モンスター。ゴーレム、悪魔、動く植物など',
            '乗り物(乗ることは出来ないので注意)。車、戦闘機など。',
            '他のどれでもない君のオリジナルのなにか'
          ]
        ),
        'NAYA1' => DiceTable::Table.new(
          '悩みの詳細表・愛/Love',
          '2D6',
          [
            'オレには彼女が居るはずなのに誰にも見えない',
            '好きになった人が同性。でも将来的には子供がほしい……',
            'あいつの彼女が可愛い',
            'タレントを愛してしまったが当たり前だけど告白のしようもない',
            '好きなのに、あの人に告白できない。自分なんかが告白していい人じゃない……!',
            '●●のことが好き。でもそれを伝えてしまったら、今の関係が崩れてしまいそうで怖い',
            '相手が異性として見てくれない',
            '僕の彼女は遠く離れた大学への進学を悩んでいる。応援するべきか、引き止めるべきか',
            '一緒に遊びたいだけなのに、ついそっけない態度やいたずらをしてしまう',
            'オレの彼女が可愛すぎてつらい',
            '好きになった人がピクシー（拡張現実の身体を持つ高性能AI）'
          ]
        ),
        'NAYA2' => DiceTable::Table.new(
          '悩みの詳細表・体/Figure',
          '2D6',
          [
            '過去の出来事が痛烈すぎて今が色褪せて見える',
            '我ながら醜い',
            '学校に行きたいけど行けない',
            '筋トレしてるけど筋肉がつかない。同じ部活のみんなはかっこいい体を手に入れているのに',
            '体重が気になる……ダイエットしなきゃ……でも、ごはんおいしい……',
            '身長があと数センチほしい。そしたらあいつを背を追い越せるのに！',
            '背が高いんだけど、もっと可愛い体に育ちたかった',
            '肌の白い人がうらやましい',
            '食べても食べてもお肉が付かない',
            '病気がちだ',
            '自分の美しさに酔いしれてしまう'
          ]
        ),
        'NAYA3' => DiceTable::Table.new(
          '悩みの詳細表・才/Talent',
          '2D6',
          [
            '将来何になりたいかと言われてもなんにも思いつかない',
            '俺様の能力はこんなものではないはずだ……！　きっと明日起きたら秘められた真なる力にm',
            'ああ妬ましい妬ましい。そう思ってしまう自分が嫌だが、わかっていてもやめられない',
            '妹の方が優秀。私だってこんなに勉強を頑張ってるのに、あの子と私のなにが違うの？',
            'バカすぎて授業についていけない',
            'バズりてぇな～～～俺もよぉ～～～～',
            'アイツに勝てない!投手としても、バッターとしても！',
            'この3年間サッカーに全てを捧げてきたのに、レギュラーになれない',
            '頑張りたいと思うけど気が多くて集中できない',
            '頑張って勉強したところでそれが何になるんだろうと思うと虚しい',
            '全力を出せる場所が欲しい。自分の才能がにくい'
          ]
        ),
        'NAYA4' => DiceTable::Table.new(
          '悩みの詳細表・絆/Bonds',
          '2D6',
          [
            '別に変な話をしているつもりはないのだけど同級生と会話が成立しない',
            '兄貴分に依存してしまい、1人で行動するのが怖い。アニキから離れたくない！',
            '飼っている犬が最近不機嫌。すぐ噛み付いてくる。なにかしてしまったのだろうか？',
            '来年、引っ越すことが決まった。一緒の高校に行こうねって約束したのに',
            'いろんなことに首をつっこんでしまい、逆にうざがられてしまう',
            '一緒に遊んでいた親友が、最近よそよそしい気がする',
            'なかなか友達ができない。できたとおもっても気づいたら話さなくなっている',
            '会話しているとへとへとになってる自分に時々気づく',
            '1人でいるほうがおちつくんだけど駄目なのか',
            '正直、クラスの連中の興味がどれもくだらなく思える',
            'そもそも自分以外のヒトがなんで大事なのかさっぱり分からない'
          ]
        ),
        'NAYA5' => DiceTable::Table.new(
          '悩みの詳細表・住/Home',
          '2D6',
          [
            '親がもううるさくない',
            '親がいない。奨学金とバイトで学費を稼がなければ学校にも通えない',
            '学校を卒業したら家を出ることになっている。でも、親元を離れたくない',
            '親の再婚相手と上手くいかない。何故かきつく当たってしまう',
            '親と同じ仕事を目指しているけど認めてくれない、夢を否定される',
            'お母さんが不治の病に侵されている',
            '家族の1人が家事が致命的に下手で家の内情がヤバい',
            '間違った場所に産まれてきた気がしてならない',
            '兄弟との仲が致命的に悪い。嫌われている',
            'ことあるごとに親が「おまえはどうしようもないやつだ」と言ってくる',
            '門限が早い'
          ]
        ),
      }.freeze

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d+NC', '\d+D6?([\+\-\d]*)>=\d+', TEXTS.keys, TABLES.keys)
    end
  end
end
