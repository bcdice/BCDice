# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'
require 'bcdice/game_system/SRS'

module BCDice
  module GameSystem
    class SRS_Korean < SRS
      # ゲームシステムの識別子
      ID = 'SRS:Korean'

      # ゲームシステム名
      NAME = '스탠다드 RPG 시스템(SRS)'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:스탠다드 RPG 시스템(SRS)'

      HELP_MESSAGE_1 = <<~HELP_MESSAGE
        ・판정
        　・일반판정: 2D6+m@c#f>=t 또는 2D6+m>=t[c,f]
        　　수정치 m, 목표치 t, 크리티컬치 c, 펌블치 f로 판정합니다.
        　　수정치, 크리티컬치, 펌블치는 생략 가능합니다([]째로 생략 가능, @c・#f 지정 순서는 상관없음).
        　　크리티컬치, 펌블치의 기본값은 각각 12, 2입니다.
        　　자동성공, 자동실패, 성공, 실패를 자동 표시합니다.

        　　예) 2d6>=10　　　　　수정치 0, 목표치 10으로 판정
        　　예) 2d6+2>=10　　　　수정치 +2, 목표치 10으로 판정
        　　예) 2d6+2>=10[11]　　↑를 크리티컬치 11로 판정
        　　예) 2d6+2@11>=10 　　↑를 크리티컬치 11로 판정
        　　예) 2d6+2>=10[12,4]　↑를 크리티컬치 12, 펌블치 4로 판정
        　　예) 2d6+2@12#4>=10 　↑를 크리티컬치 12, 펌블치 4로 판정
        　　예) 2d6+2>=10[,4]　　↑를 크리티컬치 12, 펌블치 4로 판정 (크리티컬치 생략)
        　　예) 2d6+2#4>=10　　　↑를 크리티컬치 12, 펌블치 4로 판정 (크리티컬치 생략)
      HELP_MESSAGE

      HELP_MESSAGE_2 = <<~HELP_MESSAGE
        　・크리티컬 및 펌블만 판정: 2D6+m@c#f 또는 2D6+m[c,f]
        　　목표치를 지정하지 않고, 수정치 m, 크리티컬치 c, 펌블치 f로 판정합니다.
        　　수정치, 크리티컬치, 펌블치는 생략 가능합니다([]는 생략 불가, @c・#f 지정 순서는 상관없음).
        　　자동성공, 자동실패를 자동 표시합니다.

        　　예) 2d6[]　　　　수정치 0, 크리티컬치 12, 펌블치 2로 판정
        　　예) 2d6+2[11]　　수정치 +2, 크리티컬치 11, 펌블치 2로 판정
        　　예) 2d6+2@11 　　수정치 +2, 크리티컬치 11, 펌블치 2로 판정
        　　예) 2d6+2[12,4]　수정치 +2, 크리티컬치 12, 펌블치 4로 판정
        　　예) 2d6+2@12#4 　수정치 +2, 크리티컬치 12, 펌블치 4로 판정
      HELP_MESSAGE

      HELP_MESSAGE_3 = <<~HELP_MESSAGE
        ・D66 주사위 있음 (순서 교체 없음)
      HELP_MESSAGE

      # 既定のダイスボット説明文
      DEFAULT_HELP_MESSAGE = "#{HELP_MESSAGE_1}\n#{HELP_MESSAGE_2}\n#{HELP_MESSAGE_3}"

      HELP_MESSAGE = DEFAULT_HELP_MESSAGE

      # 成功判定のエイリアスコマンド定義用のクラスメソッドを提供するモジュール
      module ClassMethods
        # 成功判定のエイリアスコマンドの一覧
        # @return [Array<String>]
        attr_reader :aliases

        # ダイスボットの説明文を返す
        # @return [String]
        attr_reader :help_message

        # 成功判定のエイリアスコマンドを設定する
        # @param [String] aliases エイリアスコマンド（可変長引数）
        # @return [self]
        #
        # エイリアスコマンドとして指定した文字列がコマンドの先頭にあれば、
        # 実行時にそれが2D6に置換されるようになる。
        def set_aliases_for_srs_roll(*aliases)
          aliases_upcase = aliases.map(&:upcase)

          @aliases = aliases_upcase.map { |a| Regexp.escape(a) }
          @help_message = concatenate_help_messages(aliases_upcase)
          return self
        end

        # 成功判定のエイリアスコマンドを未設定にする
        # @return [self]
        def clear_aliases_for_srs_roll
          @aliases = []
          @help_message = SRS::DEFAULT_HELP_MESSAGE
          return self
        end

        private

        # ダイスボットの説明文を結合する
        # @param [Array<String>] aliases エイリアスコマンドの配列
        # @return [String] 結合された説明文
        # @todo 現在は2文字のエイリアスコマンドに幅を合わせてある。
        #   エイリアスコマンドの文字数が変わる場合があれば、位置を調整するコードが
        #   必要。
        def concatenate_help_messages(aliases)
          help_msg_for_aliases_for_target_value =
            aliases
            .map do |a|
              "　　例) #{a}+2>=10　　　　 2d6+2>=10と同じ（#{a}が2D6のショートカットコマンド）\n"
            end
            .join()
          help_msg_for_aliases_for_without_target_value =
            aliases
            .map do |a|
              "　　例) #{a}　　　　　 2d6[]と同じ（#{a}が2D6のショートカットコマンド）\n" \
              "　　例) #{a}+2@12#4　　2d6+2@12#4と同じ（#{a}が2D6のショートカットコマンド）\n"
            end
            .join()

          return "#{SRS::HELP_MESSAGE_1}" \
                 "#{help_msg_for_aliases_for_target_value}\n" \
                 "#{SRS::HELP_MESSAGE_2}" \
                 "#{help_msg_for_aliases_for_without_target_value}\n" \
                 "#{SRS::HELP_MESSAGE_3}"
        end
      end

      class << self
        # クラスが継承されたときに行う処理
        # @return [void]
        def inherited(subclass)
          subclass
            .extend(ClassMethods)
            .clear_aliases_for_srs_roll
        end

        # ダイスボットの説明文を返す
        # @return [String] 既定のダイスボット説明文
        def help_message
          DEFAULT_HELP_MESSAGE
        end

        # 成功判定のエイリアスコマンドの一覧
        # @return [Array<String>]
        def aliases
          []
        end
      end

      # 固有のコマンドの接頭辞を設定する
      register_prefix('2D6')

      # ダイスボットを初期化する
      def initialize(command)
        super(command)

        # 式、出目ともに送信する

        # バラバラロール（Bコマンド）でソートする
        @sort_add_dice = true
        # D66ダイスあり（出目をソートしない）
        @d66_sort_type = D66SortType::NO_SORT
      end

      # ダイスボットの説明文を返す
      # @return [String]
      def help_message
        self.class.help_message
      end

      # 成功判定のエイリアスコマンドの一覧
      # @return [Array<String>]
      def aliases
        self.class.aliases
      end

      # 既定のクリティカル値
      DEFAULT_CRITICAL_VALUE = 12
      # 既定のファンブル値
      DEFAULT_FUMBLE_VALUE = 2

      # 成功判定コマンドのノード
      SRSRollNode = Struct.new(
        :modifier, :critical_value, :fumble_value, :target_value
      ) do
        # 成功判定の文字列表記を返す
        # @return [String]
        def to_s
          lhs = "2D6#{Format.modifier(modifier)}"
          expression = target_value ? "#{lhs}>=#{target_value}" : lhs

          return "#{expression}[#{critical_value},#{fumble_value}]"
        end
      end

      # 固有のダイスロールコマンドを実行する
      # @param [String] command 入力されたコマンド
      # @return [Result, nil] ダイスロールコマンドの実行結果
      def eval_game_system_specific_command(command)
        legacy_c_f_match = /(.+)\[(.*)\]\z/.match(command)
        node =
          if legacy_c_f_match
            parse_legacy(legacy_c_f_match[1], legacy_c_f_match[2])
          else
            parse(command)
          end

        if node
          return execute_srs_roll(node)
        end

        return nil
      end

      private

      def parse(command)
        prefix_re = Regexp.new(["2D6"].concat(aliases()).join('|'), Regexp::IGNORECASE)
        parser = Command::Parser.new(prefix_re, round_type: @round_type)
                                .enable_critical
                                .enable_fumble
                                .restrict_cmp_op_to(nil, :>=)
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        if command.start_with?(/2D6/i) && cmd.critical.nil? && cmd.fumble.nil? && cmd.target_number.nil?
          # fallback to default dice
          return nil
        end

        cmd.critical ||= DEFAULT_CRITICAL_VALUE
        cmd.fumble ||= DEFAULT_FUMBLE_VALUE

        return SRSRollNode.new(cmd.modify_number, cmd.critical, cmd.fumble, cmd.target_number)
      end

      def parse_legacy(command, c_f)
        m = /^(-?\d+)?(?:,(-?\d+))?$/.match(c_f)
        unless m
          return nil
        end

        critical = m[1]&.to_i || DEFAULT_CRITICAL_VALUE
        fumble = m[2]&.to_i || DEFAULT_FUMBLE_VALUE

        prefix_re = Regexp.new(["2D6"].concat(aliases()).join('|'), Regexp::IGNORECASE)
        parser = Command::Parser.new(prefix_re, round_type: @round_type)
                                .restrict_cmp_op_to(nil, :>=)
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        return SRSRollNode.new(cmd.modify_number, critical, fumble, cmd.target_number)
      end

      # 成功判定を実行する
      # @param [SRSRollNode] srs_roll 成功判定ノード
      # @return [Result] 成功判定結果
      def execute_srs_roll(srs_roll)
        dice_list = @randomizer.roll_barabara(2, 6)
        dice_list.sort! if @sort_add_dice

        sum = dice_list.sum()
        dice_str = dice_list.join(",")

        modified_sum = sum + srs_roll.modifier

        result = compare_result(srs_roll, sum, modified_sum)

        parts = [
          "(#{srs_roll})",
          "#{sum}[#{dice_str}]#{Format.modifier(srs_roll.modifier)}",
          modified_sum,
          result.text
        ]

        result.text = parts.compact.join(' ＞ ')
        result
      end

      # ダイスロール結果を目標値、クリティカル値、ファンブル値と比較する
      # @param [SRSRollNode] srs_roll 成功判定ノード
      # @param [Integer] sum 出目の合計
      # @param [Integer] modified_sum 修正後の値
      # @return [Result] 比較結果
      def compare_result(srs_roll, sum, modified_sum)
        if sum >= srs_roll.critical_value
          Result.critical("자동성공")
        elsif sum <= srs_roll.fumble_value
          Result.fumble("자동실패")
        elsif srs_roll.target_value.nil?
          Result.new
        elsif modified_sum >= srs_roll.target_value
          Result.success("성공")
        else
          Result.failure("실패")
        end
      end
    end
  end
end
