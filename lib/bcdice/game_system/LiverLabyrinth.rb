# frozen_string_literal: true

module BCDice
  module GameSystem
    class LiverLabyrinth < Base
      # ゲームシステムの識別子
      ID = 'LiverLabyrinth'

      # ゲームシステム名
      NAME = 'ライバー＆ラビリンス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'らいはああんとらひりんす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        同人TRPGシステム『ライバー＆ラビリンス』用ダイスボット。
        ・判定コマンド(xLL+y@c$d>=z)
          x：能力値
          +y：ダメージ判定時の攻撃力(省略可。省略時は0)
          c：クリティカル値(省略可。省略時は10)
          d：クリティカル時の加算値(省略可。省略時は1)
          z：難易度(4以下のとき5に。11以上は10になり、サイコロの数が減る）
          (例) 6LL@8>=6
               10LL>=5
               4LL+5@10$2>=10
        ・各種表 ：
            コマンド末尾に数字を入れると複数回の一括実行が可能　例）GETCT4
            コマンド末尾に"="(イコール)と数字を入れると、特定のダイス目の結果の実行が可能　例）CRITICALT=5
          ・クリティカル表(CriticalT)
          ・命中ファンブル表(FumbleT)
          ・致命傷表(FatalT)
          ・休憩表(RestT)
          ・痛恨表(TerribleT)
          ・お宝表(レベル1~4)(GetCT)
          ・お宝表(レベル5~8)(GetRT)
          ・お宝表(レベル9~14)(GetSRT)
          ・お宝表(レベル15~99)(GetURT)
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command begin string", command)

        return check_roll(command) || roll_table_command(command)
      end

      def check_roll(command)
        parser = Command::Parser.new("LL", round_type: RoundType::CEIL).has_prefix_number.enable_critical.enable_dollar.restrict_cmp_op_to(:>=)
        parsed = parser.parse(command)
        return nil if parsed.nil?

        dice_cnt = parsed.prefix_number
        modify = parsed.modify_number || 0
        critical_target = parsed.critical || 10
        critical_addition = parsed.dollar || 1

        target = parsed.target_number

        text = ""
        if target < 5
          text += "【#{command}】 ＞ あらゆる難易度は5未満にはならないため、難易度は5になる！\n"
          target = 5
        elsif target >= 11
          text += "【#{command}】 ＞ 難易度が11を超えたため、超過分、ダイスの数が減少！\n"
          over = target - 10
          target = 10
          dice_cnt -= over
        end

        dice_cnt = 0 if dice_cnt < 0

        text += "【ダイスの数#{dice_cnt}、難易度#{target}、クリティカル#{critical_target}#{critical_addition > 1 ? '(+' + critical_addition.to_s + ')' : ''}#{modify > 0 ? '、攻撃力' + modify.to_s : ''}】"

        dice_arr = @randomizer.roll_barabara(dice_cnt, 10)
        dice_count = dice_arr
                     .group_by(&:itself)
                     .transform_values(&:length)

        success_cnt = 0
        critical_cnt = 0

        dice_count.each do |v, count|
          next if count == 0

          if v >= target
            success_cnt += count
          end

          if v >= critical_target
            success_cnt += count * critical_addition
            critical_cnt += count
          end
        end

        dice_count_strs = (1..10).map do |v|
          count = dice_count.fetch(v, 0)
          next nil if count == 0

          "[#{v}]×#{dice_count.fetch(v, 0)}"
        end

        has_critical = critical_cnt >= 3
        has_fumble = dice_cnt > 0 && dice_count.fetch(1, 0) >= (dice_cnt.to_f / 2).ceil

        if has_fumble
          # ファンブルの場合、クリティカルは無視される
          has_critical = false
          success_cnt = 0
        end
        result = success_cnt > 0

        text += " ＞ #{dice_count_strs.compact.join(',')} ＞ 成功度#{success_cnt} ＞ #{result ? '成功' : '失敗'}#{has_critical ? '(クリティカル)' : ''}#{has_fumble ? '(ファンブル)' : ''}"

        if result && modify > 0
          text += " ＞ #{success_cnt + modify}ダメージ"
        end

        Result.new.tap do |r|
          r.text = text
          r.critical = has_critical
          r.fumble = has_fumble
          r.success = result
          r.failure = !result
        end
      end

      def roll_table_command(command)
        # サタスペのダイスボットを参考に実装
        command = command.upcase

        m = /([A-Z]+)(\d+)?(=)?(\d+)?/.match(command)
        return nil unless m

        table_name = m[1]
        table = TABLES[table_name]
        return nil if table.nil?

        counts = 1
        counts = m[2].to_i if m[2]
        operator = m[3]
        value = m[4].to_i

        return nil if !operator.nil? && value <= 0 || value >= 11

        result_texts = []

        counts.times do |_i|
          if operator == "=" && !value.nil?
            info = table.choice(value)
            text = "#{info.table_name}(#{value}) ＞ #{info.body}"
          else
            text = roll_tables(table_name, TABLES)
          end
          result_texts.push(text)
        end

        Result.new.tap do |r|
          r.text = result_texts.join("\n")
        end
      end

      ####################
      # 各種表

      TABLES = {
        "CRITICALT" => DiceTable::Table.new(
          "クリティカル表",
          "1d10",
          [
            "視聴者が沸き立つ一撃！閲覧数を1D10点増加させる。",
            "致命的な一撃！最終的に与えるダメージが2倍になる。",
            "肉体を変容させる一撃！ランダムで対象にバステを付与する。",
            "魔力の消費を最小限に抑えることに成功！最終的にこのアクションで消費する《EP》が0になる。",
            "取れ高発生！《トレダカ》を1点増加させる。",
            "相手の動きを阻害することに成功！対象の《行動値》を0にする。",
            "華麗に素材をゲット！《クレジット》を1D10点獲得する。",
            "狙いが的確に決まった！対象のスキル、アプリ、ツールのうちどれか一つ、この戦闘の間、使用不能にする。",
            "意識の外から刈り取る一撃！このアクションに対して、対象は防御判定を行えない。また、スキル、アプリ、ツールによるダメージ減少も無視する。",
            "次の動作への連携が決まる！次に行う自身のアクションのクリティカル値を2点減少させる。",
          ]
        ),
        "FUMBLET" => DiceTable::Table.new(
          "命中ファンブル表",
          "1d10",
          [
            "急にコメントが荒れて攻撃を外してしまう。「炎上」のバステを受ける。",
            "攻撃が自分に命中。1D10点のダメージを受ける（防御判定不可）",
            "アクション中に盛大にすっころぶ。「ストップ」のバステを受ける。",
            "アクションが大失敗。配信の空気が冷える。《トレダカ》が1点減少する。",
            "魔力の消費が爆増！このアクションで消費した《EP》を再度消費する。",
            "タンマツの調子が悪い。「オフライン」のバステを受ける。",
            "敵のカウンターを受ける。1D10点のダメージを受ける（防御判定不可）",
            "うっかり武器を落としてしまう。支援行動で武器を拾うまで、汎用アクション以外のアクションを行うことができない。",
            "仲間との連携に失敗。ランダムな味方一人の《EP》を1D10点減少する。",
            "攻撃は失敗だが、ネタとして大ウケ。《閲覧数》が1D10点増加する。",
          ]
        ),
        "FATALT" => DiceTable::Table.new(
          "致命傷表",
          "1d10",
          [
            "行動不能。ダンジョンに身体を侵食される。異形トロフィーを1つ獲得する。",
            "ドラマチックなやられ方で配信が盛り上がる。《閲覧数》が2D10点増加する。自身は行動不能になる。",
            "お前も道連れだ！自分にダメージを与えた対象に同じダメージを与える。このダメージ減少できない。自身は行動不能になる。",
            "奇跡が起きた！？〔幸運〕で難易度10の判定に成功すると受けたダメージを０にする。",
            "致命傷だがまだ動ける！《EP》を1にする。「スリップ」のバステを受ける。",
            "行動不能。ダンジョンに身体を侵食される。異形トロフィーを1つ獲得する。",
            "行動不能。だが、タンマツにはまだエネルギーが残っている。１ラウンド後、《EP》を1にして戦線に復帰する。",
            "走馬灯が過る！走馬灯に回避のアイデアが！〔反応〕で難易度10の判定に成功すると、受けたダメージを０にする。",
            "死んだかと思ったが、ギリギリのところで持ちこたえる。《EP》を1にする。",
            "行動不能。ダンジョンに身体を侵食される。異形トロフィーを1つ獲得する。",
          ]
        ),
        "RESTT" => DiceTable::Table.new(
          "休憩表",
          "1d10",
          [
            "辺りを探索すると、ツールを発見する。誰かがここに残していたのだろうか？お宝表(レベル1~4)を一回振る。",
            "希少な鉱床を発見。【ダンジョン資源(中級)】を一つ獲得。",
            "自身の存在が大きくブレる。任意のアクションを一つ、別のアクションに変更してもよい。",
            "素晴らしい戦術を思いつく。次回のバトルフェイズでの行動値判定で振ることができるダイスが１つ増える。",
            "視聴者の無茶振りについつい応えてしまう。調子に乗りすぎて体力が…。 《EP》が1D10点減少する。《トレダカ》を1点獲得。",
            "何気ない雑談配信。だが危うくリテラシーのない発言をしてしまい…。 〔魅力〕で難易度8の判定を行う。閲覧数が成功度分増加。判定に失敗した場合、「炎上」のバステを受ける。",
            "休憩の合間にネットサーフィン。うわ！なんか変なリンク踏んだ！？〔技術〕で難易度9の判定を行う。失敗した場合、「フリーズ」のバステを受ける。成功した場合、奇跡的に冒険者用の通販サイトに繋がる。買い物を行うことができる。",
            "急にタンマツのアプリのアップデートがはじまる。アップデートが重すぎて他の通信がうまくいかない！？〔幸運〕で難易度9の判定を行う。失敗した場合、「オフライン」のバステを受ける。成功した場合、タンマツのアプデが成功し、〔EP〕が全回復する。",
            "バッチリ熟睡。しっかりとした休憩を取ることができた。〔EP〕が2D10点回復する。",
            "やたら魔力の巡りがいい。絶好調ってやつか！？このセッションの間、すべての主能力が1点増加する。副能力の再計算を行うこと。",
          ]
        ),
        "TERRIBLET" => DiceTable::Table.new(
          "痛恨表",
          "1d10",
          [
            "脳が揺さぶられた！「ブライン」のバステを付与する。",
            "痛恨の一撃！最終的に与えるダメージが2倍になる。",
            "肉体の動きを阻害する一撃！対象の《行動値》を0にする。",
            "致命的な一撃！ダメージを与える代わりに、対象の《EP》を1にする。",
            "追撃を決められてしまった！ダメージを2D10点追加する。",
            "場外へ吹っ飛ばした！対象を戦場から取り除く。取り除かれた対象は、ラウンド終了時に最後尾に再配置する。",
            "悔しいが見栄えする一撃だ！《閲覧数》が1D10点増加する。",
            "衝撃が貫通する！アクションの対象になっていないキャラ1体を選択し、そのキャラにもダメージを与える。",
            "意識の外から刈り取る一撃！このアクションに対して、対象は防御判定を行えない。また、スキル、アプリ、ツールによるダメージ減少も無視する。",
            "魔力を奪う一撃！与えたダメージと同じ値だけ《EP》が回復する。",
          ]
        ),
        "GETCT" => DiceTable::Table.new(
          "お宝表(レベル1~4)",
          "1d10",
          [
            "携帯食料を1つ手に入れた！ ⇒54頁参照",
            "エアバッグを1つ手に入れた！ ⇒53頁参照",
            "携帯テントを1つ手に入れた！ ⇒54頁参照",
            "特効薬を1つ手に入れた！ ⇒52頁参照",
            "ダンジョン資源（低級）を1つ手に入れた！ ⇒55頁参照",
            "スモークボールを1つ手に入れた！ ⇒53頁参照",
            "ポーションを1つ手に入れた！ ⇒52頁参照",
            "クイックポーションを1つ手に入れた！ ⇒52頁参照",
            "ダンジョン資源（低級）を1つ手に入れた！ ⇒55頁参照",
            "素晴らしい戦果で配信が盛り上がる！現在の閲覧数が1D10点上昇する。",
          ]
        ),
        "GETRT" => DiceTable::Table.new(
          "お宝表(レベル5~8)",
          "1d10",
          [
            "携帯保健室を1つ手に入れた！ ⇒54頁参照",
            "マショウストーンを1つ手に入れた！ ⇒55頁参照",
            "ぬいぐるみ爆弾を1つ手に入れた！ ⇒54頁参照",
            "生命の粉塵を1つ手に入れた！ ⇒52頁参照",
            "ダンジョン資源（中級）を1つ手に入れた！ ⇒55頁参照",
            "パワーポーションを1つ手に入れた！ ⇒52頁参照",
            "クリティカッターを1つ手に入れた！ ⇒53頁参照",
            "ダンジョン資源（中級）を1つ手に入れた！ ⇒55頁参照",
            "ハイポーションを1つ手に入れた！ ⇒52頁参照",
            "素晴らしい戦果で配信が盛り上がる！現在の閲覧数が2D10点上昇する。",
          ]
        ),
        "GETSRT" => DiceTable::Table.new(
          "お宝表(レベル9~14)",
          "1d10",
          [
            "携帯食料を1つ手に入れた！ ⇒54頁参照",
            "フウマスリケンを1つ手に入れた！ ⇒55頁参照",
            "ダンジョン資源（上級）を1つ手に入れた！ ⇒55頁参照",
            "生命の粉塵を1つ手に入れた！ ⇒52頁参照",
            "コンティニューコインを1つ手に入れた！ ⇒52頁参照",
            "ダンジョン資源（低級）を1D10個手に入れた！ ⇒55頁参照",
            "フィリピンバクチクを1つ手に入れた！ ⇒55頁参照",
            "ダンジョン資源（上級）を1つ手に入れた！ ⇒55頁参照",
            "携帯病院を1つ手に入れた！ ⇒54頁参照",
            "素晴らしい戦果で配信が盛り上がる！現在の閲覧数が4D10点上昇する。",
          ]
        ),
        "GETURT" => DiceTable::Table.new(
          "お宝表(レベル15~99)",
          "1d10",
          [
            "ダンジョン資源（伝説）を1つ手に入れた！ ⇒55頁参照",
            "マショウストーンを1D10個手に入れた！ ⇒55頁参照",
            "エリキシルを1つ手に入れた！ ⇒54頁参照",
            "ダンジョン資源（伝説）を1つ手に入れた！ ⇒55頁参照",
            "盗賊の鍵を1つ手に入れた！ ⇒53頁参照",
            "コンティニューコインを1つ手に入れた！ ⇒52頁参照",
            "経験値を1つ手に入れた！ ⇒55頁参照",
            "ダイナマイトを1つ手に入れた！ ⇒55頁参照",
            "エリキシルを1つ手に入れた！ ⇒54頁参照",
            "素晴らしい戦果で配信が盛り上がる！現在の閲覧数が8D10点上昇する。",
          ]
        ),
      }.freeze

      register_prefix('\d+LL', TABLES.keys)
    end
  end
end
