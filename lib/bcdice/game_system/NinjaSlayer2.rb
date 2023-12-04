# frozen_string_literal: true

module BCDice
  module GameSystem
    class NinjaSlayer2 < Base
      # ゲームシステムの識別子
      ID = "NinjaSlayer2"

      # ゲームシステム名
      NAME = "ニンジャスレイヤーTRPG 2版"

      # ゲームシステム名の読みがな
      SORT_KEY = "にんしやすれいやあTRPG2"

      HELP_MESSAGE = <<~TEXT
        - K{x1},{x2},...,{xn}
        難易度K([K]ids)の成功判定({x1}B6>=2)を、ダイス{x1}個({x2}～を指定した場合はそれぞれ個々に)で実行します。
        先頭の文字を変えることで、難易度E([E]asy),N([N]ormal),H([H]ard),U([U]ltra-hard)もしくはUH([U]ltra-[H]ard)でも実行可能です。(以下も同様)

        - K{x1},{x2},...,{xn}[>={y}]
        K{x1}のロールの結果を使って、[]内で指定された条件を満たすダイスの個数を追加で出力します。
        判定式は「>=」の他に「>」「<=」「<」「=」「!=」が利用可能です。
        [=5][=6]のように複数記述することで、それぞれで追加判定が可能です。

        - K{x1},{x2},...,{xn}[S] or K{x1},{x2},...,{xn}[S{y}]
        - K{x1},{x2},...,{xn}[C] or K{x1},{x2},...,{xn}[C{y}]
        いずれもK{x1},{x2},...,{xn}[>={y}]のショートカットです。({y}省略時は固定値6で処理します。)
        出力時のテキストが、Sの場合は「サツバツ！」に、Cの場合は「クリティカル！」になります。
        こちらも複数記述することで、それぞれで追加判定が可能です。

        - SB or SB@{x}
        {x}(1-6/省略時はd6)に対応したサツバツ([S]atz-[B]atz)・クリティカル表の内容を返します。

        - WS{x}
        {x}(1-12/省略不可)に対応する[W]as[s]hoi!判定(2d6<={x})を行います

        - WSE or WSE@{x}
        {x}(1-6/省略時はd6)に対応する死神のエントリー決定表([W]as[s]hoi! [E]ntry)の内容を返します。

        - NRS_E{x} or NRS_E{x}@{y} or NRS@{y}
        ダイス{x}個で難易度[E]asy(>=3)のNRS判定({x}省略時はスキップ)を行い、失敗した場合は{y}(1～7/省略時は難易度に応じたダイス目)に対応するNRS発狂表を返します。
        「_E」部分を変更することで、難易度N,H,U,UHでも利用可能です。(Kはありません)
      TEXT

      # Base::eval_game_system_specific_commandの実装
      # @param command [String]
      # @return [String, nil]
      def eval_game_system_specific_command(command)
        # @debug = true
        debug("input: #{command}")

        begin
          case command
          when RE_JUDGE_DICEROLL
            # 2版用のダイス判定
            proc_result = proc_dice_2nd(Regexp.last_match)

            # 結果は文字列と達成値という形で受け取る
            if proc_result[1] > 0
              return Result.success(proc_result[0])
            else
              return Result.failure(proc_result[0])
            end
          else
            # ダイスでなければ定型文処理
            return proc_text(command)
          end
        rescue StandardError => e
          # 解析できずにエラーが出たら構文ミスと皆してnilを返す
          debug("#{e.message} \n#{e.backtrace}")
          return nil
        end
      end

      private

      # 文字列stringを数値化する。nilの場合はdefaultで指定された値を返す
      # @param string [String]
      # @param default [Integer]
      # @return [Integer]
      def s_to_i(string, default)
        return string.nil? ? default : string.to_i
      end

      # 判定結果の出力テキストと成功数のカウントを返す。
      # @param dice_array [Array<Integer>]
      # @param difficulty [Integer]
      # @param cmp_op [String]
      # @param title_text [String]
      # @return [String, Integer]
      def check_difficulty(dice_array, difficulty, cmp_op, title_text)
        success_num = 0
        success_dice = []
        dice_array.each do |dice_value|
          if dice_value.send(Normalize.comparison_operator(cmp_op), difficulty)
            success_num += 1
            success_dice.push(dice_value)
          end
        end

        success_dice_s = success_dice.empty? ? "" : "[#{success_dice.sort.reverse.join(',')}]"
        return "#{title_text}:#{success_num}#{success_dice_s}", success_num
      end

      # ダイス処理(2版用)
      # @param command [String]
      # @return [String, Integer]
      def proc_dice_2nd(match)
        output_text = ''
        total_success_num = 0

        difficulty = DIFFICULTY_SYMBOL_TO_INTEGER.fetch(match[1])
        appendix = match[3]

        match[2].split(",").each do |sub_command|
          dice_num = sub_command.to_i

          # D6バラバラロール
          roll_command = "#{dice_num}B6>=#{difficulty}"
          roll_result = BCDice::CommonCommand::BarabaraDice.eval(roll_command, self, @randomizer)

          output_text += "(#{roll_command}) ＞ #{roll_result.last_dice_list.join(',')} ＞ 成功数:#{roll_result.success_num}"
          success_num = roll_result.success_num

          # Appendix部分の処理
          unless appendix.nil?
            debug("---- appendix: [#{appendix}]")
            ap_command_array = appendix.split("\]\[")
            ap_command_array.each do |ap_command|
              debug("----- ap_command: #{ap_command}")
              case ap_command
              when RE_COUNT_SATZ_BATZ
                # サツバツ！カウント
                check_result = check_difficulty(roll_result.last_dice_list, s_to_i(Regexp.last_match[1], 6), ">=", "サツバツ！")
                output_text += ", #{check_result[0]}"
                success_num += check_result[1]
              when RE_COUNT_CRITICAL
                # クリティカル！カウント
                check_result = check_difficulty(roll_result.last_dice_list, s_to_i(Regexp.last_match[1], 6), ">=", "クリティカル！")
                output_text += ", #{check_result[0]}"
                success_num += check_result[1]
              when RE_COUNT_JUDGE
                # 追加判定カウント
                check_result = check_difficulty(roll_result.last_dice_list, Regexp.last_match[2].to_i, Regexp.last_match[1], "追加判定")
                output_text += ", #{check_result[0]}"
                success_num += check_result[1]
              end
            end
          end
          output_text += " \n"

          total_success_num += success_num
        end

        return output_text, total_success_num
      end

      # サツバツ！の処理を実行する
      # @param type [Integer]
      # @return [Result]
      def proc_satz_batz(type)
        # サツバツ判定(d6)
        if type > 0
          return "サツバツ!!(#{type}) ＞ #{translate('NinjaSlayer2.table.SATSUBATSU.items')[type - 1]}"
        else
          return DiceTable::Table.from_i18n("NinjaSlayer2.table.SATSUBATSU", @locale).roll(@randomizer)
        end
      end

      # Wasshoi！判定の処理を実行する
      # @param dkk [Integer]
      # @return [Result]
      def proc_wasshoi(dkk)
        dice_array = @randomizer.roll_barabara(2, 6)
        output_text = "Wasshoi!判定(2D6) ＞ (#{dice_array.join('+')}) ＞ #{dice_array.sum()}"

        if dice_array.sum() > dkk
          output_text += "(>#{dkk}) 判定失敗"
          return Result.success(output_text)
        else
          output_text += "(<=#{dkk}) 判定成功!! \nニンジャスレイヤー=サンのエントリーだ!!"
          return Result.failure(output_text)
        end
      end

      # Wasshoi！の処理を実行する
      # @param type [Integer]
      # @return [Result]
      def proc_wasshoi_entry(type)
        # Wasshoi!判定
        output_text = ""
        if type > 0
          output_text += "ニンジャスレイヤー=サンのエントリー!!(#{type}) ＞ #{translate('NinjaSlayer2.table.WASSHOI.items')[type - 1]}"
        else
          # DKKの指定無し、もしくはロール結果がDKKを超えたら死神のエントリー決定表(d6)
          table = DiceTable::Table.from_i18n("NinjaSlayer2.table.WASSHOI", @locale)
          output_text += table.roll(@randomizer).to_s
        end
        return output_text
      end

      # NRS判定の処理を実行する
      # @param dice_num [Integer]
      # @param dificulty_s [String]
      # @param type [Integer]
      # @return [Result]
      def proc_nrs(dice_num, dificulty_s, type)
        # 難易度も乱数表の番号も指定が無ければコマンドミス
        dificulty_i = dificulty_s.nil? ? 0 : DIFFICULTY_SYMBOL_TO_INTEGER.fetch(dificulty_s)
        if dificulty_i == 0 && type == 0
          return nil
        end

        # NRS判定
        output_text = ""
        if dificulty_i > 0
          roll_command = "#{dice_num}B6>=#{dificulty_i}"
          roll_result = BCDice::CommonCommand::BarabaraDice.eval(roll_command, self, @randomizer)
          output_text += "NRS判定(#{roll_command}) ＞ #{roll_result.last_dice_list.join(',')} ＞ 成功数:#{roll_result.success_num}"
          if roll_result.success_num > 0
            output_text += " NRS克服!!"
            return Result.success(output_text)
          else
            output_text += " NRS発症!! \n"
          end
        end

        # NRS発狂表の決定
        dice_face = 0
        additional = 0
        if type == 0
          case dificulty_s
          when "E"
            dice_face = 3
          when "N"
            dice_face = 6
          when "H", "U"
            dice_face = 6
            additional = 1
          end
          type = @randomizer.roll_once(dice_face) + additional
        end
        roll_command = "1D#{dice_face}#{additional > 0 ? '+' + additional.to_s : ''}"
        output_text += "NRS発狂#{dice_face > 0 ? "(#{roll_command}) ＞ " : ''}(#{type}) ＞ #{translate('NinjaSlayer2.table.NRS.items')[type - 1]}"
        return Result.failure(output_text)
      end

      # テキスト系処理
      # @param command [String]
      # @return [String, Integer]
      def proc_text(command)
        debug("text: #{command}")
        case command
        when RE_JUDGE_SATZ_BATZ
          # サツバツ判定(d6)
          return proc_satz_batz(Regexp.last_match[1].to_i)
        when RE_JUDGE_WASSHOI
          # Wasshoi!判定
          return proc_wasshoi(Regexp.last_match[1].to_i)
        when RE_JUDGE_WASSHOI_ENTRY
          # Wasshoi!判定
          return proc_wasshoi_entry(Regexp.last_match[1].to_i)
        when RE_JUDGE_NRS
          # NRS判定
          return proc_nrs(Regexp.last_match[2].to_i, Regexp.last_match[1], Regexp.last_match[3].to_i)
        end
      end

      RE_COUNT_SATZ_BATZ = /S([1-6])?/i.freeze
      RE_COUNT_CRITICAL = /C([1-6])?/i.freeze
      RE_COUNT_JUDGE = /(=|!=|>=|>|<=|<)([1-6])/.freeze

      RE_JUDGE_DICEROLL = /^(UH|[KENHU])([\d,]+)(?:\[((?:(?:S([1-6])?|C([1-6])?|(=|!=|>=|>|<=|<)([1-6]))(?:\]\[)?)+)\])?$/i.freeze
      RE_JUDGE_SATZ_BATZ = /^SB(?:@([1-6]))?$/i.freeze
      RE_JUDGE_WASSHOI = /^WS([1-9]|10|11|12)$/i.freeze
      RE_JUDGE_WASSHOI_ENTRY = /^WSE(?:@([1-6]))?$/i.freeze
      RE_JUDGE_NRS = /^NRS(?:_(E|N|H|U|UH)(\d+))?(?:@([1-7]))?$/i.freeze

      # 難易度の文字表現から整数値への対応
      DIFFICULTY_SYMBOL_TO_INTEGER = {
        'K' => 2,
        'E' => 3,
        'N' => 4,
        'H' => 5,
        'U' => 6,
        'UH' => 6
      }.freeze

      register_prefix(
        "UH",
        "[KENHU]",
        "SB",
        "WS",
        "WSE",
        "NRS"
      )
    end
  end
end
