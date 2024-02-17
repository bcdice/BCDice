# frozen_string_literal: true

module BCDice
  module GameSystem
    class Tensai < Base
      # ゲームシステムの識別子
      ID = 'Tensai'

      # ゲームシステム名
      NAME = '天才軍師になろう'

      # ゲームシステム名の読みがな
      SORT_KEY = 'てんさいぐんしになろう'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定
        T6…「有利」を得ていない場合、6面ダイスを2つ振って判定します。
        T10…「有利」を得ている場合、10面ダイスを2つ振って判定します。
        不調 気づかぬうちの不満【C】…判定のダイス目が「4」でも判定に成功しません。数字の後ろに【C】をつけます。
        　例）T6C
        軍師スキル 〇〇サポート【S】…決戦フェイズの判定中「3」の出目を出しても判定に成功します。数字の後ろに【S】をつけます。
        　例）T6S
        英傑スキル/武人 煌めく刃【B】…決戦フェイズの判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【B】をつけます。
        　例）T6B
        英傑スキル/カリスマ 御身のためならば【Y】…「交流」「スカウト」の判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【Y】をつけます。
        　例）T6Y
        英傑スキル/英傑汎用 凄腕エージェント【A】…活動フェイズの判定中「3」の出目を出しても判定に成功となり、スペシャルが発生します。数字の後ろに【A】をつけます。
        　例）T6A
        数字の後ろに複数のコマンドを追加できます。
        　例）T10CYA
        ・ダメージ計算 xDM>=t
        　[ダメージ計算]を行う。成否と【HP】の減少量を表示する。
        　x: 6面ダイス数
        　t: 防御力
        ・各種表
        【セッション時】
        変調表 BDST
        【設定時】
        経歴表　軍師 PHGS　武人 PHWA　カリスマ PHCH　戦略級魔法使い PHMA　薬師経歴表 PHPH

      MESSAGETEXT

      def initialize(command)
        super(command)

        @d66_sort_type = D66SortType::ASC
        @round_type = RoundType::FLOOR
      end

      register_prefix('T(6|10)[CSBYA]*', '(\d)DM')

      def eval_game_system_specific_command(command)
        roll_judge(command) || roll_damage(command) || roll_tables(command, self.class::TABLES)
      end

      private

      # 行為判定
      def roll_judge(command)
        # 特定の書式の場合のみ実行
        unless /^T(6|10)[CSBYA]*$/.match(command)
          return nil
        end

        # 成功となる出目
        success_dices = [4, 5, 6, 7, 8, 9, 10]

        # スペシャルとなる出目
        special_dices = [6, 10]

        # ファンブルとなる出目
        fumble_dices = [1]

        # 有利
        advantage = /10/.match(command) ? true : false

        # 不調 気づかぬうちの不満
        complaints = /C/i.match(command) ? true : false

        # 軍師スキル 〇〇サポート
        support = /S/i.match(command) ? true : false

        # 英傑スキル/武人 煌めく刃
        blade = /B/i.match(command) ? true : false

        # 英傑スキル/カリスマ 御身のためならば
        you = /Y/i.match(command) ? true : false

        # 英傑スキル/英傑汎用 凄腕エージェント
        agent = /A/i.match(command) ? true : false

        # 〇〇サポート、煌めく刃、御身のためならば、凄腕エージェントいずれかの適用時
        if support | blade | you | agent
          # 成功となる出目に3を追加
          success_dices.push(3)
        end

        # 煌めく刃、御身のためならば、凄腕エージェントいずれかの適用時
        if blade | you | agent
          # スペシャルとなる出目に3を追加
          special_dices.push(3)
        end

        # 気づかぬうちの不満適用時
        if complaints
          # 成功となる出目から4を削除
          success_dices.delete(4)
        end

        dice_size = advantage ? 10 : 6
        dice_list = @randomizer.roll_barabara(2, dice_size)

        texts = []
        is_critical = false
        is_fumble = false
        is_success = false

        # スペシャルとなる出目を含む場合
        unless dice_list.intersection(special_dices).empty?
          # クリティカルフラグを立てる
          is_critical = true
          # スペシャルのシステムメッセージを追加
          texts.push(translate("Tensai.JUDGE.critical"))
          special_effects = []
          # 通常時の追加効果
          special_effects.push(translate("Tensai.NORMAL.critical"))
          # 英傑スキル/武人 煌めく刃による追加効果
          special_effects.push(translate("Tensai.BLADE.critical")) if blade
          # 英傑スキル/カリスマ 御身のためならばによる追加効果
          special_effects.push(translate("Tensai.YOU.critical")) if you
          # 追加効果を結合してカッコ内に格納
          texts.push("（#{special_effects.join('')}）")
        end

        # ファンブルとなる出目を含む場合
        unless dice_list.intersection(fumble_dices).empty?
          # ファンブルフラグを立てる
          is_fumble = true
          # ファンブルのシステムメッセージを追加
          texts.push(translate("Tensai.JUDGE.fumble"))
          # ファンブルの追加効果をカッコ内に格納
          texts.push("（#{translate('Tensai.NORMAL.fumble')}）")
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
          r.text = "#{command}(#{dice_list.join(',')}) ＞ #{texts.join('')}"
          # 各種成否を格納
          r.condition = is_success
          r.success = is_success
          r.failure = !is_success
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
        damage = @randomizer.roll_sum(parsed.prefix_number, 6)
        # HP減少量計算
        dec = damage / parsed.target_number

        # HP減少量の最大値は3
        dec = 3 if dec > 3

        if dec > 0
          # HPを減らせた場合
          # 成功フラグを立てる
          is_success = true
          # 成功メッセージを追加
          text = translate("Tensai.DAMAGE.success", damage: damage.to_s, dec: dec.to_s)
        else
          # 失敗メッセージを追加
          text = translate("Tensai.DAMAGE.failure", damage: damage.to_s)
        end

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command}(#{damage}) ＞ #{text}"
          # 各種成否を格納
          r.condition = is_success
          r.success = is_success
          r.failure = !is_success
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            "PHGS" => DiceTable::D66Table.from_i18n("Tensai.table.PHGS", locale),
            "PHWA" => DiceTable::D66Table.from_i18n("Tensai.table.PHWA", locale),
            "PHCH" => DiceTable::D66Table.from_i18n("Tensai.table.PHCH", locale),
            "PHMA" => DiceTable::D66Table.from_i18n("Tensai.table.PHMA", locale),
            "PHPH" => DiceTable::D66Table.from_i18n("Tensai.table.PHPH", locale),
            "BDST" => DiceTable::Table.from_i18n("Tensai.table.BDST", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
