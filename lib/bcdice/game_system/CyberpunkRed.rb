# frozen_string_literal: true

require "bcdice/game_system/cyberpunk_red/tables"

module BCDice
  module GameSystem
    class CyberpunkRed < Base
      # ゲームシステムの識別子
      ID = 'CyberpunkRed'

      # ゲームシステム名
      NAME = 'サイバーパンクRED'

      # ゲームシステム名の読みがな
      SORT_KEY = 'さいはあはんくれつと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ・判定　CPx+y>=z
        　(x＝能力値と技能値の合計、y＝修正値、z＝難易度 or 受動側　x、y、zは省略可)
        　例）CP12 CP10+2>=12　CP7-1　CP8+4　CP7>=12　CP　CP>=9
        ・イニシアティブを振る　INIx
        　(x＝反応)
        　例）INI8

        各種表
        ・致命的損傷表
        　FFD　：身体への致命的損傷
        　HFD　：頭部への致命的損傷
        ・遭遇表
        　NCDT　：ナイトシティ(日中)
        　NCNT　：ナイトシティ(夜間)
        　NCMT　：ナイトシティ(深夜)
        ・ナイトマーケット表
        　MKTT　：ナイトマーケット(分類のみ)
        　MKTK　：ナイトマーケット表
        　MKTE　：食品とドラッグ
        　MKTD　：個人用電子機器
        　MKTW　：武器と防具
        　MKTC　：サイバーウェア
        　MKTF　：衣料品とファッションウェア
        　MKTS　：サバイバル用品
        ・スクリームシート
        　SCSR　：スクリームシート(ランダム)
        　SCST　：スクリームシート分類
        　SCSA　：ヘッドラインA
        　SCSB　：ヘッドラインB
        　SCSC　：ヘッドラインC
        ・最寄りの自販機
        　VMCR　：最寄りの自販機表
        　VMCT　：自販機タイプ決定表
        　VMCE　：食品
        　VMCF　：ファッション
        　VMCS　：変なもの
        ・ボデガの客
        　STORE　：ボデガの客と店員
        　STOREA　：店主またはレジ係
        　STOREB　：変わった客その1
        　STOREC　：変わった客その2
      HELP

      # 判定の正規表現
      CP_RE = /^CP(?<ability>\d+)?(?<modifier>[+-]\d+)?(?<target>>=\d+)?/.freeze

      # イニシアティブロールの正規表現
      INI_RE = /^INI(?<initiative>\d+)/.freeze

      def initialize(command)
        super(command)

        @sort_add_dice = false
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command begin string", command)

        case command
        when CP_RE
          return cp_roll_result(command)
        when INI_RE
          return ini_roll_result(command)
        end

        debug("各種表として処理")
        roll_tables(command, TABLES)
      end

      private_constant :CP_RE, :INI_RE
      private

      def cp_roll_result(command)
        parser = Command::Parser.new('CP', round_type: RoundType::FLOOR).enable_suffix_number.enable_question_target
        parsed = parser.parse(command)
        return nil if parsed.nil?

        dice_cnt = 1
        dice_face = 10
        modify_number = 0
        total = 0

        result = Result.new

        dices = []
        dices << @randomizer.roll_once(dice_face)
        total += dices.first
        modify_number += parsed.suffix_number if parsed.suffix_number
        modify_number += parsed.modify_number if parsed.modify_number
        total += modify_number

        case dices.first
        when 10 # critical
          dices << @randomizer.roll_once(dice_face)
          total += dices.last
          result.critical = true
        when 1 # fumble
          dices << @randomizer.roll_once(dice_face)
          total -= dices.last
          result.fumble = true
        end

        if parsed.target_number
          if total >= parsed.target_number
            result.success = true
          else
            result.failure = true
          end
        end

        result.text = ''
        result.text += "(#{dice_cnt}D#{dice_face}"
        result.text += Format.modifier(modify_number) unless modify_number.zero?
        result.text += "#{parsed.cmp_op}#{parsed.target_number}" if parsed.target_number
        result.text += ') ＞ '
        result.text += "#{dices.first}[#{dices.first}]"
        result.text += "+#{modify_number}" unless modify_number.zero?
        result.text += ' ＞ '

        if result.critical?
          result.text += '決定的成功！ ＞ '
          result.text += "#{dices.last}[#{dices.last}] ＞ "
        end
        if result.fumble?
          result.text += '決定的失敗！ ＞ '
          result.text += "#{dices.last}[#{dices.last}] ＞ "
        end

        result.text += total.to_s

        if result.success?
          result.text += ' ＞ 成功！'
        end
        if result.failure?
          result.text += ' ＞ 失敗！'
        end

        return result
      end

      def ini_roll_result(command)
        result = "(#{command})"
        total = 0

        ini_match = INI_RE.match(command)
        ini = nil
        ini ||= ini_match[:initiative].to_i if ini_match

        dice = @randomizer.roll_once(10)
        total += dice

        result += " ＞ #{dice}[#{dice}]"
        if ini
          total += ini
          result += "+#{ini}"
        end

        result += " ＞ #{total}"

        return result
      end

      register_prefix('CP', 'INI', TABLES.keys)
    end
  end
end
