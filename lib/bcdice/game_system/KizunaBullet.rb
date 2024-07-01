# frozen_string_literal: true

require "bcdice/game_system/kizuna_bullet/tables"

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
        nDM…n個の6面ダイスを転がして、一番高い出目を採用します。
        ・［調査判定］
        nIN…n個の6面ダイスを転がして、一番高い出目が5以上なら成功します。（［パートナーのヘルプ］使用可）
        ・［鎮静判定］
        SEn…2個の6面ダイスを転がして、出目の合計値がn（［ヒビワレ］状態の［キズナ］の個数）より高いと成功します。（［強制鎮静］使用可）
        ・［解決］ ［アクション］のダメージと［アクシデント］のダメージ軽減
        nSO…2+n個の6面ダイスを転がして、出目をすべて合計します。（nは減らした【励起値】。省略可能）
        ・各種表
        日常表・場所 OP
        日常表・内容 OC
        日常表・場所と内容 OPC
        日常表（仕事）・場所 OWP
        日常表（仕事）・内容 OWC
        日常表（仕事）・場所と内容 OWPC
        日常表（休暇）・場所 OHP
        日常表（休暇）・内容 OHC
        日常表（休暇）・場所と内容 OHPC
        日常表（出張）・場所 OTP
        日常表（出張）・内容 OTC
        日常表（出張）・場所と内容 OTPC
        ターンテーマ表 TT
        ターンテーマ表・親密 TTI
        ターンテーマ表・クール TTC
        ターンテーマ表・主従 TTH
        遭遇表・場所 EP
        遭遇表・登場順 EO
        遭遇表・状況（初対面） EF
        遭遇表・状況（知り合い） EA
        遭遇表・決着 EE
        遭遇表・場所と登場順と状況（初対面）と決着 EFA
        遭遇表・場所と登場順と状況（知り合い）と決着 EAA
        交流表・場所 CP
        交流表・内容 CC
        交流表・場所と内容 CPC
        調査表・ベーシック IB
        調査表・ダイナミック ID
        調査表・ベーシックとダイナミック IBD
        ハザード表 HA
        通常ダイジェスト　キミたちに新しい命令が下った（調査が依頼された）。
        1:その事件の内容は…… NI1
        2:捜査に向かった場所は…… NI2
        3:犯人のキセキ使いは…… NI3
        4:起きた出来事は…… NI4
        5:バレットの間では…… NI5
        6:戦いの結末は…… NI6
        通常ダイジェスト　キミたちは旅行（出張）である場所を訪れた。
        1:その場所とは…… NT1
        2:そこで始まったのは…… NT2
        3:極限状態のなかで…… NT3
        4:犯人のキセキ使いは…… NT4
        5:バレットの間では…… NT5
        6:戦いの結末は…… NT6
        ホリデーダイジェスト　キミたちは休日に出かけることにした。
        1:その場所とは…… HH1
        2:待ち合わせをしたら…… HH2
        3:そしてなんと…… HH3
        4:ふたりが決めたのは…… HH4
        5:結果的に…… HH5
        6:バレットは最後に…… HH6
        ホリデーダイジェスト　キミたちは奇妙な事件に出くわした。
        1:その場所とは…… HC1
        2:起きた事件は…… HC2
        3:犯人のキセキ使いは…… HC3
        4:犯人を追い詰めるべく…… HC4
        5:戦いの結果は…… HC5
        6:バレットは最後に…… HC6
      MESSAGETEXT

      TABLES = translate_tables(@locale)

      def initialize(command)
        super(command)

        @sides_implicit_d = 6
        @round_type = RoundType::CEIL
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        roll_max(command) || roll_investigate(command) || roll_sedative(command) || roll_solve(command) || roll_tables(command, self.class::TABLES)
      end

      private

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
                                .has_suffix_number
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        text = ''
        is_success = false

        # 合計値計算
        sum = @randomizer.roll_sum(2, 6)

        if parsed.suffix_number > 12
          # 目標値が12より大きい場合
          # ［晶滅］メッセージを追加
          text = translate("KizunaBullet.SEDATIVE.burst")
        elsif parsed.suffix_number < 6
          # 目標値が6より小さい場合
          # ［生存］メッセージを追加
          text = translate("KizunaBullet.SEDATIVE.alive")
        elsif sum > parsed.suffix_number
          # 合計値が目標値より大きい場合
          # 成功フラグを立てる
          is_success = true
          # 成功メッセージを追加
          text = translate("KizunaBullet.SEDATIVE.success")
        else
          # 上記以外
          # ［強制鎮静］に必要な［キズナ］のチェック数の計算
          # 目標値と出目の差分を計算
          dif = parsed.suffix_number - sum
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

      register_prefix('\d+DM', '\d+IN', 'SE\d+', '\d*SO', TABLES.keys)
    end
  end
end
