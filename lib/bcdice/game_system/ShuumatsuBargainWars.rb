# frozen_string_literal: true

module BCDice
  module GameSystem
    class ShuumatsuBargainWars < Base
      # ゲームシステムの識別子
      ID = "ShuumatsuBargainWars"

      # ゲームシステム名
      NAME = "終末買い物戦争"

      # ゲームシステム名の読みがな
      SORT_KEY = "しゆうまつはあけんうおおす"

      HELP_MESSAGE = <<~TEXT
        ・行為判定 （nBGk+y>=t）n:ダイス数、k:心根、y:修正値（省略可)、t:目標値
          例）3BG1>=3 2BG3+1>=4 4BG5-1>=3
        ・アイテム表
          ・RT 回復系アイテム表
          ・CT 便利系アイテム表
          ・WT 武器系アイテム表
          ・WG ワゴン(全アイテムランダム)
        ・ET イベント表
        ・TT トラブル表
      TEXT

      def initialize(command)
        super(command)
        @sort_barabara_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      RecoveryItemTable = DiceTable::D66Table.new(
        '回復系アイテム表',
        D66SortType::ASC,
        {
          11 => '飴玉',
          12 => 'エナジードリンク',
          13 => 'せんべい',
          14 => '餅',
          15 => 'ロウソク',
          16 => '酒',
          22 => '寿司',
          23 => 'ばんそうこう',
          24 => 'お布団',
          25 => 'カレー',
          26 => '消毒液',
          33 => '缶詰',
          34 => 'みたらし団子',
          35 => '骨付き肉',
          36 => 'ステーキ',
          44 => 'うちわ',
          45 => 'ぬいぐるみ',
          46 => 'のり',
          55 => '美容液',
          56 => '黄色いハンカチ',
          66 => '洗剤',
        }
      )

      ConvenienceItemTable = DiceTable::D66Table.new(
        '便利系アイテム表',
        D66SortType::ASC,
        {
          11 => 'ちくわ',
          12 => '焼き芋',
          13 => 'トイレットペーパー',
          14 => '熊手',
          15 => '胡椒',
          16 => '鏡',
          22 => '割りばし',
          23 => '輪ゴム',
          24 => '塩の結晶',
          25 => 'プチプチマット',
          26 => '長靴',
          33 => 'バケツ',
          34 => 'アルミホイル',
          35 => '下敷き',
          36 => '長芋',
          44 => '鉛筆',
          45 => 'まな板',
          46 => 'フライパン',
          55 => 'ほうき',
          56 => 'クラッカー',
          66 => '消臭スプレー',
        }
      )

      WeaponItemTable = DiceTable::D66Table.new(
        '武器系アイテム表',
        D66SortType::ASC,
        {
          11 => 'アズキアイス',
          12 => 'スプーン',
          13 => 'フォーク',
          14 => 'カミソリ',
          15 => '電池',
          16 => 'デッキブラシ',
          22 => '傘',
          23 => '物干し竿',
          24 => '鉄パイプ',
          25 => 'くぎ打ち機',
          26 => 'モンキーレンチ',
          33 => 'ハエタタキ',
          34 => '鎌',
          35 => '蛍光灯',
          36 => '包丁',
          44 => 'ハサミ',
          45 => 'ショベル',
          46 => '釣り竿',
          55 => '芝刈り機',
          56 => 'ステッキ',
          66 => '小麦粉',
        }
      )

      TABLES = {
        "ET" => DiceTable::Table.new(
          "イベント表",
          "2D6",
          [
            "ドッキン！一目惚れ！好きなキャラクターを1人選ぶ。このセッション中その相手との関係の深度を互いに3以上にすることができた場合、シナリオの結末に関係なく貴方は完全無欠のハッピーエンドを迎え経験点を100点得る。達成できなかった場合、エンディングフェイズで目が覚める。",
            "おや？こんな所にアイテムが転がっている。ランダムに選んだアイテムを獲得する。そのアイテムの種別が支援・計画ならば[技術]/5の判定に成功すれば手番を消費せずそのアイテムを使用しても良い。",
            "チームメンバーと二人っきりになる。ちょっといい雰囲気かも。好きなキャラクターを目標に選び、『関係』のチェックを外す事ができる。",
            "あぶな～い！チームメンバーに危機が襲い掛かる。PCの中からランダムに1人を選び[武力]/5の判定を行う。成功すると互いに『関係』を結ぶことができる。失敗すると2人とも体力に1d6点のダメージ。",
            "ちょっとお食事でも如何？自身の体力3点と活力1点を回復させる。",
            "穏やかな時が流れる。このメンバーならこれからも上手くやっていけそうだ。ランダムにPCを選び『関係』を獲得する。",
            "チームメンバーの意外な一面を覗く、まさかアイツあんな趣味があったなんて！PCの中からランダムで1人を選び[精神]/6で判定を行う。成功すると互いに『関係』を獲得する。失敗すると互いに活力が1点減少する。",
            "仲間と意見が対立する。アイツにだけは負けられない！関係を持つPCの中からランダムで1人を選び、対象との関係の深度を1下げてもよい（0未満にならない）。下げた場合、以降のセッション中任意の能力値が1上昇したものとして判定を行う事ができる。この効果で実際に能力値は上がらない。",
            "何かお手伝いをしよう。好きなキャラクターを1人選ぶ。この休憩中次に相手が判定を行う場合、その判定に修正値+1を加える。その後、目標は自分に対し『関係』を獲得する。",
            "酒を発見、宴だぁああ！！！PCは全員回復アイテムの「酒」の効果を使用できる。その後、自分の持つ全ての『関係』をランダムな相手に同じ《深度》で取り直す。",
            "不味い！敵襲だ！バナナワニにキリミウオが戦闘を仕掛けに来る。戦闘に勝利した場合、好きなアイテムを1つ得る。この処理が面倒ならば戦闘を行う代わりにPC達全員の体力の値を半分にし戦闘に勝利したものとして扱っても良い。"
          ]
        ),
        "TT" => DiceTable::Table.new(
          "トラブル表",
          "1D6",
          [
            "緊張感からか焦りが生じる。以降スポットフェイズに行くまでの間あらゆる判定の成功度が1減少する。",
            "カートの操作が効かなくなった！このラウンドは操作表を全員ダイスを振りランダムで決定する事。",
            "派手な振動が起き頭をぶつける。全員1d6点のダメージを受ける。",
            "集中力が切れて来た……全員の活力を1 点減少させる",
            "激しく揺さぶられ荷物が落下する。カート内にあるアイテムを1 つ選ぶ。そのアイテムを失う。",
            "不気味な超市場の雰囲気がパッセンジャー達の不安を煽る。特に何も起こらない。",
          ]
        ),
        "RT" => RecoveryItemTable,
        "CT" => ConvenienceItemTable,
        "WT" => WeaponItemTable,
        "WG" => DiceTable::ChainTable.new(
          "ワゴン",
          "1D6",
          [
            RecoveryItemTable,
            RecoveryItemTable,
            ConvenienceItemTable,
            ConvenienceItemTable,
            WeaponItemTable,
            WeaponItemTable,
          ]
        ),
      }.freeze

      register_prefix('\d+BG', TABLES.keys)

      def eval_game_system_specific_command(command)
        return roll_bg(command) || roll_tables(command, TABLES)
      end

      private

      def roll_bg(command)
        parser = Command::Parser.new("BG", round_type: @round_type)
                                .has_prefix_number
                                .has_suffix_number
                                .restrict_cmp_op_to(:>=)
        parsed = parser.parse(command)
        return nil unless parsed

        times = parsed.prefix_number
        kokorone = parsed.suffix_number
        correction = parsed.modify_number
        target = parsed.target_number
        dice_list = @randomizer.roll_barabara(times, 6).sort
        success = dice_list.count { |number| number >= target - correction }
        get_vitality = dice_list.count(kokorone)

        result =
          if dice_list.count(6) >= 2
            Result.critical("スペシャル！ 成功度#{success + 1}、活力#{get_vitality}獲得")
          elsif dice_list.all?(1)
            Result.fumble("ファンブル 活力をすべて失う")
          else
            Result.new("成功度#{success}、活力#{get_vitality}獲得")
          end

        result.text = "(#{parsed}) ＞ [#{dice_list.join(',')}] ＞ #{result.text}"

        return result
      end
    end
  end
end
