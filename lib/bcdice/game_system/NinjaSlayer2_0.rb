# frozen_string_literal: true

require "bcdice/game_system/NinjaSlayer"

module BCDice
  module GameSystem
    class NinjaSlayer2_0 < NinjaSlayer
      # ゲームシステムの識別子
      ID = "NinjaSlayer2.0"

      # ゲームシステム名
      NAME = "ニンジャスレイヤー(2.0版)"

      # ゲームシステム名の読みがな
      SORT_KEY = "にんしやすれいやあ2.0"

      HELP_MESSAGE = <<~TEXT
        - K{x1},{x2},...,{xn}
        難易度K([K]ids)の成功判定({x1}B6>=2)を、{x1}～{xn}で指定された分だけ実行します。
        先頭の文字を変えることで、難易度E([E]asy),N([N]ormal),H([H]ard),U([U]ltra-hard)でも実行可能です。(以下も同様)

        - K{x1},{x2},...,{xn}[>={y}]
        K{x1}のロールの結果を使って、[]内で指定された条件を満たすダイスの個数を追加で出力します。
        判定式は「>=」の他に「>」「<=」「<」「=」「!=」が利用可能です。
        [=5][=6]のように複数記述することで、それぞれで追加判定が可能です。

        - K{x1},{x2},...,{xn}[S] or K{x1},{x2},...,{xn}[S{y}]
        - K{x1},{x2},...,{xn}[C] or K{x1},{x2},...,{xn}[C{y}]
        いずれもK{x1},{x2},...,{xn}[>={y}]のショートカットです。({y}省略時は固定値6で処理します。)
        出力時のテキストが、Sの場合は「サツバツ！」に、Cの場合は「クリティカル！」になります。
        こちらも複数記述することで、それぞれで追加判定が可能です。

        - SB or SB@{x} / {x}(1-6/省略時はd6)に対応したサツバツ([S]atz-[B]atz)・クリティカル表の内容を返します。
        - WS{x} / {x}(1-12)に対応する[W]as[s]hoi!判定(2d6<={x})を行います
        - WSE or WSE@{x} / {x}(1-6/省略時はd6)に対応する死神のエントリー決定表([W]as[s]hoi! [E]ntry)の内容を返します。
        - NAM or NAM@{x1},{x2} / {x1}{x2}(共に11～66/省略時はd66)に対応するニンジャ名([Nam]e)を返します。
        - STA / d6を4回振って、カラテ/ニューロン/ワザマエ/ジツの値([Sta]tus)を返します。
        - JIT or JIT@{x} / {x}(1-6/省略時はd6)に対応する初期ジツ系統([Jit]su)を返します。
        - SKI or SKI@{x} / {x}(1-6/省略時はd6)に対応する初期スキル([Ski]ll)を返します。
        - KNO or KNO@{x} / {x}(1-6/省略時はd6)に対応する初期知識スキル([Kno]wledge)を返します。
        - ITE or ITE@{x} / {x}(1-6/省略時はd6)に対応する初期アイテム([Ite]m)を返します。
        - CYB or CYB@{x} / {x}(1-6/省略時はd6)に対応する初期サイバネ([Cyb]ernetics)を返します。
        - BAC or BAC@{x} / {x}(11～66/省略時はd66)に対応する生い立ち([Bac]kground)を返します。
        - NB / 新規ニンジャ([N]ew[b]ie)、上記のNAM～CYBをまとめて振ってまとめて返します。

        - NRS_E{x} or NRS_E{x}@{y} or NRS@{y}
        ダイス{x}個で難易度[E]asy(>=3)のNRS判定({x}省略時はスキップ)を行い、失敗した場合は{y}(1～7/省略時は難易度に応じたダイス目)に対応するNRS発狂表を返します。
        「_E」部分を変更することで、難易度N,H,Uでも利用可能です。(Kはありません)

        ◆その他◆
        ダイスボット「ニンジャスレイヤーTRPG」に存在していたコマンドも引き続き利用可能です。
      TEXT

      RE_COUNT_SATZ_BATZ = /S([1-6])?/i.freeze
      RE_COUNT_CRITICAL = /C([1-6])?/i.freeze
      RE_COUNT_JUDGE = /(=|!=|>=|>|<=|<)([1-6])/.freeze

      RE_JUDGE_DICEROLL = /^([KENHU])([\d,]+)(?:\[((?:(?:#{RE_COUNT_SATZ_BATZ}|#{RE_COUNT_CRITICAL}|#{RE_COUNT_JUDGE})(?:\]\[)?)+)\])?$/i.freeze
      RE_JUDGE_SATZ_BATZ = /^SB(?:@([1-6]))?$/i.freeze
      RE_JUDGE_WASSHOI = /^WS([1-9]|10|11|12)$/i.freeze
      RE_JUDGE_WASSHOI_ENTRY = /^WSE(?:@([1-6]))?$/i.freeze
      RE_JUDGE_NRS = /^NRS(?:_(E|N|H|U)(\d+))?(?:@([1-7]))?$/i.freeze

      RE_OLD_COMMAND = /^(?:EV|AT|EL|NJ)/i.freeze
      RE_OLD_NJ_COMMAND = /^NJ(\d+)#{DIFFICULTY_RE}?$/i.freeze

      # 難易度の文字表現から整数値への対応
      DIFFICULTY_SYMBOL_TO_INTEGER = {
        'K' => 2,
        'E' => 3,
        'N' => 4,
        'H' => 5,
        'U' => 6,
        'UH' => 6
      }.freeze

      # 文字列stringを数値化する。nilの場合はdefaultで指定された値を返す
      # @param string [String]
      # @param default [Integer]
      # @return [Integer]
      def s_to_i(string, default)
        return string.nil? ? default : string.to_i
      end
      private :s_to_i

      # キャラクターのランダム名の出力テキストを生成する
      # @param specified_dice_a [String]
      # @param specified_dice_b [String]
      # @return [String]
      def create_name_text(specified_dice_a, specified_dice_b)
        dice_a = []
        dice_b = []
        dice_type = nil
        if specified_dice_a.nil? || specified_dice_b.nil?
          dice_a = @randomizer.roll_barabara(2, 6)
          dice_b = @randomizer.roll_barabara(2, 6)
          dice_type = "(D66,D66)"
        else
          dice_a[0] = specified_dice_a[0].to_i
          dice_a[1] = specified_dice_a[1].to_i
          dice_b[0] = specified_dice_b[0].to_i
          dice_b[1] = specified_dice_b[1].to_i
        end
        return "◆ニンジャ名#{dice_type.nil? ? '' : (dice_type + ' ＞ ')}(#{dice_a.join('')},#{dice_b.join('')}) ＞ #{translate('NinjaSlayer2_0.table.NAME_A.items')[dice_a[0] - 1][dice_a[1] - 1]} #{translate('NinjaSlayer2_0.table.NAME_B.items')[dice_b[0] - 1][dice_b[1] - 1]}"
      end
      private :create_name_text

      # キャラクターの基礎能力値を生成する
      # @return [Array<Integer>, Integer, Integer, Integer, Integer]
      def create_status_values()
        dice_array = @randomizer.roll_barabara(4, 6)
        return dice_array, dice_array[0], dice_array[1], dice_array[2], dice_array[3] > 3 ? (dice_array[3] - 3) : 0
      end
      private :create_status_values

      # キャラクターの基礎能力値を元に、出力テキストを生成する
      # @param dice_array [Array<Integer>]
      # @param karate [Integer]
      # @param neuron [Integer]
      # @param wazamae [Integer]
      # @param jitsu [Integer]
      # @return [String]
      def create_status_text(dice_array, karate, neuron, wazamae, jitsu)
        return "◆基礎能力値(4B6) ＞ (#{dice_array.join(',')}) ＞ カラテ:#{karate}, ニューロン:#{neuron}, ワザマエ:#{wazamae}, ジツ:#{jitsu} (スクラッチビルド#{karate + neuron + wazamae + jitsu * 2}ポイント相当)"
      end
      private :create_status_text

      # キャラクターの初期ジツ系統の出力テキストを生成する
      # @param specified_dice [String]
      # @return [String]
      def create_jitsu_text(specified_dice)
        if specified_dice.nil?
          return DiceTable::Table.from_i18n('NinjaSlayer2_0.table.JITSU', @locale).roll(@randomizer).to_s
        else
          return "◆初期ジツ系統(#{specified_dice}) ＞ #{translate('NinjaSlayer2_0.table.JITSU.items')[specified_dice.to_i - 1]}"
        end
      end
      private :create_jitsu_text

      # キャラクターの初期スキルの出力テキストを生成する
      # @param specified_dice [String]
      # @return [String]
      def create_skill_text(specified_dice)
        if specified_dice.nil?
          return DiceTable::Table.from_i18n('NinjaSlayer2_0.table.SKILL', @locale).roll(@randomizer).to_s
        else
          return "◆初期スキル(#{specified_dice}) ＞ #{translate('NinjaSlayer2_0.table.SKILL.items')[specified_dice.to_i - 1]}"
        end
      end
      private :create_skill_text

      # キャラクターの初期知識スキルの出力テキストを生成する
      # @param specified_dice [String]
      # @return [String]
      def create_knowledge_text(specified_dice)
        if specified_dice.nil?
          return DiceTable::D66GridTable.from_i18n('NinjaSlayer2_0.table.KNOWLEDGE', @locale).roll(@randomizer).to_s
        else
          return "◆初期知識スキル(#{specified_dice}) ＞ #{translate('NinjaSlayer2_0.table.KNOWLEDGE.items')[specified_dice.split('')[0].to_i - 1][specified_dice.split('')[1].to_i - 1]}"
        end
      end
      private :create_knowledge_text

      # キャラクターの初期アイテムの出力テキストを生成する
      # @param specified_dice [String]
      # @return [String]
      def create_item_text(specified_dice)
        if specified_dice.nil?
          return DiceTable::Table.from_i18n('NinjaSlayer2_0.table.ITEM', @locale).roll(@randomizer).to_s
        else
          return "◆初期アイテム(#{specified_dice}) ＞ #{translate('NinjaSlayer2_0.table.ITEM.items')[specified_dice.to_i - 1]}"
        end
      end
      private :create_item_text

      # キャラクターの初期サイバネの出力テキストを生成する
      # @param specified_dice [String]
      # @return [String]
      def create_cybernetics_text(specified_dice)
        if specified_dice.nil?
          return DiceTable::Table.from_i18n('NinjaSlayer2_0.table.CYBERNETICS', @locale).roll(@randomizer).to_s
        else
          return "◆初期サイバネ(#{specified_dice}) ＞ #{translate('NinjaSlayer2_0.table.CYBERNETICS.items')[specified_dice.to_i - 1]}"
        end
      end
      private :create_cybernetics_text

      # キャラクターの生い立ちの出力テキストを生成する
      # @param specified_dice [String]
      # @return [String]
      def create_background_text(specified_dice)
        if specified_dice.nil?
          return DiceTable::D66GridTable.from_i18n('NinjaSlayer2_0.table.BACKGROUND', @locale).roll(@randomizer).to_s
        else
          return "◆生い立ち(#{specified_dice}) ＞ #{translate('NinjaSlayer2_0.table.BACKGROUND.items')[specified_dice.split('')[0].to_i - 1][specified_dice.split('')[1].to_i - 1]}"
        end
      end
      private :create_background_text

      # 新規キャラクター１人分の出力テキストを生成する
      # @return [String]
      def create_character_text()
        # ニンジャ名
        output_text = "#{create_name_text(nil, nil)} \n\n"

        # 基礎能力値
        dice_array, karate, neuron, wazamae, jitsu = create_status_values()
        output_text += "#{create_status_text(dice_array, karate, neuron, wazamae, jitsu)} \n\n"

        if jitsu > 0
          # 初期ジツ系統
          output_text += "#{create_jitsu_text(nil)} \n\n"
        else
          # 初期スキル
          output_text += "#{create_skill_text(nil)} \n\n"
        end

        # 初期知識スキル
        output_text += "#{create_knowledge_text(nil)} \n\n"
        # 初期アイテム
        output_text += "#{create_item_text(nil)} \n\n"
        # 初期サイバネ
        output_text += create_cybernetics_text(nil).to_s

        return output_text
      end
      private :create_character_text

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
          comparison_s = "#{dice_value}#{cmp_op == '=' ? '==' : cmp_op}#{difficulty}"
          if Kernel.eval(comparison_s)
            success_num += 1
            success_dice.push(dice_value)
          end
        end

        success_dice_s = success_dice.empty? ? "" : "[#{success_dice.sort.reverse.join(',')}]"
        return "#{title_text}:#{success_num}#{success_dice_s}", success_num
      end
      private :check_difficulty

      # ダイス処理。
      # @param command [String]
      # @return [String, Integer]
      def proc_dice(command)
        output_text = ''
        total_success_num = 0

        RE_JUDGE_DICEROLL.match(command)
        difficulty = DIFFICULTY_SYMBOL_TO_INTEGER.fetch(Regexp.last_match[1])
        appendix = Regexp.last_match[3]

        Regexp.last_match[2].split(",").each do |sub_command|
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
      private :proc_dice

      # サツバツ！の処理を実行する
      # @param type [Integer]
      # @return [Result]
      def proc_satz_batz(type)
        # サツバツ判定(d6)
        if type > 0
          return Result.critical("サツバツ!!(#{type}) ＞ #{translate('NinjaSlayer2_0.table.SATSUBATSU.items')[type - 1]}")
        else
          return Result.critical(DiceTable::Table.from_i18n("NinjaSlayer2_0.table.SATSUBATSU", @locale).roll(@randomizer).to_s)
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
          output_text += "ニンジャスレイヤー=サンのエントリー!!(#{type}) ＞ #{translate('NinjaSlayer2_0.table.WASSHOI.items')[type - 1]}"
        else
          # DKKの指定無し、もしくはロール結果がDKKを超えたら死神のエントリー決定表(d6)
          table = DiceTable::Table.from_i18n("NinjaSlayer2_0.table.WASSHOI", @locale)
          output_text += table.roll(@randomizer).to_s
        end
        return Result.failure(output_text)
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
        output_text += "NRS発狂#{dice_face > 0 ? "(#{roll_command}) ＞ " : ''}(#{type}) ＞ #{translate('NinjaSlayer2_0.table.NRS.items')[type - 1]}"
        return Result.fumble(output_text)
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
        else
          # 初期データ作成
          return Result.new.tap do |r|
            r.text =
              case command
              when /^NAM(?:@([1-6][1-6]),([1-6][1-6]))?$/i
                create_name_text(Regexp.last_match[1], Regexp.last_match[2])
              when "STA"
                dice_array, karate, neuron, wazamae, jitsu = create_status_values()
                create_status_text(dice_array, karate, neuron, wazamae, jitsu)
              when /^JIT(?:@([1-5]))?$/
                create_jitsu_text(Regexp.last_match[1])
              when /^SKI(?:@([1-6]))?$/
                create_skill_text(Regexp.last_match[1])
              when /^KNO(?:@([1-6][1-6]))?$/i
                create_knowledge_text(Regexp.last_match[1])
              when /^ITE(?:@([1-6]))?$/i
                create_item_text(Regexp.last_match[1])
              when /^CYB(?:@([1-6]))?$/i
                create_cybernetics_text(Regexp.last_match[1])
              when /^BAC(?:@([1-6][1-6]))?$/i
                create_background_text(Regexp.last_match[1])
              when "NB"
                create_character_text()
              end
          end
        end
      end

      # Base::eval_game_system_specific_commandの実装
      # @param command [String]
      # @return [String, nil]
      def eval_game_system_specific_command(command)
        # @debug = true
        debug("input: #{command}")

        begin
          # 1版のコマンドにマッチしたら1版側の処理
          if RE_OLD_COMMAND.match(command)
            # 1版のNJコマンドはコメント付きの処理にバグを抱えているため、修正されるまでは手動で処理
            if RE_OLD_NJ_COMMAND.match(command)
              dice_num = Regexp.last_match[1].to_i
              dificulty_s = Regexp.last_match[2] || Regexp.last_match[3]
              dificulty_i = dificulty_s.to_i
              if dificulty_i == 0
                dificulty_i = dificulty_s.nil? ? 4 : DIFFICULTY_SYMBOL_TO_INTEGER.fetch(dificulty_s)
              end

              roll_command = "#{dice_num}B6>=#{dificulty_i}"
              roll_result = BCDice::CommonCommand::BarabaraDice.eval(roll_command, self, @randomizer)

              output_text = "(#{roll_command}) ＞ #{roll_result.last_dice_list.join(',')} ＞ 成功数#{roll_result.success_num}"

              if roll_result.success_num > 0
                return Result.success(output_text)
              else
                return Result.failure(output_text)
              end
            else
              return super(command)
            end
          end

          # ここからが2版用の処理
          case command
          when RE_JUDGE_DICEROLL
            # ダイス判定
            proc_result = proc_dice(command)

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

      register_prefix(
        RE_JUDGE_DICEROLL,
        RE_JUDGE_SATZ_BATZ,
        RE_JUDGE_WASSHOI,
        RE_JUDGE_WASSHOI_ENTRY,
        RE_JUDGE_NRS
      )
      register_prefix('NB', 'NAM', "STA", 'SKI', 'JIT', 'KNO', 'ITE', 'CYB', 'BAC')

      # 1版互換用のコマンド登録
      register_prefix("NJ", "EV", "AT", "EL")

      # 1版はchange_textでNJx[y]をxB6>=yに変換しており、これが元でNJ系コマンドにコメントが付くと正常に処理できないバグが存在する。
      # 詳細は省くが、これを回避するためchange_textの処理を潰し、NJ系コマンドはこちらのeval_game_system_specific_commandで処理する形とする。
      def change_text(string)
        return string
      end
    end
  end
end
