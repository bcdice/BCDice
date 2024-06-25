# frozen_string_literal: true

module BCDice
  module GameSystem
    class TheOneRing2nd < Base
      # ゲームシステムの識別子
      ID = "TheOneRing2nd"

      # ゲームシステム名
      NAME = "一つの指輪：指輪物語TRPG2版"

      # ゲームシステム名の読みがな
      SORT_KEY = "ひとつのゆひわゆひわものかたりTRPG2"

      HELP_MESSAGE = <<~TEXT
        ・判定コマンド(nRG[x][@y][Az][f[0|1]][i[0|1]][w[0|1]][m[0|1]])
         判定用に難易度nを指定して判定ダイスを振る。技量ダイスx、痛打判定値y、修正値zを指定可能。
         技量ダイス、痛打判定値、修正値は0、または未指定（0と同じ）にできる。
         痛打判定値の0、未指定は痛打判定を行わない。
         修正値は判定合計値に加算され、「ガンダルフ・ルーン」や「サウロンの目」はその影響を受けない。
         例1: 13RG     (難易度13 技量ダイス0個)
         例2: 13RG3    (難易度13 技量ダイス3個)
         例3: 13RG3@10A1  (難易度13 技量ダイス3個、痛打判定10、結果に1を加算)

        ・表用コマンド(FD[x][f[0|1]][i[0|1]])
         表用に判定ダイスを振る。修正値xが指定可能。修正値は0、あるいは未指定(0と同じ)にできる。
         「ガンダルフ・ルーン」や「サウロンの目」は修正値の影響を受けず、値が10を越えることもない。
         例1: FD      (1d12で判定)
         例2: FD1     (1d12で判定し、ダイス目に+1修正)

        ・コマンドオプション
        オプションは、判定コマンドなら4個まで、表用コマンドなら2個まで、順不同で指定可能（重複可）。
          f: 有利(favoured)オプション。不利と同時指定時は相殺。選択された値に◎。
          i: 不利(ill-favoured)オプション。有利と同時指定時は相殺。選択された値に◎。
         例1: 13RG3f   (難易度13 技量ダイス3個、有利)
         例2: FD1f     (1修正、有利)
         例3: 13RG3if   (難易度13 技量ダイス3個、不利、有利)
              ※有利/不利は相殺。

         判定コマンドでは更に下記のオプションを同じ条件で指定可能。
          w: 疲労(weary)状態オプション。
          m: 絶望(miserable)状態オプション。
         例1: 13RG3wf   (難易度13 技量ダイス3個、疲労状態、有利)
         例2: 13RG3fiwm (難易度13 技量ダイス3個、有利、不利、疲労状態、絶望状態)
              ※有利/不利は相殺。最大オプション数である4つを指定。

        ・オプションスイッチ
         指定したオプションのon/offを1/0で指定可能。1はon、0はoffを表す。
         複数の同じオプションへのスイッチ指定は、最後のスイッチが有効となる。
         例1: 13RG3if0  (難易度13 技量ダイス3個、不利はon、有利はoff)
              ※ 有利指定がoffのため、相殺されず不利となる。
         例2: 13RG3f1f0 (難易度13 技量ダイス3個、有利は最終的にoff)
      TEXT

      register_prefix('\d+RG', 'FD')

      SAURONS_EYE_NUMBER        = 11 # サウロンの目
      GANDALF_RUNE_NUMBER       = 12 # ガンダルフ・ルーン

      CHOICE_DIE_MARK = '◎' # 有利/不利の状態で選択されたダイスにつけるマーク

      # 有利/不利状態のenum
      module FavouredState
        NORMAL = -98 # 通常状態
        FAVOURED = -99 # 有利状態
        ILLFAVOURED = -100 # 不利状態
      end

      def eval_game_system_specific_command(command)
        case command
        when /^\d+RG/i
          return rg_command_exec(command)
        when /^FD/i
          return fd_command_exec(command)
        end
        return "Error" # 到達しないはずだが、念のため
      end

      private

      # ================ RG/FGコマンド共有メソッド等 ================#

      # オプションデータクラス
      class OptionData
        attr_reader :favoured_state, :weary, :miserable

        def initialize(favoured_state_value: FavouredState::NORMAL, weary_condition: false, miserable_condition: false)
          @favoured_state = favoured_state_value
          @weary = weary_condition
          @miserable = miserable_condition
        end
      end

      # 指定された修正値文字列を取得
      def get_adjust_number_text(adjust_number)
        adjust_number_text = ""

        if adjust_number > 0
          adjust_number_text = "+#{adjust_number}"
        elsif adjust_number < 0
          adjust_number_text = adjust_number.to_s
        end

        return adjust_number_text
      end

      # 指定された状態文字列を取得
      def get_condition_text(opts)
        if opts.favoured_state == FavouredState::NORMAL && !opts.weary && !opts.miserable
          return ""
        end

        condition_text = "\n状態："
        if opts.favoured_state == FavouredState::FAVOURED
          condition_text = "#{condition_text}有利 "
        elsif opts.favoured_state == FavouredState::ILLFAVOURED
          condition_text = "#{condition_text}不利 "
        end
        if opts.weary
          condition_text = "#{condition_text}疲労 "
        end
        if opts.miserable
          condition_text = "#{condition_text}絶望 "
        end

        return condition_text.rstrip
      end

      # 指定された状態文字列を取得
      def get_options(opt_params)
        favoured_state_value = FavouredState::NORMAL
        miserable_condition = false
        weary_condition = false

        opt_params.each do |x|
          case x[/[WFIM]/]
          when "W"
            weary_condition = on_option_switch?(x)
          when "F"
            favoured_state_value = get_favoured_state(on_option_switch?(x), favoured_state_value, FavouredState::FAVOURED)
          when "I"
            favoured_state_value = get_favoured_state(on_option_switch?(x), favoured_state_value, FavouredState::ILLFAVOURED)
          when "M"
            miserable_condition = on_option_switch?(x)
          end
        end

        return OptionData.new(favoured_state_value: favoured_state_value, weary_condition: weary_condition, miserable_condition: miserable_condition)
      end

      # オプションから有利/不利状態指定を取得
      def get_favoured_state(option_switch, before_favoured_state_value, tagert_state_type)
        if option_switch
          if before_favoured_state_value == tagert_state_type || before_favoured_state_value == FavouredState::NORMAL
            return tagert_state_type
          end

          return FavouredState::NORMAL
        else
          if before_favoured_state_value == tagert_state_type
            return FavouredState::NORMAL
          end
        end
        return before_favoured_state_value
      end

      # オプションのON/OFFを取得
      def on_option_switch?(opt_value)
        if opt_value.length == 1 || opt_value[1..opt_value.length].to_i > 0
          return true
        end

        return false
      end

      # 技量ダイスロールを行う
      def make_successdice_roll(success_dice_count, weary_condition)
        dice_list = @randomizer.roll_barabara(success_dice_count, 6)
        success_count = dice_list.count(6)
        if weary_condition
          success_total_number = dice_list.reject { |i| i <= 3 }.sum
        else
          success_total_number = dice_list.sum
        end
        return dice_list.to_s, success_total_number, success_count
      end

      # 判定ダイスロールを行う
      def make_featdice_roll(favoured_state_value)
        feat_dice_count = favoured_state_value == FavouredState::NORMAL ? 1 : 2
        dice_list = @randomizer.roll_barabara(feat_dice_count, 12)

        choice_die_number = die_choice(dice_list, favoured_state_value)
        if feat_dice_count > 1

          choice_index = dice_list.find_index(choice_die_number)

          first_die = "#{CHOICE_DIE_MARK if choice_index == 0}#{get_specal_die_str(dice_list[0])}"
          second_die = "#{CHOICE_DIE_MARK if choice_index == 1}#{get_specal_die_str(dice_list[1])}"

          feat_result_text = "[#{first_die}, #{second_die}]"
        else
          feat_result_text = "[#{get_specal_die_str(choice_die_number)}]"
        end

        return feat_result_text, choice_die_number, feat_dice_count
      end

      # 有利/不利を含めて判定ダイスの結果を取得
      def die_choice(dice_list, favoured_state_value)
        if favoured_state_value == FavouredState::ILLFAVOURED
          if dice_list.count(SAURONS_EYE_NUMBER) >= 1
            return SAURONS_EYE_NUMBER
          else
            return dice_list.min
          end
        elsif favoured_state_value == FavouredState::FAVOURED
          if dice_list.count(GANDALF_RUNE_NUMBER) >= 1
            return GANDALF_RUNE_NUMBER
          else
            # ガンダルフ・ルーンが無ければサウロンの目を除いた最大値を選ぶ
            # ※ どちらもサウロンの目ならサウロンの目を返す
            return dice_list.count(SAURONS_EYE_NUMBER) == 2 ? SAURONS_EYE_NUMBER : dice_list.reject { |x| x == SAURONS_EYE_NUMBER }.max
          end
        end
        return dice_list[0]
      end

      # 判定ダイスが特殊ダイス目だった場合、該当文字列に変換する
      def get_specal_die_str(die_number)
        if die_number == GANDALF_RUNE_NUMBER
          return "ガンダルフ・ルーン"
        elsif die_number == SAURONS_EYE_NUMBER
          return "サウロンの目"
        end

        return die_number
      end

      # ================ FDコマンド ================#

      FD_ADJUST_NUMBER_INDEX    = 2
      FD_OPTION_START_INDEX     = 3

      # FDコマンド実行
      def fd_command_exec(command)
        m = /\A(FD)(-?\d*)?([FI]-?\d*)?([FI]-?\d*)?$/.match(command)
        unless m
          return ''
        end

        # コマンドパラメータ取得
        adjust_number, opts = get_fd_params(m)

        # 判定ダイス処理
        feat_result_text, feat_die_number, feat_dice_count = make_featdice_roll(opts.favoured_state)
        result_header_text = "(#{feat_dice_count}D12"

        return get_fd_roll_result(result_header_text, feat_result_text, feat_die_number, feat_dice_count, adjust_number)
      end

      # FDコマンド判定結果の取得
      def get_fd_roll_result(result_header_text, feat_result_text, feat_die_number, feat_dice_count, adjust_number)
        # 修正値処理
        reslt_die_number, adjust_number_text = get_fd_adjust(feat_die_number, adjust_number)

        result_header_text = "#{result_header_text}#{adjust_number_text}) ＞ #{feat_result_text}#{adjust_number_text}"
        if adjust_number != 0 || feat_dice_count != 1
          return "#{result_header_text} ＞ [#{get_specal_die_str(reslt_die_number)}]"
        end

        return result_header_text
      end

      # FDコマンドの修正値取得
      def get_fd_adjust(feat_die_number, adjust_number)
        if [SAURONS_EYE_NUMBER, GANDALF_RUNE_NUMBER].include?(feat_die_number)
          return feat_die_number, get_adjust_number_text(adjust_number)
        end

        res_total_num = feat_die_number + adjust_number
        if res_total_num > 10
          res_total_num = 10
        elsif res_total_num < 1
          res_total_num = 1
        end
        return res_total_num, get_adjust_number_text(adjust_number)
      end

      # FDコマンドパラメータの取得
      def get_fd_params(m)
        adjust_number = m[FD_ADJUST_NUMBER_INDEX].to_i

        opt_params = m[FD_OPTION_START_INDEX..m.length].compact

        return adjust_number, get_options(opt_params)
      end

      # ================ RGコマンド ================#

      RG_DIFFICULTY_INDEX       = 1
      RG_SUCCESS_DICE_INDEX     = 3
      RG_PIERCING_BLOWS_INDEX   = 5
      RG_ADJUST_NUMBER_INDEX    = 7
      RG_OPTION_START_INDEX     = 8

      # RGコマンド実行
      def rg_command_exec(command)
        m = /\A(\d+)(RG)(\d*)(@(\d{0,2}))?(A(-?\d*))?([WFIM]-?\d*)?([WFIM]-?\d*)?([WFIM]-?\d*)?([WFIM]-?\d*)?$/.match(command)
        unless m
          return ''
        end

        success_count = 0

        # コマンドパラメータ取得
        difficulty, success_dice_count, piercing_blows_number, adjust_number, opts = get_rg_params(m)

        # 判定ダイス処理
        feat_result_text, feat_die_number, feat_dice_count = make_featdice_roll(opts.favoured_state)
        total_dice_number = (feat_die_number != SAURONS_EYE_NUMBER ? feat_die_number : 0)

        result_header_text = "(#{feat_dice_count}D12"
        result_dice_text = feat_result_text

        # 技量ダイスが指定されているならその処理
        if success_dice_count > 0
          success_result_text, success_total_number, success_count = make_successdice_roll(success_dice_count, opts.weary)
          total_dice_number += success_total_number

          result_header_text = "#{result_header_text}+#{success_dice_count}D6"
          result_dice_text = "#{result_dice_text}+#{success_result_text}"
        end

        # 修正値処理
        total_dice_number, adjust_number_text = get_rg_adjust(total_dice_number, adjust_number)

        result_header_text = "#{result_header_text}#{adjust_number_text}) ＞ #{result_dice_text}#{adjust_number_text}"

        return get_rg_roll_result(result_header_text, difficulty, feat_die_number, piercing_blows_number, total_dice_number, success_count, opts)
      end

      # 修正値と修正値テキストの取得
      def get_rg_adjust(total_dice_number, adjust_number)
        total_dice_number += adjust_number
        total_dice_number = 0 if total_dice_number < 0

        return total_dice_number, get_adjust_number_text(adjust_number)
      end

      # RGコマンド判定結果の取得
      def get_rg_roll_result(result_header_text, difficulty, feat_die_number, piercing_blows_number, total_dice_number, success_count, opts)
        # 状態表示取得
        condition_text = get_condition_text(opts)

        success_count_text = "成功度 #{success_count}"

        # 痛打判定をブロック化
        piercing_blows = lambda() { |feat_die_num, piercing_blows_num, res_text, cond_text|
          if piercing_blows_num > 0 && feat_die_num >= piercing_blows_num && feat_die_num != SAURONS_EYE_NUMBER
            res_text = "#{res_text} 痛打発生！"
          end
          return "#{res_text}#{cond_text}"
        }

        if feat_die_number == GANDALF_RUNE_NUMBER
          gandalf_rune_text = "#{result_header_text}：自動成功[#{success_count_text}]"
          gandalf_rune_text = piercing_blows.call(feat_die_number, piercing_blows_number, gandalf_rune_text, condition_text)
          if success_count >= 2
            return Result.critical(gandalf_rune_text)
          end

          return Result.success(gandalf_rune_text)
        elsif opts.miserable && feat_die_number == SAURONS_EYE_NUMBER
          return Result.failure("#{result_header_text}：自動失敗#{condition_text}")
        end

        result_detail_text = "難易度 #{difficulty} 達成値 #{total_dice_number}"
        if difficulty > total_dice_number
          return Result.failure("#{result_header_text} #{result_detail_text}：失敗#{condition_text}")
        end

        success_text = "#{result_header_text} #{result_detail_text}：成功[#{success_count_text}]"
        success_text = piercing_blows.call(feat_die_number, piercing_blows_number, success_text, condition_text)
        if success_count >= 2
          return Result.critical(success_text)
        end

        return Result.success(success_text)
      end

      # RGコマンドパラメータの取得
      def get_rg_params(m)
        difficulty = m[RG_DIFFICULTY_INDEX].to_i

        success_dice_count = m[RG_SUCCESS_DICE_INDEX].to_i
        adjust_number = m[RG_ADJUST_NUMBER_INDEX].to_i
        piercing_blows_number = m[RG_PIERCING_BLOWS_INDEX]&.to_i || -1 # -1は痛打判定自体を行わない

        opt_params = m[RG_OPTION_START_INDEX..m.length].compact

        return difficulty, success_dice_count, piercing_blows_number, adjust_number, get_options(opt_params)
      end
    end
  end
end
