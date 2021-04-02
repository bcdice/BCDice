# frozen_string_literal: true

require 'bcdice/game_system/beginning_idol/accessories_table'
require 'bcdice/game_system/beginning_idol/heart_step_table'
require 'bcdice/game_system/beginning_idol/work_table'
require 'bcdice/game_system/beginning_idol/world_setting_table'
require 'bcdice/game_system/beginning_idol/table'

module BCDice
  module GameSystem
    class BeginningIdol < Base
      # ゲームシステムの識別子
      ID = 'BeginningIdol'

      # ゲームシステム名
      NAME = 'ビギニングアイドル'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひきにんくあいとる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・パフォーマンス　[r]PDn[+m/-m](r：場に残った出目　n：振る数　m：修正値)
        ・ワールドセッティング仕事表　BWT：大手芸能プロ　LWT：弱小芸能プロ
        　TWT：ライブシアター　CWT：アイドル部　LO[n]：地方アイドル(n：チャンス)
        　SU：情熱の夏　WI：ぬくもりの冬　NA：大自然　GA：女学園　BA：アカデミー
        ・仕事表　WT　VA：バラエティ　MU：音楽関係　DR：ドラマ関係
        　VI：ビジュアル関係　SP：スポーツ　CHR：クリスマス　PAR：パートナー関係
        　SW：お菓子　AN：動物　MOV：映画　FA：ファンタジー
        ・ランダムイベント　RE
        ・ハプニング表　HA
        ・特技リスト　AT[n](n：分野No.)
        ・アイドルスキル修得表　SGT：チャレンジガールズ　RS：ロードトゥプリンス
        ・変調　BT[n](n：発生数)
        ・アイテム　IT[n](n：獲得数)
        ・アクセサリー　ACT：種別決定　ACB：ブランド決定　ACE：効果表
        ・衣装　DT：チャレンジガールズ　RC：ロードトゥプリンス　FC:フォーチュンスターズ
        ・無茶ぶり表　LUR：地方アイドル　SUR：情熱の夏　WUR：ぬくもりの冬
        　NUR：大自然　GUR：女学園　BUR：アカデミー
        ・センタールール　HW：向かい風シーン表　FL：駆け出しシーン表　LN：孤独表
        　マイスキル【MS：名前決定　MSE：効果表】　演出表【ST　FST：ファンタジー】
        ・合宿ルール　散策表【SH：ショッピングモール　MO：山　SEA：海　SPA：温泉街】
        　TN：夜語りシチュエーション表　成長表【CG：コモン　GG：ゴールド】
        ・サビ表　CHO　SCH：情熱の夏　WCH：ぬくもりの冬　NCH：大自然
        　GCH：女性向け　PCH：力強い
        ・キャラ空白表　CBT：チャレンジガールズ　RCB：ロードトゥプリンス
        ・趣味空白表　HBT：チャレンジガールズ　RHB：ロードトゥプリンス
        ・マスコット暴走表　RU
        ・アイドル熱湯風呂　nC：バーストタイム(n：温度)　BU：バースト表
        ・攻撃　n[S]A[r][+m/-m](n：振る数　S：失敗しない　r：取り除く出目　m：修正値)
        ・かんたんパーソン表　SIP
        ・会場表
        　BVT：大手芸能プロ　LVT：弱小芸能プロ　TVT：ライブシアター　CVT：アイドル部
        ・場所表
        　BST：大手芸能プロ　LST：弱小芸能プロ　TST：ライブシアター　CST：アイドル部
        ・プレッシャー種別決定表
        　BPT：大手芸能プロ　LPT：弱小芸能プロ　TPT：ライブシアター　CPT：アイドル部
        ・道具表
        　BIT：大手芸能プロ　LIT：弱小芸能プロ　TIT：ライブシアター　CIT：アイドル部
        []内は省略可　D66入れ替えあり
      INFO_MESSAGE_TEXT

      register_prefix(
        '[1-7]*PD',
        'HW',
        'BWT',
        'LWT',
        'TWT',
        'CWT',
        'LO',
        'SU',
        'WI',
        'NA',
        'GA',
        'BA',
        'WT',
        'VA',
        'MU',
        'DR',
        'VI',
        'SP',
        'CHR',
        'PAR',
        'SW',
        'AN',
        'MOV',
        'FA',
        'RE',
        'HA',
        'AT[1-6]?',
        'LUR',
        'SUR',
        'WUR',
        'NUR',
        'GUR',
        'BUR',
        'BT',
        'SGT',
        'RS',
        'SH',
        'MO',
        'SEA',
        'SPA',
        'TN',
        'CG',
        'GG',
        'FL',
        'LN',
        'MS',
        'MSE',
        'ST',
        'FST',
        'CHO',
        'SCH',
        'WCH',
        'NCH',
        'GCH',
        'PCH',
        'IT',
        'ACT',
        'ACB',
        'ACE',
        'DT',
        'RC',
        'FC',
        'CBT',
        'RCB',
        'HBT',
        'RHB',
        'RU',
        '\d{2}C',
        'BU',
        '\d+S?A',
        'SIP',
        'BVT',
        'LVT',
        'TVT',
        'CVT',
        'BST',
        'LST',
        'TST',
        'CST',
        'BPT',
        'LPT',
        'TPT',
        'CPT',
        'BIT',
        'LIT',
        'TIT',
        'CIT'
      )

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def check_nD6(total, dice_total, _dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        if dice_total <= 2
          " ＞ ファンブル(変調がランダムに1つ発生し、PCは【思い出】を1つ獲得する)"
        elsif dice_total >= 12
          " ＞ スペシャル！(PCは【思い出】を1つ獲得する)"
        elsif total >= target
          " ＞ 成功"
        else
          " ＞ 失敗"
        end
      end

      alias check_2D6 check_nD6

      def eval_game_system_specific_command(command)
        res = roll_work_table(command) ||
              roll_heart_step_table(command) ||
              roll_accessories_table(command) ||
              roll_world_setting_table(command) ||
              roll_other_table(command)
        return res if res

        case command
        when /^([1-7]*)PD(\d+)([+\-]\d+)?$/
          counts = Regexp.last_match(2).to_i
          return nil if counts <= 0

          residual = Regexp.last_match(1)
          adjust = Regexp.last_match(3).to_i

          return rollPerformance(counts, residual, adjust)

        when /^AT([1-6]?)$/
          value = Regexp.last_match(1).to_i
          return getSkillList(value)

        when /^BT(\d+)?$/
          counts = (Regexp.last_match(1) || 1).to_i
          return badStatus(counts)

        when /^IT(\d+)?$/
          counts = (Regexp.last_match(1) || 1).to_i
          return getItem(counts)

        when 'DT'
          return costume('衣装(チャレンジガールズ)')

        when 'RC'
          return costume('衣装(ロードトゥプリンス)')

        when 'FC'
          return costume('衣装(フォーチュンスターズ)')

        when /^(\d{2})C$/
          title = 'バーストタイム'
          degrees = Regexp.last_match(1).to_i
          counts = 6
          if (degrees < 45) || (degrees > 55)
            return nil
          elsif degrees <= 49
            counts = 3
          elsif degrees <= 52
            counts = 4
          elsif degrees <= 54
            counts = 5
          end

          dice_list = @randomizer.roll_barabara(counts, 6).sort
          total = dice_list.sum()
          dice = dice_list.join(",")
          total += degrees

          text = "#{title} ＞ #{degrees}+[#{dice}] ＞ #{total} ＞ "
          if total >= 80
            text += "Burst!\n「バースト表」を使用する。"
          elsif total >= 65
            string = "成功\n【獲得ファン人数】が2D6点上昇する。"
            if total >= 75
              string = "大#{string}\nPC全員が挑戦者ではない場合、自分以外のPCを一人指名する。指名されたPCは、新たな挑戦者として、【メンタル】を減少させずに「バーストタイム」を行う。"
            end
            text += string
          else
            text += '失敗'
          end
          return text

        when 'BU'
          title = 'バースト表'
          table = [
            "熱い！　熱い！\n【メンタル】が2点減少する。",
            "慌てて浴槽から出ようとしたが、足を滑らせて浴槽に落ちる。ウケたはいいが、とても熱い。\n【メンタル】が1D6点減少し、【獲得ファン人数】が3D6点上昇する。",
            "温かい目で見守っていた仲間の手を力いっぱい引っ張り、浴槽に引きずり込む。\n自分以外のPCを一人選ぶ。選ばれたPCは、【メンタル】を3点減少させ、「バーストタイム」を行う。",
            "あまりの熱さに浴槽へ入り損ねていたら、仲間の一人に叩き落とされる。\n【メンタル】を2点減少してから、PCを一人選ぶ。選んだPCに対する【理解度】が3点上昇し、チェックを外す。",
            "思い切って氷を頭から浴びる。クールダウン完了！\n【メンタル】を2点減少させることで、もう一度「バーストタイム」を行うことができる。",
            "熱湯風呂に入るための着替えに手間取ってしまい、急かされてしまう。結果、満足に着替えができなかった。\nこのライブフェイズの間、衣装の効果が無効化される。",
          ]
          return textFrom1D6Table(title, table)

        when /^(\d+)(S?)A([1-6]*)([+\-]\d+)?$/
          title = '攻撃'
          counts = Regexp.last_match(1).to_i
          return nil if counts <= 0

          sure = !Regexp.last_match(2).empty?
          remove = Regexp.last_match(3).each_char.map(&:to_i)
          adjust = Regexp.last_match(4)&.to_i
          adjust_str = Format.modifier(adjust)

          dice = @randomizer.roll_barabara(counts, 6).sort
          dice_str = dice.join(",")

          dice -= remove

          text = "#{title} ＞ [#{dice_str}]#{adjust_str} ＞ "

          unless (dice.count == counts) || dice.empty?
            text += "[#{dice.join(',')}]#{adjust_str} ＞ "
          end

          if sure || (dice.count == dice.uniq.count)
            total = adjust.to_i
            total += dice.sum()
            total = 0 if total < 0
            text += "#{total}ダメージ"
          else
            text += '失敗'
          end
          return text
        when 'SIP'
          title = 'かんたんパーソン表'
          table = [
            'テレビ番組に出て、ライブの宣伝をする。',
            'ラジオに出演して、ライブの宣伝をする。',
            '動画を配信して、ライブの宣伝をする。',
            'ライブの宣伝のために、街でビラ配りをする。',
            'ライブに人を集めるために、派手なパフォーマンスを街中でする。',
            'ライブの宣伝のために、あちこちを走り回る。',
          ]
          return textFrom1D6Table(title, table)
        end

        return nil
      end

      private

      def rollPerformance(counts, residual, adjust)
        title = 'パフォーマンス'

        string = ''
        string += '+' if adjust > 0
        string += adjust.to_s unless adjust == 0

        dice_list = @randomizer.roll_barabara(counts, 6).sort
        dice_str = dice_list.join(",")
        diceAll = dice_list.join("") + residual

        total = 0
        diceUse = []
        (1..7).each do |i|
          if diceAll.count(i.to_s) == 1
            total += i
            diceUse.push(i)
          end
        end

        text = " ＞ [#{dice_str}]"

        if residual.empty?
          text = "#{title}#{text}"
        else
          text = "シンフォニー#{text}"
        end

        unless residual.empty?
          text += ',[' + residual.split("").sort.join(",") + ']'
        end

        text += "#{string} ＞ "

        if total == 0
          if residual.empty?
            total = 10 + adjust
            text += "【ミラクル】#{total}"
          else
            total = 15 + adjust
            text += "【ミラクルシンクロ】#{total}＋シンフォニーを行った人数"
          end
        elsif (total == 21) && !diceUse.include?(7)
          unless residual.empty?
            text += '[' + diceUse.join(',') + "]#{string} ＞ "
          end
          total = 30 + adjust
          text += "【パーフェクトミラクル】#{total}"
        else
          unless residual.empty? && (diceUse.count == diceAll.length)
            text += '[' + diceUse.join(',') + "]#{string} ＞ "
          end
          total += adjust
          text += total.to_s
        end

        return text
      end

      def textFromD66Table(title, table, chance = '')
        dice = @randomizer.roll_d66(D66SortType::ASC)
        number, text, skill = table.assoc(dice)

        text, skill = checkChance(text, skill, chance)
        return "#{title} ＞ [#{number}] ＞ " + replaceBadStatus(text) + getSkillText(skill)
      end

      def checkChance(text, skill, chance)
        return text, skill if chance.empty?
        return text, skill unless text =~ /チャンスが(\d{1,2})以下ならオフ。/

        target = Regexp.last_match(1).to_i
        matchedText = Regexp.last_match(0)

        if target >= chance.to_i
          text = "オフ"
          skill = ''
        else
          text = text.gsub(matchedText, '')
          text = text.chomp
        end

        return text, skill
      end

      def textFrom1D6Table(title, table1, table2 = nil)
        text1, number1 = get_table_by_1d6(table1)

        text = "#{title} ＞ "
        if table2.nil?
          text += "[#{number1}] ＞ #{text1}"
        else
          text2, number2 = get_table_by_1d6(table2)
          text += "[#{number1},#{number2}] ＞ #{text1}#{text2}"
        end

        if /ランダムに決定した特技が指定特技のアイドルスキル\(身長分野、(属性|才能)分野、出身分野が出たら振り直し\)$/ =~ text
          category = Regexp.last_match(1)
          loop do
            skill = getSkillList()
            text += "\n#{skill}"
            break unless skill.include?("身長") || skill.include?(category) || skill.include?("出身")

            text += " ＞ 振り直し"
          end
        end

        return replaceBadStatus(text)
      end

      def getSkillList(field = 0)
        title = '特技リスト'
        table = [
          ['身長', ['～125', '131', '136', '141', '146', '156', '166', '171', '176', '180', '190～']],
          ['属性', ['エスニック', 'ダーク', 'セクシー', 'フェミニン', 'キュート', 'プレーン', 'パッション', 'ポップ', 'バーニング', 'クール', 'スター']],
          ['才能', ['異国文化', 'スタイル', '集中力', '胆力', '体力', '笑顔', '運動神経', '気配り', '学力', 'セレブ', '演技力']],
          ['キャラ', ['中二病', 'ミステリアス', 'マイペース', '軟派', '語尾', 'キャラ分野の空白', '元気', '硬派', '物腰丁寧', 'どじ', 'ばか']],
          ['趣味', ['オカルト', 'ペット', 'スポーツ', 'おしゃれ', '料理', '趣味分野の空白', 'ショッピング', 'ダンス', 'ゲーム', '音楽', 'アイドル']],
          ['出身', ['沖縄', '九州地方', '四国地方', '中国地方', '近畿地方', '中部地方', '関東地方', '北陸地方', '東北地方', '北海道', '海外']],
        ]

        number1 = 0
        if field == 0
          table, number1 = get_table_by_1d6(table)
        else
          table = table[field - 1]
        end

        fieldName, table = table
        skill, number2 = get_table_by_2d6(table)

        text = title
        if field == 0
          text += " ＞ [#{number1},#{number2}]"
        else
          text += "(#{fieldName}分野) ＞ [#{number2}]"
        end

        return "#{text} ＞ 《#{skill}／#{fieldName}#{number2}》"
      end

      def badStatus(counts = 1)
        title = '変調'
        table = [
          "「不穏な空気」　PCの【メンタル】が減少するとき、減少する数値が1点上昇する",
          "「微妙な距離感」　【理解度】が上昇しなくなる",
          "「ガラスの心」　PCのファンブル値が1点上昇する",
          "「怪我」　幕間のとき、プロデューサーは「回想」しか行えない",
          "「信じきれない」　PC全員の【理解度】を1点低いものとして扱う",
          "「すれ違い」　PCはアイテムの使用と、リザルトフェイズに「おねがい」をすることができなくなる",
        ]

        return '' if counts <= 0

        dice_list = @randomizer.roll_barabara(counts, 6).sort
        dice_str = dice_list.join(",")
        numbers = dice_list.uniq

        text = "#{title} ＞ [#{dice_str}] ＞ "
        occurrences = numbers.count

        if occurrences > 1
          text += "以下の#{occurrences}つが発生する。\n"
        end

        occurrences.times do |i|
          text += table[numbers[i] - 1] + "\n"
        end

        return text[0, text.length - 1]
      end

      def getSkillText(skill)
        return '' if skill.nil? || skill.empty?

        text = skill
        if /^AT([1-6]?)$/ =~ text
          text = getSkillList(Regexp.last_match(1).to_i)
        else
          text = "特技 : #{text}"
        end

        return "\n#{text}"
      end

      def setArrayFromD66Table(array, name, src, table)
        index = name.index(src)
        return if index.nil?

        dice = @randomizer.roll_d66(D66SortType::ASC)
        number, text, = table.assoc(dice)
        array.push([index, src, text, number])
      end

      def getItem(counts = 1)
        title = 'アイテム'
        table = [
          "スタミナドリンク",
          "トレーニングウェア",
          "ドリーミングシューズ",
          "キャラアイテム",
          "お菓子",
          "差し入れ",
        ]

        return '' if counts <= 0

        numbers = @randomizer.roll_barabara(counts, 6).sort
        unique = numbers.uniq

        text = "#{title} ＞ [#{numbers.join(',')}] ＞ "
        acquisitions = numbers.count
        kinds = unique.count

        kinds.times do |i|
          string = table[unique[i].to_i - 1]
          unless kinds == 1
            string = "「#{string}」"
          end

          text += string
          unless acquisitions == kinds
            text += numbers.count(unique[i]).to_s + 'つ'
          end
          text += 'と'
        end

        text = text.sub(/と$/, '')

        return text
      end

      def replaceBadStatus(text)
        return text unless /変調がランダムに(一|二|三)つ発生する。/ =~ text

        counts = 1
        case Regexp.last_match(1)
        when '二'
          counts = 2
        when '三'
          counts = 3
        end

        substitution = text.clone
        substitution = substitution.gsub(Regexp.last_match(0), '')
        substitution += "\n" unless substitution.empty? || /\n$/ =~ substitution

        return substitution + badStatus(counts)
      end

      def costume(title, brandOnly = false)
        table = []
        if title.include?('チャレンジガールズ')
          table = [
            [11, "１２＆８８\n自分の【パフォーマンス値】が決定したとき、その値を2点上昇する。"],
            [12, "Glow Up Princess\nパフォーマンスを行うとき、サイコロを追加で1つ振れる。"],
            [13, "しずく\nライブフェイズ開始時に、【メンタル】が5点上昇する。"],
            [14, "Pop☆Sweet\n自分の【メンタル】が上昇するとき、さらに1点上昇する。"],
            [15, "Ttype\n一芸突破をしても【メンタル】が減少しない。また、一芸突破をした時、達成値が1点上昇する。"],
            [16, "Vampire Story\nパフォーマンスの【パフォーマンス値】が10以上の場合、自分の【メンタル】が3点上昇する。"],
            [22, "Pure Mermaid\n【ビジュアル】の演目は、指定特技を《スタイル》に変更できる。指定特技が《スタイル》の演目では、【パフォーマンス値】が2点上昇する。"],
            [23, "I'm cute\nライブフェイズ開始時に【メンタル】が1点上昇する。幕間の開始時に能力値を1つ選ぶ。選ばれた能力値は、このライブフェイズの間、1点上昇する。"],
            [24, "No.1 Girl\n【パフォーマンス値】が決定するとき、【メンタル】を1点減少することで、【パフォーマンス値】が3点上昇する。"],
            [25, "Final Romance\n【ビジュアル】のパフォーマンスを行うとき、キャラクターを1人選ぶ。選んだキャラクターの自分に対する【理解度】と同じだけ、【パフォーマンス値】が上昇する。"],
            [26, "Prism Line\nパフォーマンス1回につき、1度だけパフォーマンスに使用したサイコロ1つを振り直すことができる。"],
            [33, "さーばんとさーびす\nシンフォニーを行うたびに、そのパフォーマンスの【パフォーマンス値】が3点上昇する。"],
            [34, "Travel Bag\n幕間に自分の【理解度】チェック1つを外すことができる。"],
            [35, "JewelC\n開幕演目と幕間にアイテムを1つ選んで獲得する。"],
            [36, "Sweet Girl\nパフォーマンスを行ったPCは、【メンタル】を2点上昇する。"],
            [44, "Satisfaction West\nミラクル、ミラクルシンクロ、パーフェクトミラクルが発生したとき【パフォーマンス値】を5点上昇する。"],
            [45, "Under Big Ben\n使用能力が【ボイス】のパフォーマンスの【パフォーマンス値】が10以上の場合、自分に対する【理解度】チェック1つを外すことができる。"],
            [46, "PIERO\n一芸突破の達成値が2点上昇する。"],
            [55, "甘々娘々\n使用能力が【ビジュアル】のパフォーマンスを行うとき、【パフォーマンス値】が3点上昇する。"],
            [56, "花鳥風月\nシンフォニーを行うとき、振るサイコロの数を1つ増やす、もしくは1つ減らすことができる。"],
            [66, "Jingle Bells\nリザルトフェイズに以下の効果が発生する。リザルトフェイズに、【獲得ファン人数】が1D6点上昇する。また、PC全員は、条件を満たしていなくても「お願い」をすることができる。"],
          ]
        elsif title.include?('ロードトゥプリンス')
          table = [
            [11, "Angel kiss\nパフォーマンスを行うとき、1の目が出たサイコロは取り除かれない。シンフォニーを行ったとき、1の目が出たサイコロをすべて取り除く。"],
            [12, "Pirate ship\n指定特技が属性分野の演目を行うとき、その指定特技を《セクシー／属性4》に変更することができる。"],
            [13, "ロードトゥプリンス\nミラクル、ミラクルシンクロ、パーフェクトミラクルが発生したとき、そのキャラクターは【メンタル】が10点上昇する。"],
            [14, "Princess Guardian\n自分以外のキャラクターの【メンタル】が0点になったときに、《気配り／才能9》で判定を行うことができる。この判定には、個性特技は使用できない。成功すると、そのキャラクターは、【獲得ファン人数】が半分にならない。"],
            [15, "Starlight TourS\nライブフェイズの間、演目を1つ選んで、指定特技を《スター／属性12》に変更できる。"],
            [16, "花鳥風月・裏\nライブフェイズ中、一度だけ場に残っているすべてのサイコロの目を反転（1なら6に、2なら5に、3なら4に）することができる。"],
            [22, "しくらま\n判定に使用したサイコロの目が7の場合、【メンタル】が7点上昇する。"],
            [23, "Chime\nミラクル、ミラクルシンクロ、パーフェクトミラクルが発生したとき、そのキャラクターはランダムにアイテムを1つ獲得する。"],
            [24, "砂上の光\nシンフォニーを行ったとき、シンフォニーを受けたキャラクターの【メンタル】が5点上昇する。"],
            [25, "Air by me\n幕間の開始時に、【メンタル】が5点上昇する。"],
            [26, "戦国ストリート\n演目の使用能力が【フィジカル】のとき、【パフォーマンス値】が2点上昇する。また、指定特技が《ダンス／趣味9》の場合、【パフォーマンス値】が2点上昇する。"],
            [33, "Wild man\n一芸突破の達成値が2点上昇する。ただし、スペシャルは発生しなくなる。"],
            [34, "Gray Stand\n【獲得ファン人数】が減少したとき、減少した値の半分（端数切り捨て）と同じ値だけ、【獲得ファン人数】が上昇する。"],
            [35, "トイ ARM\n演目の開始時に、2D6を振る。その結果が11以上の場合、この演目では【メンタル】が減少しない。"],
            [36, "white plan\nファンブルが発生しても変調を受けない。"],
            [44, "SINOBI\n開幕演目を行うとき、出ないことを選択することができる。"],
            [45, "V-X\nミラクルが発生したときの【パフォーマンス値】を15にできる。"],
            [46, "ドラゴンナックル\n幕間より後、PCが行うパフォーマンスの【パフォーマンス値】が4点上昇する。"],
            [55, "Halloween Magic\n後半PPによって【メンタル】が減少するとき、その値を4点減少する（最低0）。"],
            [56, "Satisfaction East\n【獲得ファン人数】が減少したとき、【メンタル】を20点にすることができる。"],
            [66, "Devil kiss\nパフォーマンスを行うとき、6の目が出たサイコロは取り除かれない。シンフォニーを行ったとき、6の目が出たサイコロをすべて取り除く。"],
          ]
        elsif title.include?('フォーチュンスターズ')
          table = [
            [11, "常峰製作所\n第一演目では、【メンタル】が減少しない。"],
            [12, "フォーチュンスター\n最終演目の【パフォーマンス値】が「【メンタル】÷2（端数切り捨て）」点上昇する。"],
            [13, "ファイタースケイル\n【メンタル】が5点以下の場合、【パフォーマンス値】が1D6点上昇する。"],
            [14, "Blood Scissors\n自分以外のキャラクター一人の【メンタル】を5点減少するか、プロデューサーに変調「怪我」を与えることで、自分の【メンタル】が5点上昇する。この効果は、プロデューサーが既に「怪我」の変調を受けていると、使用できない。"],
            [15, "蒸気式演技服\n判定を行うとき、【メンタル】を1点消費することで、判定の達成値が1点上昇する。"],
            [16, "ウェイトスター\n「スタミナドリンク」によって、他のキャラクターの【メンタル】を上昇する場合、さらに4点上昇する。"],
            [22, "Little Stage\n判定のサイコロやパフォーマンスで「1」の出目が1つ以上出た場合、【思い出】を1つ獲得する。"],
            [23, "Check It\n開幕演目前に、最終演目以外の好きな演目を指定する。指定された演目では、自分の【メンタル】が減少しない。"],
            [24, "12 Sword\nアイドル戦闘ルールを使用しているとき、与えるダメージが3点上昇し、上昇する【獲得ファン人数】が5点上昇する。"],
            [25, "Magi Magic\nパフォーマンスや自分が行うシンフォニーでサイコロを取り除くたびに、【メンタル】が2点上昇する。"],
            [26, "Jokers\n最終演目に行う一芸突破の目標値が3点減少する。"],
            [33, "Papillon Club\n自分以外のキャラクターがタイプが「補助」のアイドルスキルを使用するたびに、【メンタル】が3点上昇する。"],
            [34, "ネイキッドチャレンジ\n開幕演目開始時に、【メンタル】が5点減少する。このライブフェイズの間、好きな能力値が3点上昇する。"],
            [35, "Cold Vivit\n好きなギャップを1つ埋める。このギャップは、ライブフェイズ終了時に元に戻る。"],
            [36, "対魔絶伏\n特別な演目では、【メンタル】が減少しない。"],
            [44, "Rescue Power\n演目の判定でファンブルが発生した場合、好きな能力値でパフォーマンスを行うことができる。"],
            [45, "アニマルエンジン\n幕間の終了時に、好きな動物からの【理解度】が2点上昇する。"],
            [46, "ふわふわキッチン\n好きなときに、「お菓子」を一つ消費することで、好きなキャラクターの【メンタル】が1D6点上昇できる。また、幕間に「お菓子」を1つ獲得する。"],
            [55, "Night Talk\n幕間で「信用」を行ったとき、上昇する【メンタル】が10点になる。"],
            [56, "ティーチングタイム\n自分以外のキャラクターを1人指定する。このライブフェイズの間、指定されたPCの能力値が1点上昇する。"],
            [66, "See Diver\n演目名に「海」「水」「泡」「湖」「風呂」を含む演目を行った場合、【獲得ファン人数】が1D6点上昇する。"],
          ]
        else
          return nil
        end

        text = textFromD66Table(title, table)
        text = text.split("\n").first if brandOnly
        return text
      end
    end
  end
end
