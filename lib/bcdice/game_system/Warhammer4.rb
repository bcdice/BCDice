# frozen_string_literal: true

module BCDice
  module GameSystem
    class Warhammer4 < Base
      # ゲームシステムの識別子
      ID = 'Warhammer4'

      # ゲームシステム名
      NAME = 'ウォーハンマーRPG第4版'

      # ゲームシステム名の読みがな
      SORT_KEY = 'うおおはんまあ4'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・クリティカル表(whctH/whctA/whctB/whctL//whctHU/whctAU/whctBU/whctLU)
        　"WH部位 頑健ボーナス以下フラグ"の形で指定します。
        　部位は「H(頭部)」「A(腕)」「B(胴体)」「L(足)」の４カ所です。
        　頑健ボーナスフラグは頑健ボーナス以下のダメージの時にUをつけます。
        　例）whH whAU WHL
        ・命中部位表(WHLT)
        　"WHLT"の形で指定します。
        　命中部位をランダムに決め、表示します。(クリティカル用)
        ・やっちまった！表(WHFT)
        　"WHFT"の形で指定します。
        　やっちまった！表をロールして、結果を表示します。
        ・命中判定(WHx)
        　"WH(命中値)"の形で指定します。
        　命中判定を行って、命中してクリティカルでなければ部位も表示します。
        　例）wh60　　wh(43-20)
      INFO_MESSAGE_TEXT

      register_prefix('WH')

      def initialize(command)
        super(command)

        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        roll_critical_table(command) || roll_attack(command) || roll_tables(command, TABLES)
      end

      def check_1D100(total, _dice_total, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :<=

        t10 = (total / 10).to_i
        d10 = (target / 10).to_i
        sl = d10 - t10

        output = ""
        if total <= 5
          sl = 1 if sl < 1
          output = " ＞ 自動成功(SL+#{sl})"

        elsif total >= 96
          sl = -1 if sl > -1
          output = " ＞ 自動失敗(SL#{sl})"

        elsif total <= target
          output = " ＞ 成功(SL+#{sl})"

        else
          if sl == 0
            output = " ＞ 失敗(SL+#{sl})"
          else
            output = " ＞ 失敗(SL#{sl})"
          end
        end

        # テスト結果表
        if sl == 0
          if total <= 5
            output += ' ＞ 小成功'
          elsif total >= 96
            output += ' ＞ 小失敗'
          elsif total <= target
            output += ' ＞ 小成功'
          else
            output += ' ＞ 小失敗'
          end
        elsif sl >= 6
          output += ' ＞ 超大成功'
        elsif sl >= 4
          output += ' ＞ 大成功'
        elsif sl >= 2
          output += ' ＞ 成功'
        elsif sl > 0
          output += ' ＞ 小成功'
        elsif sl >= -1
          output += ' ＞ 小失敗'
        elsif sl >= -3
          output += ' ＞ 失敗'
        elsif sl >= -5
          output += ' ＞ 大失敗'
        elsif sl <= -6
          output += ' ＞ 超大失敗'
        end
        return output
      end

      private

      # クリティカル表
      def roll_critical_table(command)
        m = /^WHCT([HABTL])(U)?$/.match(command)
        return nil unless m

        part = m[1]
        part = "B" if part == "T"

        under_ganken_bonus = !m[2].nil?

        CRITICAL_TABLES[part].roll(@randomizer, under_ganken_bonus)
      end

      class CriticalTable
        def initialize(name, items)
          @name = name
          @items = items
        end

        def roll(randomizer, under_ganken_bonus)
          dice = randomizer.roll_once(100)
          if under_ganken_bonus
            dice = (dice-20).clamp(1, 100)
          end

          chosen = @items.find {|key, _| key >= dice }[1]

          "#{@name}(#{dice}) ＞ #{chosen}"
        end
      end

      CRITICAL_TABLES = {
        "H" => CriticalTable.new(
          "頭部CT表",
          [
            [10, '勲章となる傷：耐久値-1：「出血状態」1つを得る。社交系テストSL+1(累積なし)。'],
            [20, '小さな裂傷：耐久値-1：「出血状態」1つを得る。'],
            [25, '眼窩の負傷：耐久値-1：「目がくらんだ状態」1つを得る。'],
            [30, '耳朶への強打：耐久値-1：「耳鳴り状態」1つを得る。'],
            [35, '朦朧化打撃：耐久値-2：「朦朧状態」1つを得る。'],
            [40, '眼の周りの青あざ：耐久値-2：「目がくらんだ状態」2つを得る。'],
            [45, '耳朶の裂傷：耐久値-2：「出血状態」2つに加えて、「耳鳴り状態」1つを得る。'],
            [50, '額への一打：耐久値-2：「出血状態」2つに加えて「目がくらんだ状態」1つを得る。なお後者は「出血状態」を取り除いた後でなければ取り除けない。'],
            [55, '顎骨折：耐久値-3：「朦朧状態」2つを得る。さらに「骨折(軽度)」の負傷を得る。'],
            [60, '眼窩の大怪我：耐久値-3：「出血状態」2つを得る。さらに「目がくらんだ状態」1つも得て、こちらは「治療行為」を受けない限り回復できない。'],
            [65, '耳朶の大怪我：耐久値-3：片耳の聴力を失う。聴覚に関するテストに-20。この効果をもう一度受けた場合、永続的な聴覚喪失者となる。これは魔法でしか治療できない。'],
            [70, '鼻砕き：耐久値-3：「出血状態」2つを得る。「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したら「朦朧状態」1つも得る。社交系テストに+1/-1。'],
            [75, '顎粉砕：耐久値-4：「朦朧状態」3つを得る。「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したら「気絶状態」を得る。「骨折(重度)」の負傷を得る。'],
            [80, '脳震盪打撃：耐久値-4：「出血状態」2つと「耳鳴り状態」1つに加えて1d10の「朦朧状態」を得る。さらに1d10日間継続する「疲労状態」1つも得る。この「疲労状態」継続中に頭部への「致命的負傷」を再度得たなら、「普通(+20)」の〈肉体抵抗〉テストを行い、失敗したなら追加で「気絶状態」になる。'],
            [85, '口粉砕：耐久値-4：「出血状態」2つを得る。1d10本の歯が失われる。「身体欠損(容易)」を被る。'],
            [90, '耳が屑肉に：耐久値-4：「耳鳴り状態」3つに加えて「出血状態」2つを得る。片耳の機能を失う。「身体欠損(普通)」を被る。'],
            [93, '眼球破裂：耐久値-5：「目がくらんだ状態」3つと、「出血状態」2つ、「朦朧状態」1つを得る。片目の機能を失う。「身体欠損(難しい)」を被る。'],
            [96, '顔が化け物のように：耐久値-5：「出血状態」3つ「目がくらんだ状態」3つ、「朦朧状態」2つを得る。片目の機能を失い、鼻梁も失う。「身体欠損(多難)」を被る。'],
            [99, '顎が屑肉に：耐久値-5：「出血状態」4つと「朦朧状態」3つを得る。「超多難(-30)」な〈肉体抵抗〉テストを行い、失敗したら「気絶状態」になる。「骨折(重度)」の負傷を得て、舌と1d10本の歯を失う。「身体欠損(多難)」を被る。'],
            [100, '斬首刑さながらに：即死：'],
          ]
        ),
        "A" => CriticalTable.new(
          "腕部CT表",
          [
            [10, '腕痺れ：耐久値-1：手に持っているものを落としてしまう。'],
            [20, '小さな裂傷：耐久値-1：「出血状態」1つを得る。'],
            [25, '捻挫：耐久値-1：「筋断裂(軽度)」の負傷を得る。'],
            [30, 'ひどい腕痺れ：耐久値-2：手に持っているものを落としてしまい、その腕は1d10-【頑健力】ボーナスのラウンドに渡って使えなくなる。'],
            [35, '筋断裂：耐久値-2：「出血状態」1つと、「筋断裂(軽度)」の負傷を得る。'],
            [40, '手の出血：耐久値-2：「出血状態」1つを得る。その手で何かを握る「アクション」を行う場合、先立って「普通(+20)」の【器用度】テストを行い、失敗したら取り落としてしまう。'],
            [45, '肩の捻挫：耐久値-2：手に持っているものを落としてしまい、その腕は1d10ラウンドに渡って使えなくなる。'],
            [50, '大きな傷口：耐久値-3：「出血状態」2つを得る。傷口を縫う「手術」を受ける前に同じ腕にダメージを受けた場合、傷口が開き「出血状態」1つを追加で得る。'],
            [55, '単純骨折：耐久値-3：手に持っているものを落としてしまい、「骨折(軽度)」の負傷を得る。「難しい(-10)」〈肉体抵抗〉テストを行い、失敗したなら「朦朧状態」1つを得る。'],
            [60, '靱帯断裂：耐久値-3：手に持っているものを落としてしまい、「筋断裂(重度)」の負傷を得る。'],
            [65, '深手：耐久値-3：「出血状態」2つを得る。「朦朧状態」1つを得て、「筋断裂(軽度)」の負傷を得る。「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「気絶状態」になる。'],
            [70, '動脈破損：耐久値-4：「出血状態」4つを得る。「手術」を受ける前に同じ腕にダメージを受けるたびに「出血状態」2つを得る。'],
            [75, '肘粉砕：耐久値-4：手に持っているものを落としてしまい、「筋断裂(重度)」の負傷を得る。'],
            [80, '肩の脱臼：耐久値-4：「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「朦朧状態」1つを得て「伏せ状態」になる。手に持っているものを落としてしまう。その腕を使うことはできず、欠損したものとして扱う。さらに「治療行為」を受けるまでの間「朦朧状態」1つを得る。'],
            [85, '指切断：耐久値-4：「身体欠損(普通)」を被る。「出血状態」1つを得る。'],
            [90, '手の半切断：耐久値-5：指一本を失い、「身体欠損(多難)」を被る。「出血状態」2つと「朦朧状態」1つを得る。君が「治療行為」を受けるまでの以降の各ラウンドに指を一本ずつ失う。すべての指を失ったら、その手の機能を失い「身体欠損(難しい)」を得る。'],
            [93, '力こぶがズタズタに：耐久値-5：手に持っていたものを落とすとともに「筋断裂(重度)」の負傷を得て、「出血状態」2つと「朦朧状態」1つを得る。'],
            [96, '片手が屑肉同然に：耐久値-5：その手の機能を失い、「身体欠損(多難)」を被る。「出血状態」2つを得る。「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「気絶状態」になる。'],
            [99, '靱帯断裂：耐久値-5：腕は無用の長物と化す―「身体欠損(超多難)」を被る。「出血状態」3つ、「朦朧状態」1つを得て、「伏せ状態」になる。「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「気絶状態」になる。'],
            [100, '残酷な腕の喪失：即死：'],
          ]
        ),
        "B" => CriticalTable.new(
          "胴体CT表",
          [
            [10, 'ただのかすり傷だって！：耐久値-1：「出血状態」1つを得る。'],
            [20, 'みぞおちへの一打：耐久値-1：「朦朧状態」1つを得る。「容易(+40)」な〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」になる。'],
            [25, '下腹部に直撃！：耐久値-1：「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「朦朧状態」3つを得る。'],
            [30, '背中を捻じる：耐久値-1：「筋断裂(軽度)」の負傷を得る。'],
            [35, '息ができない：耐久値-2：「朦朧状態」1つを得る。「普通(+20)」の〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」になる。また、1d10ラウンドに渡って「移動力」が半分になる。'],
            [40, '肋骨に青あざ：耐久値-2：1d10日間に渡って【敏捷力】に関連するテストに-10。'],
            [45, '鎖骨捻じれ：耐久値-2：左右どちらの鎖骨かランダムに決定する。そちらの手に持っている物を落としてしまい、1d10ラウンドに渡ってその腕は使用できない。'],
            [50, '裂傷：耐久値-2：「出血状態」2つを得る。'],
            [55, '肋骨にひびが：耐久値-3：「朦朧状態」1つを得る。また、「骨折(軽度)」の負傷を得る。'],
            [60, '大きな傷口：耐久値-3：「出血状態」3つを得る。「手術」を受けるまでの間、胴体に命中を受けるたびに追加で1つの「出血状態」を得る。'],
            [65, '激痛を伴う裂傷：耐久値-3：「出血状態」2つと「朦朧状態」1つを得る。「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「気絶状態」になる。またSL+4以上でテストに成功していない限り、金切り声を上げてしまう。'],
            [70, '動脈損傷：耐久値-3：「出血状態」4つを得る。「手術」を受けるまでの間、胴体に攻撃を受けるたびに追加で2つの「出血状態」を得る。'],
            [75, '背筋断裂：耐久値-4：「筋断裂(重度)」の負傷を得る。'],
            [80, '股関節骨折：耐久値-4：「朦朧状態」1つを得る。「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」にもなる。「骨折(軽度)」の負傷を得る。'],
            [85, '胸郭の大怪我：耐久値-4：「出血状態」4つを得る。「手術」を受けるまでの間、胴体に命中を受けるたびに追加で2つの「出血状態」を得る。'],
            [90, '内臓の損傷：耐久値-4：「膿み傷」に罹患し、「出血状態」2つを得る。'],
            [93, '胸郭粉砕：耐久値-5：「朦朧状態」1つを得る。これは「治療行為」を受けない限り取り除くことは出来ない。さらに「骨折(重度)」の負傷を得る。'],
            [96, '鎖骨粉砕：耐久値-5：「気絶状態」になる。これは「治療行為」を受けない限り取り除くことは出来ない。さらに「骨折(重度)」の負傷を得る。'],
            [99, '内臓出血：耐久値-5：「出血状態」1つを得る。これは「手術」を受けない限り取り除くことは出来ない。さらに「血液腐れ病」に罹患する。'],
            [100, '胴部両断：即死：'],
          ]
        ),
        "L" => CriticalTable.new(
          "脚部CT表",
          [
            [10, '爪先をぶつける：耐久値-1：「普通(+20)」の〈肉体抵抗〉テストを行い、失敗したなら次のターンの終了時まで【敏捷力】に関するテストに-10。'],
            [20, '足首の捻挫：耐久値-1：以降1d10ラウンドに渡って【敏捷力】に関連するテストに-10。'],
            [25, '小さな裂傷：耐久値-1：「出血状態」1つを得る。'],
            [30, '足がかりを失う：耐久値-1：「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」になる。'],
            [35, '太腿への打撃：耐久値-2：「出血状態」1つを得て「普通(+20)」の〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」になる。'],
            [40, '足首の筋断裂：耐久値-2：「筋断裂(軽度)」の負傷を得る。'],
            [45, '膝の捻挫：耐久値-2：以降1d10ラウンドに渡って【敏捷力】に関連するテストに-20。'],
            [50, '爪先のひどい裂傷：耐久値-2：「出血状態」1つを得る。「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したなら片方の爪先を失う―「身体欠損(普通)」を被る。'],
            [55, 'ひどい裂傷：耐久値-3：「出血状態」2つを得る。「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」になる。'],
            [60, '膝のひどい捻挫：耐久値-3：「筋断裂(重度)」の負傷を得る。'],
            [65, '脚への痛打：耐久値-3：「伏せ状態」に加えて「出血状態」2つを得て、「骨折(軽度)」の負傷を得る。さらに「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「朦朧状態」1つを追加で得る。'],
            [70, '太腿への深手：耐久値-3：「出血状態」3つを得る。「手強い(+0)」〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」になる。「手術」を受けるまでの間、この脚に命中を受けるたびに、追加で1つの「出血状態」を得る。'],
            [75, '靱帯断裂：耐久値-4：「伏せ状態」に加えて「朦朧状態」1つを得る。「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「気絶状態」になる。君のその脚は使えなくなる。'],
            [80, '脛への深手：耐久値-4：敵の武器が君の膝下に当たり、骨に食い込んで腱を切断する。「朦朧状態」1つを得て、「伏せ状態」になる。さらに「筋断裂(重度)」と「骨折(軽度)」の負傷を得る。'],
            [85, '膝粉砕：耐久値-4：「出血状態」1つと「朦朧状態」1つを得ることに加えて、「伏せ状態」になる。「骨折(重度)」の負傷を得る。'],
            [90, '膝関節脱臼：耐久値-4：「伏せ状態」になる。「多難(-20)」な〈肉体抵抗〉テストを行い、失敗したなら「朦朧状態」1つを得る。これは「治療行為」を受けない限り取り除くことができない。'],
            [93, '脚粉砕：耐久値-5：「普通(+20)」の〈肉体抵抗〉テストを行い、失敗したなら「伏せ状態」を得て、足の指1本を失う。さら、SLが-1あるごとに追加で1つの足指を失う―「身体欠損(普通)」を被る。「出血状態」2つを得る。'],
            [96, '足切断：耐久値-5：「身体欠損(多難)」を被る。「出血状態」3つと「朦朧状態」2つを得て「伏せ状態」になる。'],
            [99, 'アキレス腱切断：耐久値-5：苦痛に金切り声を上げながら倒れる。「出血状態」2つと「朦朧状態」2つを得て「伏せ状態」になる。「身体欠損(超多難)」を被る。'],
            [100, '骨盤粉砕：即死：'],
          ]
        ),
      }.freeze

      # 命中判定
      def roll_attack(command)
        m = /^WH(\d+)$/.match(command)
        return nil unless m

        target_number = m[1].to_i
        total = @randomizer.roll_once(100)
        result = check_1D100(total, total, :<=, target_number).delete_prefix(" ＞ ")

        sequence = [
          "(#{command})",
          total,
          result,
          additional_result(total, target_number),
        ].compact

        return sequence.join(" ＞ ")
      end

      def additional_result(total, target_number)
        tens, ones = split_d100(total)
        result =
          if (total > target_number) || (total > 95) # 自動失敗時のファンブル処理も
            if ones == tens
              "ファンブル"
            end
          elsif ones == tens
            "クリティカル"
          else
            # 一の位と十の位を入れ替えて参照する
            HIT_PARTS_TABLE.fetch(merge_d100(ones, tens)).content
          end

        result
      end

      def split_d100(dice)
        if dice == 100
          return 0, 0
        else
          return dice / 10, dice % 10
        end
      end

      def merge_d100(tens, ones)
        if tens == 0 && ones == 0
          100
        else
          tens * 10 + ones
        end
      end

      HIT_PARTS_TABLE = DiceTable::RangeTable.new(
        "命中部位表",
        "1D100",
        [
          # [0, '二足'],
          [1..9, '頭部'],
          [10..24, '左腕(逆腕)'],
          [25..44, '右腕(利腕)'],
          [45..79, '胴体'],
          [80..89, '左脚'],
          [90..100, '右脚'],
        ]
      )

      TABLES = {
        "WHLT" => HIT_PARTS_TABLE,
        "WHFT" => DiceTable::RangeTable.new(
          "やっちまった！表",
          "1D100",
          [
            [1..20, '君は自分の体の一部に当ててしまった。「耐久度」1点を失う。'],
            [21..40, '君の武器が1ダメージを受ける。次のラウンドの行動順が一番最後になる。'],
            [41..60, '君は身体動作の目算を誤る。次のラウンドのアクションに-10。'],
            [61..70, '君はひどく躓きバランスを回復するのに手間取る。次の「移動」を失う。'],
            [71..80, '君は武器を取り回しを誤る。次の「アクション」を失う。'],
            [81..90, '君は筋を違えるか、足首をひねってしまう。「筋断裂(軽度)」の負傷を得る。「致命的負傷」としてカウントされる。'],
            [91..100, '君は射程内のランダムな味方を攻撃してしまう。命中判定の出目の1の位をSLとして用いること。攻撃可能な味方が居ない場合は、自己を攻撃ししまい「朦朧状態」1つを得る。'],
          ]
        )
      }.freeze
    end
  end
end
