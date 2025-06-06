# frozen_string_literal: true

module BCDice
  module GameSystem
    class TensaiGunshiNiNaro < Base
      # ゲームシステムの識別子
      ID = 'TensaiGunshiNiNaro'

      # ゲームシステム名
      NAME = '天才軍師になろう'

      # ゲームシステム名の読みがな
      SORT_KEY = 'てんさいくんしになろう'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定
        TN6…「有利」を得ていない場合、6面ダイスを2つ振って判定します。
        TN10…「有利」を得ている場合、10面ダイスを2つ振って判定します。
        不調 気づかぬうちの不満【C】…このセッションの間、「4」の出目を出しても判定は成功になりません。数字の後ろに【C】をつけます。
        　例）TN6C
        軍師スキル 〇〇サポート【S】…決戦フェイズの判定中「3」の出目を出しても判定に成功します。数字の後ろに【S】をつけます。
        　例）TN6S
        英傑スキル/武人 煌めく刃【B】…決戦フェイズの判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【B】をつけます。
        　例）TN6B
        英傑スキル/武人 力ずく…その判定のサイコロをすべて振った後、[使用者の【攻撃力】]個サイコロを振る。先頭に使用者の【攻撃力】をつけます。
        　例）4TN6
        英傑スキル/武人 必殺の剣【D】…《戦技》を使用している判定中「4」「5」の出目を出してもスペシャルが発生します。数字の後ろに【D】をつけます。
        　例）TN6K
        英傑スキル/武人 二刀流【T】…「攻撃」のスキルの判定中「2」の出目を出しても判定に成功となり、同じ出目のサイコロが2つ以上出ているとスペシャルが発生します。数字の後ろに【T】をつけます。
        　例）TN6T
        英傑スキル/カリスマ 御身のためならば【Y】…「交流」「スカウト」の判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【Y】をつけます。
        　例）TN6Y
        英傑スキル/弓取り 愛用の弓【A】…「攻撃」のスキルの判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【A】をつけます。
        　例）TN6A
        英傑スキル/ヤンキー&マイルドヤンキー その辺の物を武器に【C】…「4」の出目を出しても判定は成功になりません。数字の後ろに【C】をつけます。
        　例）TN6C
        英傑スキル/ヤンキー&マイルドヤンキー 熱血判定【C】…「4」の出目を出しても判定は成功になりません。数字の後ろに【C】をつけます。
        　例）TN6C
        英傑スキル/英傑汎用 凄腕エージェント【A】…活動フェイズの判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【A】をつけます。
        　例）TN6A
        数字の後ろに複数のコマンドを追加できます。
        　例）TN10CYA
        ・ダメージ計算 xDM+y>=t
        　[ダメージ計算]を行う。成否と【HP】の減少量を表示する。
        　x: 6面ダイス数
        　y: 補正値（省略可能）
        　t: 防御力
        ・各種表
        関係決定表 RELA
        平時天才軍師表 PTGS
        平時英傑表 PTHE
        スカウト表 SCOU
        変調表 BDST
      MESSAGETEXT

      def initialize(command)
        super(command)

        @d66_sort_type = D66SortType::ASC
        @round_type = RoundType::FLOOR
      end

      register_prefix('\d*TN(6|10)[ABCKSTY]*', '\d+DM')

      def eval_game_system_specific_command(command)
        roll_judge(command) || roll_damage(command) || roll_tables(command, self.class::TABLES)
      end

      private

      # 行為判定
      def roll_judge(command)
        m = /^(\d*)TN(6|10)([ABCKSTY]*)$/.match(command)
        unless m
          return nil
        end

        # 成功となる出目
        success_dices = [4, 5, 6, 7, 8, 9, 10]

        # スペシャルとなる出目
        special_dices = [6, 10]

        # ファンブルとなる出目
        fumble_dices = [1]

        # 有利
        advantage = m[2] == "10"

        # 不調 気づかぬうちの不満
        complaints = m[3].include?("C")

        # 軍師スキル 〇〇サポート
        support = m[3].include?("S")

        # 英傑スキル/武人 煌めく刃
        blade = m[3].include?("B")

        # 英傑スキル/武人 必殺の剣
        killer = m[3].include?("K")

        # 英傑スキル/武人 二刀流
        twin = m[3].include?("T")

        # 英傑スキル/カリスマ 御身のためならば
        you = m[3].include?("Y")

        # 英傑スキル/弓取り 愛用の弓
        # 英傑スキル/英傑汎用 凄腕エージェント
        agent = m[3].include?("A")

        # 二刀流の適用時
        if twin
          # 成功となる出目に2を追加
          success_dices.push(2)
        end

        # 〇〇サポート、煌めく刃、愛用の弓、御身のためならば、凄腕エージェントいずれかの適用時
        if support | blade | you | agent
          # 成功となる出目に3を追加
          success_dices.push(3)
        end

        # 煌めく刃、御身のためならば、愛用の弓、凄腕エージェントいずれかの適用時
        if blade | you | agent
          # スペシャルとなる出目に3を追加
          special_dices.push(3)
        end

        # 必殺の剣の適用時
        if killer
          # スペシャルとなる出目に4，5を追加
          special_dices.push(4)
          special_dices.push(5)
        end

        # 気づかぬうちの不満適用時
        if complaints
          # 成功となる出目から4を削除
          success_dices.delete(4)
        end

        # 英傑スキル/武人 力ずく
        times = 2 + m[1].to_i
        dice_size = advantage ? 10 : 6
        dice_list = @randomizer.roll_barabara(times, dice_size)

        texts = []
        is_critical = false
        is_fumble = false
        is_success = false

        # スペシャルとなる出目を含む、または、二刀流の適用時かつ同じ出目のサイコロが2つ以上出ている場合
        if !dice_list.intersection(special_dices).empty? | (twin & (dice_list.count != dice_list.uniq.count))
          # クリティカルフラグを立てる
          is_critical = true
          # スペシャルのシステムメッセージを追加
          texts.push(translate("TensaiGunshiNiNaro.JUDGE.critical"))
          special_effects = []
          # 通常時の追加効果
          special_effects.push(translate("TensaiGunshiNiNaro.NORMAL.critical"))
          # 英傑スキル/武人 煌めく刃による追加効果
          special_effects.push(translate("TensaiGunshiNiNaro.BLADE.critical")) if blade
          # 英傑スキル/カリスマ 御身のためならばによる追加効果
          special_effects.push(translate("TensaiGunshiNiNaro.YOU.critical")) if you
          # 追加効果を結合してカッコ内に格納
          texts.push("（#{special_effects.join('')}）")
        end

        # ファンブルとなる出目を含む場合
        unless dice_list.intersection(fumble_dices).empty?
          # ファンブルフラグを立てる
          is_fumble = true
          # ファンブルのシステムメッセージを追加
          texts.push(translate("TensaiGunshiNiNaro.JUDGE.fumble"))
          # ファンブルの追加効果をカッコ内に格納
          texts.push("（#{translate('TensaiGunshiNiNaro.NORMAL.fumble')}）")
        end

        if dice_list.intersection(success_dices).empty?
          # 成功となる出目を含まない場合
          # 失敗の汎用メッセージを追加
          texts.push(translate("failure"))
        else
          # 成功となる出目を含む場合
          # 成功フラグを立てる
          is_success = true
          # 成功の汎用メッセージを追加
          texts.push(translate("success"))
        end

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ [#{dice_list.join(',')}] ＞ #{texts.join('')}"
          # 各種成否を格納
          r.condition = is_success
          r.critical = is_critical
          r.fumble = is_fumble
        end
      end

      # ダメージ計算
      def roll_damage(command)
        parser = Command::Parser.new("DM", round_type: @round_type)
                                .has_prefix_number
                                .restrict_cmp_op_to(:>=)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        text = ''
        is_success = false

        # ダメージ計算
        damage = @randomizer.roll_sum(parsed.prefix_number, 6) + parsed.modify_number
        # HP減少量計算
        dec = damage / parsed.target_number

        # HP減少量の最大値は3
        dec = 3 if dec > 3

        if dec > 0
          # HPを減らせた場合
          # 成功フラグを立てる
          is_success = true
          # 成功メッセージを追加
          text = translate("TensaiGunshiNiNaro.DAMAGE.success", damage: damage.to_s, dec: dec.to_s)
        else
          # 失敗メッセージを追加
          text = translate("TensaiGunshiNiNaro.DAMAGE.failure", damage: damage.to_s)
        end

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ #{damage} ＞ #{text}"
          # 各種成否を格納
          r.condition = is_success
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            "RELA" => DiceTable::D66Table.from_i18n("TensaiGunshiNiNaro.table.RELA", locale),
            "PTGS" => DiceTable::D66Table.from_i18n("TensaiGunshiNiNaro.table.PTGS", locale),
            "PTHE" => DiceTable::D66Table.from_i18n("TensaiGunshiNiNaro.table.PTHE", locale),
            "SCOU" => DiceTable::D66Table.from_i18n("TensaiGunshiNiNaro.table.SCOU", locale),
            "BDST" => DiceTable::Table.from_i18n("TensaiGunshiNiNaro.table.BDST", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
