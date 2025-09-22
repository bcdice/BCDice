# frozen_string_literal: true

require "bcdice/game_system/kizuna_bullet/tables"

module BCDice
  module GameSystem
    class KizunaBullet_Korean < KizunaBullet
      # ゲームシステムの識別子
      ID = 'KizunaBullet:Korean'

      # ゲームシステム名
      NAME = '키즈나 불릿'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:키즈나 불릿'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・다이스 롤
        nDM...n개의 6면 다이스를 굴려 가장 높은 값을 사용합니다.
        ・［조사 판정］
        nIN…n개의 6면 다이스를 굴려 가장 높은 값이 5 이상이면 성공합니다. ([파트너의 헬프] 사용가능)
        ・［진정 판정］
        SEn…2개의 6면 다이스를 굴려 합계치가 n([균열]상태의 [키즈나]의 개수)보다 높으면 성공합니다. ([강제 진정]사용가능)
        ・［해결］ ［액션］의 대미지와［액시던트］의 대미지 경감
        nSO…2+n개의 6면 다이스를 굴려 결과값을 모두 합산합니다. (n은 줄인 【여기치】. 생략 가능)
        ・각종표
        일상표・장소 OP
        일상표・내용 OC
        일상표・장소 및 내용 OPC
        일상표(일)・장소 OWP
        일상표(일)・내용 OWC
        일상표(일)・장소 및 내용 OWPC
        일상표(휴가)・장소 OHP
        일상표(휴가)・내용 OHC
        일상표(휴가)・장소 및 내용 OHPC
        일상표(출장)・장소 OTP
        일상표(출장)・내용 OTC
        일상표(출장)・장소 및 내용 OTPC
        턴테마표 TT
        턴테마표・친밀 TTI
        턴테마표・쿨 TTC
        턴테마표・주종 TTH
        조우표・장소 EP
        조우표・출현 순서 EO
        조우표・상황(첫대면) EF
        조우표・상황(아는 사이) EA
        조우표・결착 EE
        조우표·장소와 등장 순서와 상황(첫대면)과 결착 EFA
        조우표·장소와 등장순서와 상황(아는 사이)과 결판 EAA
        교류표·장소 CP
        교류표·내용 CC
        교류표·장소 및 내용 CPC
        조사표 · 베이직 IB
        조사표・다이나믹 ID
        조사표・베이직과 다이나믹 IBD
        해저드표 HA
        통상 다이제스트　당신들에게 새로운 명령이 떨어졌다(조사가 의뢰되었다).
        1:그 사건의 내용은……. NI1
        2:조사하러 향한 장소는…… NI2
        3:범인인 기적사는…… NI3
        4:일어난 일은……. NI4
        5:불릿 사이에서는…… NI5
        6:싸움의 결말은…… NI6
        통상 다이제스트 당신들은 여행(출장)으로 어느 장소를 찾았다.
        1:그 장소란…… NT1
        2:그곳에서 시작한 것은…… NT2
        3:극한의 상황 속에서…… NT3
        4:범인인 기적사는…… NT4
        5:불릿 사이에서는…… NT5
        6:싸움의 결말은…… NT6
        홀리데이 다이제스트 당신들은 휴일에 나가기로 했다.
        1:그 장소란…… HH1
        2:약속하고 만나면…… HH2
        3:그리고 무려……… HH3
        4:두 사람이 결정한 것은…… HH4
        5:결과적으로…… HH5
        6:불릿은 마지막으로…… HH6
        홀리데이 다이제스트 당신들은 기묘한 사건을 마주했다.
        1:그 장소란…… HC1
        2:일어난 사건은……. HC2
        3:범인인 시적사는…… HC3
        4:범인을 몰아붙이기 위해…… HC4
        5:싸움의 결과는…… HC5
        6:불릿은 마지막으로……HC6
      MESSAGETEXT

      TABLES = translate_tables(:ko_kr) # @localeを :ko_kr に強制

      def initialize(command)
        super(command)

        @sides_implicit_d = 6
        @round_type = RoundType::CEIL
        @d66_sort_type = D66SortType::NO_SORT
      end

      # translateをオーバーライドして、常に:ko_krを使うようにする
      def translate(key, **opts)
        super(key, locale: :ko_kr, **opts)
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
