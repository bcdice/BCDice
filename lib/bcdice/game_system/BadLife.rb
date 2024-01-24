# frozen_string_literal: true

module BCDice
  module GameSystem
    class BadLife < Base
      # ゲームシステムの識別子
      ID = 'BadLife'

      # ゲームシステム名
      NAME = 'バッドライフ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はつとらいふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定：nBADm[±a][Cb±c][Fd±e][@X±f][!OP]　　[]内のコマンドは省略可。
        ・BADコマンドは「BL」コマンドで代用可。
        ・博徒は「GL」コマンドで〈波乱万丈〉の効果を適用。

        「n」で振るダイス数、「m」で特性値、「±a」で達成値への修正値、
        「Cb±c」でクリティカル値への修正、「Fd±e」でファンブル値への修正、
        「@X」で目標難易度を指定。
        「±a」「Cb±c」「Fd±e」[@X±f]部分は「4+1-3」などの複数回指定可。
        「!OP」部分で、一部のスキルやガジェットの追加効果を指定可。
        使用可能なコマンドは以下の通り。順不同、複数同時使用も可。
        A：〈先見の明〉　　H：［重撃］

        【書式例】
        BAD → 1ダイスで達成値を表示。
        3BAD10+2-1 → 3ダイスで修正+11の達成値を表示。
        BL8@15 → 1ダイスで修正+8、難易度15の判定。
        2BL8C-1F1@15 → 2ダイスで修正+8、C値-1、F値+1、難易度15の判定。
        GL6@20 → 1ダイスで修正+6、難易度20の判定。〈波乱万丈〉の効果。
        GL6@20!HA → 上記に加えて〈先見の明〉［重撃］の効果。

        ・コードネーム表
        怪盗：TRN　　　闇医者：DRN　　博徒：GRN
        殺シ屋：KRN　　業師：SRN　　　遊ビ人：BRN

        ・スキル表：SKL
      MESSAGETEXT

      register_prefix('\d?(BAD|BL|GL)', '[TDGKSB]RN', 'SKL')

      def eval_game_system_specific_command(command)
        judgeDice(command) || roll_tables(command, TABLES)
      end

      def judgeDice(command)
        unless (m = /(\d+)?(BAD|BL|GL)([-+\d]*)((C|F)([-+\d]*)?)?((C|F)([-+\d]*))?(@([-+\d]*))?(!(\D*))?/i.match(command))
          return nil
        end

        diceCount = (m[1] || 1).to_i

        critical = 20
        fumble = 1

        isStormy = (m[2] == 'GL') # 波乱万丈
        if isStormy
          critical -= 3
          fumble += 1
        end

        modify = get_value(m[3])

        critical, fumble = get_critival_fumble(critical, fumble, m[5], m[6])
        critical, fumble = get_critival_fumble(critical, fumble, m[8], m[9])

        target = get_value(m[11])
        optionalText = m[13] || ''

        return checkRoll(diceCount, modify, critical, fumble, target, isStormy, optionalText)
      end

      def get_critival_fumble(critical, fumble, marker, text)
        case marker
        when 'C'
          critical += get_value(text)
        when 'F'
          fumble += get_value(text)
        end

        return critical, fumble
      end

      def checkRoll(diceCount, modify, critical, fumble, target, isStormy, optionalText)
        isAnticipation = optionalText.include?('A')    # 先見の明
        isHeavyAttack = optionalText.include?('H')     # 重撃

        dice_list = @randomizer.roll_barabara(diceCount, 20)
        diceText = dice_list.join(",")
        diceMax = dice_list.max

        diceMax = 5 if isHeavyAttack && diceMax <= 5   # 重撃

        isCritical = (diceMax >= critical)
        isFumble = (diceMax <= fumble)

        diceMax = 20 if isCritical                     # クリティカル
        total = diceMax + modify
        total += 5 if isAnticipation && diceMax <= 7   # 先見の明
        total = 0 if isFumble                          # ファンブル

        result = "#{diceCount}D20\(C:#{critical},F:#{fumble}\) ＞ "
        result += "#{diceMax}\[#{diceText}\]"
        result += "\+" if modify > 0
        result += modify.to_s if modify != 0
        result += "\+5" if isAnticipation && diceMax <= 7 # 先見の明
        result += " ＞ 達成値：#{total}"

        if target > 0
          success = total - target
          result += ">=#{target} 成功度：#{success} ＞ "

          if isCritical
            result += "成功（クリティカル）"
          elsif total >= target
            result += "成功"
          else
            result += "失敗"
            result += "（ファンブル）" if isFumble
          end
        else
          result += " クリティカル" if isCritical
          result += " ファンブル" if isFumble
        end

        skillText = ""
        skillText += "〈波乱万丈〉" if  isStormy
        skillText += "〈先見の明〉" if  isAnticipation
        skillText += "［重撃］" if isHeavyAttack
        result += " #{skillText}" if skillText != ""

        return result
      end

      def get_value(text)
        text ||= ""
        return ArithmeticEvaluator.eval(text)
      end

      TABLES = {
        "SKL" => DiceTable::Table.new(
          "スキル表",
          "1D100",
          [
            "一撃離脱",
            "一撃離脱",
            "チェイサー",
            "チェイサー",
            "影の外套",
            "影の外套",
            "二段ジャンプ",
            "二段ジャンプ",
            "韋駄天",
            "韋駄天",
            "手練",
            "手練",
            "ハニーテイスト",
            "ハニーテイスト",
            "先見の明",
            "先見の明",
            "ベテラン",
            "ベテラン",
            "応急手当",
            "応急手当",
            "セラピー",
            "セラピー",
            "緊急治療",
            "緊急治療",
            "ゴールドディガー",
            "ゴールドディガー",
            "デイリーミッション",
            "デイリーミッション",
            "見切り",
            "見切り",
            "鷹の目",
            "鷹の目",
            "しびれ罠",
            "しびれ罠",
            "大逆転",
            "大逆転",
            "武器習熟：○○",
            "武器習熟：○○",
            "百発百中",
            "百発百中",
            "屈強な肉体",
            "屈強な肉体",
            "二刀流",
            "二刀流",
            "クイックリカバリー",
            "クイックリカバリー",
            "体験主義",
            "体験主義",
            "破釜沈船",
            "破釜沈船",
            "想定の範囲内",
            "想定の範囲内",
            "セカンドチャンス",
            "セカンドチャンス",
            "優秀な子分",
            "優秀な子分",
            "時間管理術",
            "時間管理術",
            "連撃術",
            "連撃術",
            "罵詈雑言",
            "罵詈雑言",
            "ケセラセラ",
            "ケセラセラ",
            "ダンス＆ミュージック",
            "ダンス＆ミュージック",
            "フェイント",
            "フェイント",
            "ヘイトコントロール",
            "ヘイトコントロール",
            "惜別",
            "惜別",
            "戦闘マシーン",
            "戦闘マシーン",
            "戦闘マシーン",
            "名医",
            "名医",
            "名医",
            "忍者",
            "忍者",
            "忍者",
            "観察眼",
            "観察眼",
            "観察眼",
            "クレバー",
            "クレバー",
            "クレバー",
            "フェイスマン",
            "フェイスマン",
            "フェイスマン",
            "スポーツマン",
            "スポーツマン",
            "スポーツマン",
            "不屈",
            "不屈",
            "不屈",
            "慎重",
            "慎重",
            "慎重",
            "この表を2回振る",
          ]
        ),
        "TRN" => DiceTable::Table.new(
          "怪盗コードネーム表",
          "1D20",
          [
            "フォックス",
            "フォックス",
            "ラット",
            "ラット",
            "キャット",
            "キャット",
            "タイガー",
            "タイガー",
            "シャーク",
            "シャーク",
            "コンドル",
            "コンドル",
            "スパイダー",
            "スパイダー",
            "ウルフ",
            "ウルフ",
            "コヨーテ",
            "コヨーテ",
            "ジャガー",
            "ジャガー",
          ]
        ),
        "DRN" => DiceTable::Table.new(
          "闇医者コードネーム表",
          "1D20",
          [
            "キャンサー",
            "キャンサー",
            "ヘッドエイク",
            "ヘッドエイク",
            "ブラッド",
            "ブラッド",
            "ウーンズ",
            "ウーンズ",
            "ポイズン",
            "ポイズン",
            "ペイン",
            "ペイン",
            "スリープ",
            "スリープ",
            "キュア",
            "キュア",
            "デス",
            "デス",
            "リーンカーネイション",
            "リーンカーネイション",
          ]
        ),
        "GRN" => DiceTable::Table.new(
          "博徒コードネーム表",
          "1D20",
          [
            "リトルダイス",
            "リトルダイス",
            "プラチナム",
            "プラチナム",
            "プレジデント",
            "プレジデント",
            "ドリーム",
            "ドリーム",
            "アクシデント",
            "アクシデント",
            "グリード",
            "グリード",
            "フォーチュン",
            "フォーチュン",
            "ミラクル",
            "ミラクル",
            "ホープ",
            "ホープ",
            "ビッグヒット",
            "ビッグヒット",
          ]
        ),
        "KRN" => DiceTable::Table.new(
          "殺シ屋コードネーム表",
          "1D20",
          [
            "ハンマー",
            "ハンマー",
            "アロー",
            "アロー",
            "ボマー",
            "ボマー",
            "キャノン",
            "キャノン",
            "ブレード",
            "ブレード",
            "スティング",
            "スティング",
            "ガロット",
            "ガロット",
            "パイルバンカー",
            "パイルバンカー",
            "レイザー",
            "レイザー",
            "カタナ",
            "カタナ",
          ]
        ),
        "SRN" => DiceTable::Table.new(
          "業師コードネーム表",
          "1D20",
          [
            "ローズ",
            "ローズ",
            "サクラ",
            "サクラ",
            "ライラック",
            "ライラック",
            "ダンデライオン",
            "ダンデライオン",
            "フリージア",
            "フリージア",
            "カクタス",
            "カクタス",
            "ロータス",
            "ロータス",
            "リリィ",
            "リリィ",
            "ラフレシア",
            "ラフレシア",
            "ヒヤシンス",
            "ヒヤシンス",
          ]
        ),
        "BRN" => DiceTable::Table.new(
          "遊ビ人コードネーム表",
          "1D20",
          [
            "モノポリー",
            "モノポリー",
            "ブリッジ",
            "ブリッジ",
            "チェッカー",
            "チェッカー",
            "アクワイア",
            "アクワイア",
            "ジャンケン",
            "ジャンケン",
            "トランプ",
            "トランプ",
            "ケイドロ",
            "ケイドロ",
            "パンデミック",
            "パンデミック",
            "スゴロク",
            "スゴロク",
            "キャベツカンテイ",
            "キャベツカンテイ",
          ]
        ),
      }.freeze
    end
  end
end
