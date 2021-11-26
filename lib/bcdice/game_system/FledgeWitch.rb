# frozen_string_literal: true

module BCDice
  module GameSystem
    class FledgeWitch < Base
      # ゲームシステムの識別子
      ID = 'FledgeWitch'

      # ゲームシステム名
      NAME = 'フレッジウィッチ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふれつしういつち'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■判定（ xB6>=y#z または xFW>=y#z ）
        x: ダイス数（加算式を記述可）
        y: 成功ライン（加算・減算式を記述可）
        z: 必要な成功数（加算式を記述可）

        □成功ラインを省略（ xB6#z または xFW#z ）
        成功ラインは 4 となる。

        □必要な成功数を省略（ xB6>=y または xFW>=y ）
        最終的な成功・失敗は表示されない。

        □成功ラインと必要な成功数を省略（ xFW ）
        成功ラインは 4 となり、最終的な成功・失敗は表示されない。

        □特定のダイス目を必要とする（ #z の後に *r ）
        r: 必要なダイス目（ 1 以上 6 以下）
        例） 5fw>=4#3*6
        　　 ダイス５個、成功ライン４、必要な成功数３かつ、６のダイス目が必要

        □ 6 以外の特定のダイス目を成功数 2 として扱う（ B6 か FW の後に、 &t ）
        t: 成功数 2 として扱うダイス目
        例） 3b6&5>=4#2
        　　 ダイス３個、成功ライン４、必要な成功数２で、５の出目も成功数２とする
        　　 ※魔法スキル「ひらめいた！」の効果を想定

        ■各種表
        □日常表（ DailyLife または DL ）
        □トラブル表（ FailureTrouble または FT ）
        □ランダム技能（ RandomField または RF ）
      HELP

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
      end

      JUDGE_ROLL_REG = /^(\d+(\+\d+)*)(B6?|FW)(&([1-6]))?((>=|=>)(\d+([+\-]\d+)*))?(#(\d+(\+\d+)*)(\*([1-6]))?)?$/i.freeze
      register_prefix('(\d+(\+\d+)*)(B6?|FW)(&([1-6]))?((>=|=>)(\d+([+\-]\d+)*))?(#(\d+(\+\d+)*)(\*([1-6]))?)?')

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command

        if (m = JUDGE_ROLL_REG.match(command))
          dice_count_expression, _, keyword, _, number_as_twice_expression, _, _, success_line_expression, _, _, required_success_count_expression, _, _, required_number_expression = m.captures

          # 汎用コマンドの xB6 と完全に同じ書式なら、判定コマンドとして扱わない.
          return nil if number_as_twice_expression.nil? && success_line_expression.nil? && required_success_count_expression.nil? && keyword != 'FW'

          roll_judge(dice_count_expression, number_as_twice_expression, success_line_expression, required_success_count_expression, required_number_expression)
        else
          roll_tables(command, TABLES)
        end
      end

      private

      def roll_judge(dice_count_expression, number_as_twice_expression, success_line_expression, required_success_count_expression, required_number_expression)
        dice_count = Arithmetic.eval(dice_count_expression, RoundType::FLOOR)

        # 「成功ライン」（ルールブック p29 ）
        # 1..7 の範囲にまるめる（「出目 ≧ 成功ライン」の判断にもちいるので、 1 未満はすべて 1 と等価であり、 7 超はすべて 7 と等価である）
        success_line = success_line_expression ? Arithmetic.eval(success_line_expression, RoundType::FLOOR).clamp(1, 7) : 4

        required_success_count = required_success_count_expression ? Arithmetic.eval(required_success_count_expression, RoundType::FLOOR) : nil

        # 特定のダイス目を必要とするケース（ルールブック p59 ）における、そのダイス目
        required_number = required_number_expression ? required_number_expression.to_i : nil

        # 成功数をふたつ分として数えるダイス目（ルールブック p11, 魔法スキル「ひらめいた！」）
        number_as_twice = number_as_twice_expression ? number_as_twice_expression.to_i : nil

        return 'ダイス数は 1 個以上でなければなりません' if dice_count < 1

        command_text = make_command_text(dice_count, number_as_twice, success_line, required_success_count, required_number)

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        success_count = dices.sum do |dice|
          if dice >= success_line
            if dice == 6 || dice == number_as_twice
              # 「６」または特別に指定された値と一致するダイス目なら、成功数ふたつ分
              # （「６」についてはルールブック p29 、特別に値が指定されるケースはルールブック p11 ）
              2
            else
              1
            end
          else
            0
          end
        end

        is_special = dices.count { |dice| dice == 6 } >= 2 # 「６」の目がふたつ以上なら「スペシャル」（ p30 ）

        if is_special || required_success_count
          is_success = is_special ||
                       (success_count >= required_success_count &&
                       (required_number.nil? || dices.include?(required_number)))
        end

        message_elements = []
        message_elements << command_text
        message_elements << make_dices_text(dices, number_as_twice, success_line, required_number)
        message_elements << "成功数: #{success_count}"
        if is_special
          message_elements << "スペシャル"
        elsif required_success_count
          message_elements << (is_success ? "成功" : "失敗")
          message_elements[-1] = message_elements.last + "（出目 #{required_number} がありません）" if !is_success && required_number
        end

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = is_success if is_special || required_success_count
          r.critical = is_special
        end
      end

      def make_command_text(dice_count, number_as_twice, success_line, required_success_count, required_number)
        command = "#{dice_count}B6"
        command = "#{command}&#{number_as_twice}" unless number_as_twice.nil?
        command = "#{command}>=#{success_line}"
        command = "#{command}\##{required_success_count}" unless required_success_count.nil?
        command = "#{command}*#{required_number}" unless required_number.nil?
        "(#{command})"
      end

      def make_dices_text(dices, number_as_twice, success_line, required_number)
        text = dices.map do |dice|
          dice_text = dice.to_s
          dice_text = "*#{dice_text}*" if dice == required_number # 特定のダイス目が必要とされているなら、その目は強調する
          dice_text = "&#{dice_text}" if dice >= success_line && dice == number_as_twice # 特別に成功数２と扱うダイス目なら、その目は強調する
          dice_text
        end.join(',')

        "[#{text}]"
      end

      ALIAS = {
        "DL" => "DailyLife",
        "FT" => "FailureTrouble",
        "RF" => "RandomField",
      }.transform_keys(&:upcase).transform_values(&:upcase).freeze

      TABLES = {
        "DailyLife" => DiceTable::Table.new(
          "日常表", # ルールブック p24
          "1D6",
          [
            "お手伝い ⇒ 家事を手伝ったり、薬の調合を手伝ったり、本をしまったり。",
            "お稽古 ⇒ 魔女に魔法を教わったり、講義を聞いたり、直接教えてもらえる時間。上手にできることも、できないこともあるでしょう。",
            "散歩 ⇒ 薬草を摘みに行ったり、時には人里まで買い出しに行ったり。外の空気を吸うのは、珍しいことかも。",
            "休憩 ⇒ 時には休むのも弟子の仕事。魔女に言われて休む弟子も、勝手に抜け出して休む弟子もいる。",
            "ごはん ⇒ 一日三食、ちゃんと食べましょう。おやつもあります。",
            "相談 ⇒ 将来の相談から明日の献立まで。些細なことも大事なことも、相手に聞いてみるのが吉。",
          ]
        ),
        "FailureTrouble" => DiceTable::Table.new(
          "トラブル表", # ルールブック p30
          "1D6",
          [
            "ケガ・体調不良 ⇒ 箒から落ちたり、薬の匂いにやられてしまったり。ふとした気のゆるみが、ケガなどに繋がってしまいます。",
            "道具の破損 ⇒ 薬の瓶や水晶玉と、魔女の道具には壊れ物がいっぱい。ふとした瞬間に、そんな道具が壊れてしまいます。",
            "空回り ⇒ 良いとこ見せるために、めいっぱい頑張らないと！　意気込みすぎて、ドツボにはまる羽目に。",
            "気持ちの落ち込み ⇒ こんな結果じゃ、魔女様にがっかりされちゃう。そんな不安や自己嫌悪で、落ち込んでしまいます。",
            "疲労 ⇒ 試練のために集中していっぱい魔法を使うのは、とっても大変。慣れないことの連続に、目が回ってしまいます。",
            "突然の爆発 ⇒ 調合中の釜、持ち歩いていた薬、唱えていた魔法……ささいなきっかけから、なにかが爆発してしまいます。",
          ]
        ),
        "RandomField" => DiceTable::Table.new(
          "ランダム技能", # ルールブック p35
          "1D6",
          [
            "召喚術",
            "詠唱術",
            "薬品術",
            "道具術",
            "図書術",
            "生活術",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      register_prefix(ALIAS.keys, TABLES.keys)
    end
  end
end
