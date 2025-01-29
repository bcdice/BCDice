# frozen_string_literal: true

module BCDice
  module GameSystem
    class YankeeMustDie < Base
      # ゲームシステムの識別子
      ID = "YankeeMustDie"

      # ゲームシステム名
      NAME = "ヤンキーマストダイ"

      # ゲームシステム名の読みがな
      SORT_KEY = "やんきいますとたい"

      HELP_MESSAGE = <<~TEXT
        ■ 判定の方法
          基本形式：
          (YD+a>=b) または (YD+a>b)
          a：能力値、技能レベル、ドウグ等による修正値(複数指定可)
          b：目標となる成功段階

        ■ 成功の条件
          >=b：目標となる成功段階b以上の場合に成功となります。この条件では、目標となる成功段階と同じ数値でも成功とみなされます。
          >b：目標となる成功段階bより高い成功段階を出した場合に成功となります。この条件では、目標となる成功段階と同じ数値では失敗となります。

        ■ 各種表
        　関係表 RT
        　場面表 ST
        　ハプニング表 HT
        　闇堕ち表 DT
      TEXT

      def initialize(command)
        super(command)
        @sort_barabara_dice = true
        @sides_implicit_d = 10
      end

      def eval_game_system_specific_command(command)
        return check_action(command) || roll_tables(command, TABLES)
      end

      def check_action(command)
        parser = Command::Parser.new("YD", round_type: @round_type)
                                .restrict_cmp_op_to(:>=, :>, nil)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_all = []
        loop do
          dice_list = @randomizer.roll_barabara(3, 10).sort
          dice_all.push(dice_list)
          break unless dice_list.uniq.one?
        end

        achievement_value = dice_all.flatten.sum(parsed.modify_number)
        if achievement_value <= 9
          success_level = 0
        elsif achievement_value <= 19
          success_level = 1
        elsif achievement_value <= 29
          success_level = 2
        elsif achievement_value <= 39
          success_level = 3
        elsif achievement_value <= 49
          success_level = 4
        elsif achievement_value <= 59
          success_level = 5
        elsif achievement_value <= 69
          success_level = 6
        elsif achievement_value <= 79
          success_level = 7
        elsif achievement_value <= 89
          success_level = 8
        elsif achievement_value <= 99
          success_level = 9
        else
          success_level = 10
        end

        if parsed.cmp_op == :>
          is_success = success_level > parsed.target_number
          is_failure = !is_success
          success_message = is_success ? '成功' : '失敗'
        elsif parsed.cmp_op == :>=
          is_success = success_level >= parsed.target_number
          is_failure = !is_success
          success_message = is_success ? '成功' : '失敗'
        else
          is_success = false
          is_failure = false
          success_message = nil
        end

        dice_to_message_arr = []
        dice_all.each do |arr|
          dice_to_message_arr.append("#{arr.sum}[#{arr.join(',')}]")
        end

        sequence = [
          parsed.to_s,
          format("#{dice_to_message_arr.join(' + ')} %+d", parsed.modify_number),
          achievement_value,
          "成功段階#{success_level}"
        ]

        if success_message
          sequence.append(success_message)
        end

        Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          r.success = is_success
          r.failure = is_failure
        end
      end

      TABLES = {
        'RT' => DiceTable::Table.new(
          '関係表',
          '1D10',
          [
            'マブダチ：相手とは、マブダチ（親友） だ。いつからマブダチなのかはプレイヤー同士で相談して決めること。',
            '先輩／後輩：相手とは、先輩と後輩の間柄だ。なんの先輩後輩かはプレイヤー同士で相談して決めること。',
            '兄弟：相手とは、血縁であったり契りを交わした兄弟だ。兄弟になった経緯はプレイヤー同士で相談して決めること。',
            'ライバル：相手とは、良きライバル関係にある。どのようなライバル関係かはプレイヤー同士で相談して決めること。',
            '仲間：相手とは、同じチームなどに所属している仲間だ。どんなチームかはプレイヤー同士で相談して決めること。',
            'ジモティー：相手とは、同じ地元の仲間、幼馴染だ。いつから幼馴染なのかはプレイヤー同士で相談して決めること。',
            'おな中：相手とは、出身中学（小学校・高校も可） が同じだ。どんな中学だったのかはプレイヤー同士で決めること。',
            '相棒：相手は、唯一無二の相棒だ。いつから相棒なのかはプレイヤー同士で相談して決めること。',
            'ゾッコン：相手は、唯一無二の相棒だ。いつから相棒なのかはプレイヤー同士で相談して決めること。',
            '犬猿：相手とは、犬猿の仲である。犬猿の仲であるが、なぜ共に行動するのかはプレイヤー同士で相談して決めること。'
          ]
        ),
        'ST' => DiceTable::Table.new(
          '場面表',
          '1D10',
          [
            'サ店（喫茶店）',
            'クラブ',
            '工業団地',
            '神社／教会',
            '学校',
            '埠頭',
            '繁華街',
            'ゲーセン',
            '公園',
            '河原'
            # 特殊な場合のみ発生する
            # '病院'
          ]
        ),
        'HT' => DiceTable::Table.new(
          'ハプニング表',
          '1D10',
          [
            '単車ドロ：愛車を盗まれる。次の自身の手番を迎えるまで、愛車が１台使用不能になる。所有している愛車が複数ある場合はランダムに１台を選ぶ。',
            '職質：サツにドウグを取り上げられる。次の自身の手番を迎えるまで、素手を除くドウグが１つ使用不能になる。所有しているドウグが複数ある場合はランダムに１つを選ぶ。',
            '不調：どうにも愛車やドウグが体になじまない次の判定の成功段階がー１される。',
            '乱闘：不良との喧嘩に巻き込まれた。PC は1d10 点のダメージを受ける。',
            '大人：悪辣な大人に遭遇して怒りが募る。PC は不良度が1d10 点上昇する',
            '仲違い：つまらないことで喧嘩になって友情に亀裂が入る。場面に登場している【関係】を結んでいるキャラクターの中からランダムに対象を1 人選ぶ。シナリオが終了するまで対象との【関係】が失われる。',
            '悪名：ボスの悪名が広がることによって自然とボスの取り巻きが増える。次の戦闘フェイズにモブが敵として1 人参加する。モブの種類はGM が決定する。',
            '凶暴化：ボスの思考が先鋭化して凶悪になる。シナリオが終了するまでボスが与えるダメージを+2 する。この効果は累積するが、上昇した能力値は戦力には影響しない。',
            '警戒：ボスは自身の周りでうごめく不穏な気配に警戒を強める。ボスの【HP 最大値】と【HP 現在値】を+10 する。この効果は累積する。',
            '不運：ツキがなくなってきた気がする...。ラッキーナンバーの数値が２下がる（最低１）。すでにラッキーナンバーを使用済みであれば効果を受けない。'
          ]
        ),
        'DT' => DiceTable::Table.new(
          '闇堕ち表',
          '1D10',
          [
            '出奔：すべての人間関係を捨ててどこか遠くへ旅に出る。',
            '半グレ：半グレ集団とつるむようになり、悪事に手を染めるようになる。',
            '指名手配：重大な犯罪を起こして指名手配されて逃亡者となる。',
            '事故：大事故に遭い意識不明の重体となり長期入院する。',
            'ヤク中：薬物中毒者となり、薬を得るためなら何でもするようになる。',
            '借金：イカれた人間を信奉するようになり多額の借金を背負わされる。',
            '傀儡：悪意を持って人間を利用しようとする勢力に祭り上げられ傀儡と化す。',
            '身代わり：犯罪を犯した人間の身代わりにされて追われる身となる。',
            '逮捕：度を越えた暴力沙汰を度々起こして警察に逮捕される。',
            '失踪：ヤバい事件に首を突っ込んで謎の失踪を遂げる。'
          ]
        )
      }.freeze

      register_prefix('YD', TABLES.keys)
    end
  end
end
