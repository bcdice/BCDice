# frozen_string_literal: true

require "bcdice/dice_table/table"
require "bcdice/format"

module BCDice
  module GameSystem
    class TrinitySeven < Base
      # ゲームシステムの識別子
      ID = 'TrinitySeven'

      # ゲームシステム名
      NAME = 'トリニティセブンRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'とりにていせふんRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        クリティカルが変動した命中及び、7の出目がある場合のダメージ計算が行なえます。
        なお、通常の判定としても利用できます。

        ・発動/命中　［TR(±c*)<=(x)±(y*) 又は TR<=(x) など］*は必須ではない項目です。
        "TR(クリティカルの修正値*)<=(発動/命中)±(発動/命中の修正値*)"
        加算減算のみ修正値も付けられます。 ［修正値］は必須ではありません。
        例）TR<=50 TR<=60+20 TR7<=40 TR-7<=80 TR+10<=80+20

        ・ダメージ計算　［(x)DM(c*)±(y*) 又は (x)DM(c*) 又は (x)DM±(y*)］*は必須ではない項目です。
        "(ダイス数)DM(7の出目の数*)+(修正*)"
        加算減算のみ修正値も付けられます。 ［7の出目の数］および［修正値］は必須ではありません。
        例）6DM2+1 5DM2 4DM 3DM+3
        後から7の出目に変更する場合はC(7*6＋5)のように入力して計算してください。

        ・名前表　[TRNAME]
        名字と名前を出します。PCや突然現れたNPCの名付けにどうぞ。

      MESSAGETEXT

      register_prefix('\d+DM', 'TR', 'TRNAME')

      def eval_game_system_specific_command(command) # スパゲッティなコードだけど許して！！！ → 絶対に許さない。全力でリファクタリングした。
        debug("eval_game_system_specific_command command", command)

        roll_hit(command) ||
          roll_damage(command) ||
          roll_name(command)
      end

      def roll_hit(command)
        parser = Command::Parser.new(/TR\d*/, round_type: round_type)
                                .restrict_cmp_op_to(:<=)
        cmd = parser.parse(command)
        return nil unless cmd

        modify = cmd.command[2..-1].to_i + cmd.modify_number
        critical = 7 + modify
        target = cmd.target_number

        total = @randomizer.roll_once(100)
        result = get_hit_roll_result(total, target, critical)

        cmd.command = "TR"
        cmd.modify_number = modify

        result.text = "(#{cmd}) ＞ #{total} ＞ #{result.text}"
        debug("eval_game_system_specific_command result text", result.text)

        result
      end

      def get_hit_roll_result(total, target, critical)
        if total >= 96
          Result.fumble("ファンブル")
        elsif total <= critical
          Result.critical("クリティカル")
        elsif total <= target
          Result.success("成功")
        else
          Result.failure("失敗")
        end
      end

      def roll_damage(command)
        parser = Command::Parser.new(/\d+DM\d*/, round_type: round_type)
                                .restrict_cmp_op_to(nil)
        cmd = parser.parse(command)
        return nil unless cmd

        dice_count, critical = cmd.command.split("DM", 2).map(&:to_i)
        modify = cmd.modify_number

        dice_list = @randomizer.roll_barabara(dice_count, 6).sort
        dice_text = dice_list.join(",")

        total, additionalList = get_roll_damage_result(dice_count, critical, dice_list, modify)

        additionalListText = additionalList.nil? ? "" : "→[#{additionalList.join(',')}]"

        text = "(#{cmd}) ＞ [#{dice_text}]#{additionalListText}#{Format.modifier(modify)} ＞ #{total}"

        return text
      end

      def get_roll_damage_result(diceCount, critical, diceList, modify)
        if critical <= 0
          total = diceList.sum() + modify
          return total, nil
        end

        restDice = diceList.clone

        critical = diceCount if critical > diceCount

        critical.times do
          restDice.shift
          diceList.shift
          diceList.push(7)
        end

        max = restDice.pop
        max = 1 if max.nil?

        total = max * (7**critical) + restDice.sum() + modify

        return total, diceList
      end

      def result_1d100(_total, dice_total, _cmp_op, _target)
        if dice_total >= 96
          Result.fumble("ファンブル")
        elsif dice_total <= 7
          Result.critical("クリティカル")
        end
      end

      def roll_name(command)
        unless command == "TRNAME"
          return nil
        end

        first_name = NAME1.roll(@randomizer).last_body
        second_name = NAME2.roll(@randomizer).last_body

        text = "#{first_name} , #{second_name}"
        return text
      end

      NAME1 = DiceTable::Table.new(
        "名字表",
        "1D100",
        [
          '春日', # 1
          '浅見',
          '風間',
          '神無月',
          '倉田',
          '不動',
          '山奈',
          'シャルロック',
          '霧隠',
          '果心', # 10
          '今井',
          '長瀬',
          '明智',
          '風祭',
          '志貫',
          '一文字',
          '月夜野',
          '桜田門',
          '果瀬',
          '九十九', # 20
          '速水',
          '片桐',
          '葉月',
          'ウィンザー',
          '時雨里',
          '神城',
          '水際',
          '一ノ江',
          '仁藤',
          '北千住', # 30
          '西村',
          '諏訪',
          '藤宮',
          '御代',
          '橘',
          '霧生',
          '白石',
          '椎名',
          '綾小路',
          '二条', # 40
          '光明寺',
          '春秋',
          '雪見',
          '刀条院',
          'ランカスター',
          'ハクア',
          'エルタニア',
          'ハーネス',
          'アウグストゥス',
          '椎名町', # 50
          '鍵守',
          '茜ヶ崎',
          '鎮宮',
          '美柳',
          '鎖々塚',
          '櫻ノ杜',
          '鏡ヶ守',
          '輝井',
          '南陽',
          '雪乃城', # 60
          '六角屋',
          '鈴々',
          '東三条',
          '朱雀院',
          '青龍院',
          '白虎院',
          '玄武院',
          '麒麟院',
          'リーシュタット',
          'サンクチュアリ', # 70
          '六実',
          '須藤',
          'ミレニアム',
          '七里',
          '三枝',
          '八殿',
          '藤里',
          '久宝',
          '東',
          '赤西', # 80
          '神ヶ崎',
          'グランシア',
          'ダークブーレード',
          '天光寺',
          '月見里',
          '璃宮',
          '藤見澤',
          '赤聖',
          '姫宮',
          '華ノ宮', # 90
          '"天才"',
          '"達人"',
          '"賢者"',
          '"疾風"',
          '"海の"',
          '"最強"',
          '"凶器"',
          '"灼熱"',
          '"人間兵器"',
          '"魔王"', # 100
        ]
      )

      NAME2 = DiceTable::Table.new(
        "名字表",
        "1D100",
        [
          'アラタ/聖', # 1
          'アビィス/リリス',
          'ルーグ/レヴィ',
          'ラスト/アリン',
          'ソラ/ユイ',
          'イーリアス/アキオ',
          'アカーシャ/ミラ',
          'アリエス/リーゼロッテ',
          'ムラサメ/シャルム',
          '龍貴/竜姫',  # 10
          '英樹/春菜',
          '準一/湊',
          '急司郎/光理',
          '夕也/愛奈',
          '晴彦/アキ',
          '疾風/ヤシロ',
          'カガリ/灯花',
          '次郎/優都',
          '春太郎/静理',
          'ジン/時雨',  # 20
          'イオリ/伊織',
          'ユウヒ/優姫',
          'サツキ/翠名',
          'シュライ/サクラ',
          'ミナヅキ/姫乃',
          'カエデ/優樹菜',
          'ハル/フユ',
          'ドール/瑞江',
          'ニトゥレスト/キリカ',
          'スカー/綾瀬',  # 30
          '真夏/小夏',
          '光一/ののか',
          '彩/翠',
          'トウカ/柊花',
          '命/ミコト',
          '司/つかさ',
          'ゆとり/なごみ',
          '冬彦/観月',
          'カレン/華恋',
          '清次郎/亜矢',  # 40
          'サード/夢子',
          'ボックス/詩子',
          'ヘリオス/カエデ',
          'ゲート/京香',
          'オンリー/パトリシア',
          'ザッハーク/アーリ',
          'ラスタバン/ラスティ',
          '桜花/燁澄',
          '計都/リヴィア',
          'カルヴァリオ/香夜', # 50
          '悠人/夜々子',
          '太子/羽菜',
          '夕立/夕凪',
          'アルフ/愛美',
          'ファロス/灯利',
          'スプートニク/詩姫',
          'アーネスト/累',
          'ナイン/カグヤ',
          'クリア/ヒマワリ',
          'ウォーカー/オリビア', # 60
          'ダーク/クオン',
          'ウェイヴ/凛',
          'ルーン/マリエ',
          'エンギ/セイギ',
          'シラヌイ/ミライ',
          'ブライン/キズナ',
          'クロウ/カナタ',
          'スレイヤー/ヒカル',
          'レス/ミリアリア',
          'ミフユ/サリエル', # 70
          '鳴央/音央',
          'モンジ/理亜',
          'パルデモントゥム/スナオ',
          'ミシェル/詩穂',
          'フレンズ/サン',
          'サトリ/識',
          'ロード/唯花',
          'クロノス/久宝',
          'フィラデルフィア/冬海',
          'ティンダロス/美星',  # 80
          '勇弥/ユーリス',
          'エイト/アンジェラ',
          'サタン/ルシエル',
          'エース/小波',
          'セージ/胡蝶',
          '忍/千之',
          '重吾/キリコ',
          'マイケル/ミホシ',
          'カズマ/鶴香',
          'ヤマト/エリシエル',  # 90
          '歴史上の人物の名前（信長、ジャンヌなど）',
          'スポーツ選手の名前（ベッカム、沙保里など）',
          '学者の名前（ソクラテス、エレナなど）',
          'アイドルの名前（タクヤ、聖子など）',
          '土地、国、町の名前（イングランド、ワシントンなど）',
          'モンスターの名前（ドラゴン、ラミアなど）',
          '武器防具の名前（ソード、メイルなど）',
          '自然現象の名前（カザンハリケーンなど）',
          '機械の名前（洗濯機、テレビなど）',
          '目についた物の名前（シャーペン、メガネなど）', # 100
        ]
      )
    end
  end
end
