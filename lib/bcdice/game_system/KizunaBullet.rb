# frozen_string_literal: true

module BCDice
  module GameSystem
    class KizunaBullet < Base
      # ゲームシステムの識別子
      ID = 'KizunaBullet'

      # ゲームシステム名
      NAME = 'キズナバレット'

      # ゲームシステム名の読みがな
      SORT_KEY = 'きすなはれつと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・ダイスロール
        nDS…n個の6面ダイスを転がして、出目をすべて合計します。
        nDM…n個の6面ダイスを転がして、一番高い出目を採用します。
        ・［調査判定］
        nIN…n個の6面ダイスを転がして、一番高い出目が5以上なら成功します。（［パートナーのヘルプ］使用可）
        ・［鎮静判定］
        SE>n…2個の6面ダイスを転がして、出目の合計値がn（［ヒビワレ］状態の［キズナ］の個数）より高いと成功します。（［強制鎮静］使用可）
        ・［解決］ ［アクション］のダメージと［アクシデント］のダメージ軽減
        nSO…2+n個の6面ダイスを転がして、出目をすべて合計します。（nは省略可能）
        ・各種表
        日常表・場所 ODP
        日常表・内容 ODC
        ターンテーマ表 TTC
        交流表・場所 COP
        交流表・内容 COC
        調査表・ベーシック INB
        調査表・ダイナミック IND
        ハザード表 HAZ
      MESSAGETEXT

      def initialize(command)
        super(command)

        @sides_implicit_d = 6
        @round_type = RoundType::CEIL
      end

      register_prefix('\d+DS', '\d+DM', '\d+IN', 'SE>\d+', '\d*SO')

      def eval_game_system_specific_command(command)
        roll_sum(command) || roll_max(command) || roll_investigate(command) || roll_sedative(command) || roll_solve(command) || roll_tables(command, self.class::TABLES)
      end

      private

      # 合計値
      def roll_sum(command)
        parser = Command::Parser.new("DS", round_type: @round_type)
                                .has_prefix_number
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        # 合計値計算
        sum = @randomizer.roll_sum(parsed.prefix_number, 6)

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ #{sum}"
        end
      end

      # 最大値
      def roll_max(command)
        parser = Command::Parser.new("DM", round_type: @round_type)
                                .has_prefix_number
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        # 最大値計算
        dice_list = @randomizer.roll_barabara(parsed.prefix_number, 6)
        max = dice_list.max

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ [#{dice_list.join(',')}] ＞ #{max}"
        end
      end

      # 調査判定
      def roll_investigate(command)
        parser = Command::Parser.new("IN", round_type: @round_type)
                                .has_prefix_number
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        texts = []
        is_success = false
        is_fumble = false

        # 最大値計算
        dice_list = @randomizer.roll_barabara(parsed.prefix_number, 6)
        max = dice_list.max

        if max >= 5
          # 5以上の出目があった場合
          # 成功フラグを立てる
          is_success = true
          # 成功メッセージを追加
          texts.push(translate("KizunaBullet.INVESTIGATE.success"))
        elsif max >= 3
          # 3以上の出目があった場合
          # 失敗メッセージを追加
          texts.push(translate("KizunaBullet.INVESTIGATE.failure"))
          # ［パートナーのヘルプ］メッセージを追加
          texts.push(translate("KizunaBullet.INVESTIGATE.partnerHelp"))
        else
          # 上記以外
          # ファンブルフラグを立てる
          is_fumble = true
          # 失敗メッセージを追加
          texts.push(translate("KizunaBullet.INVESTIGATE.failure"))
          # ファンブルメッセージを追加
          texts.push(translate("KizunaBullet.INVESTIGATE.fumble"))
        end

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ [#{dice_list.join(',')}] ＞ #{texts.join('')}"
          # 各種成否を格納
          r.condition = is_success
          r.fumble = is_fumble
        end
      end

      # 鎮静判定
      def roll_sedative(command)
        parser = Command::Parser.new("SE", round_type: @round_type)
                                .restrict_cmp_op_to(:>)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        text = ''
        is_success = false

        # 合計値計算
        sum = @randomizer.roll_sum(2, 6)

        if parsed.target_number > 12
          # 目標値が12より大きい場合
          # ［晶滅］メッセージを追加
          text = translate("KizunaBullet.SEDATIVE.burst")
        elsif sum > parsed.target_number
          # 合計値が目標値より大きい場合
          # 成功フラグを立てる
          is_success = true
          # 成功メッセージを追加
          text = translate("KizunaBullet.SEDATIVE.success")
        else
          # 上記以外
          # ［強制鎮静］に必要な［キズナ］のチェック数の計算
          # 目標値と出目の差分を計算
          dif = parsed.target_number - sum
          # チェック一つごとに結果に+2
          check = (dif / 2) + 1
          # 失敗メッセージを追加
          text = translate("KizunaBullet.SEDATIVE.failure", check: check.to_s)
        end

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ #{sum} ＞ #{text}"
          # 各種成否を格納
          r.condition = is_success
        end
      end

      # 解決 ［アクション］のダメージと［アクシデント］のダメージ軽減
      def roll_solve(command)
        parser = Command::Parser.new("SO", round_type: @round_type)
                                .enable_prefix_number
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        # 合計値計算
        sum = @randomizer.roll_sum(parsed.prefix_number.to_i + 2, 6)

        return Result.new.tap do |r|
          # テキストを整形
          r.text = "#{command} ＞ #{sum}"
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            "ODP" => DiceTable::Table.from_i18n("KizunaBullet.table.ODP", locale),
            "ODC" => DiceTable::Table.from_i18n("KizunaBullet.table.ODC", locale),
            "TTC" => DiceTable::D66Table.from_i18n("KizunaBullet.table.TTC", locale),
            "COP" => DiceTable::Table.from_i18n("KizunaBullet.table.COP", locale),
            "COC" => DiceTable::Table.from_i18n("KizunaBullet.table.COC", locale),
            "INB" => DiceTable::D66Table.from_i18n("KizunaBullet.table.INB", locale),
            "IND" => DiceTable::D66Table.from_i18n("KizunaBullet.table.IND", locale),
            "HAZ" => DiceTable::Table.from_i18n("KizunaBullet.table.HAZ", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
