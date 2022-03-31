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
        ・判定　CP+x+y+z>=t
        　(x＝能力値、y＝技能、z＝修正値、t＝難易度 or 受動側　x、z、y、tは省略可)
        　例）CP+7+6 CP+8+4>=12　CP+5+2-1　CP+8　CP+7>=12　CP　CP>=9
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
      CP_RE = /^CP(?<ability>\+\d+)?(?<skill>\+\d+)?(?<modifier>[+-]\d+)?(?<target>>=\d+)?/.freeze

      # 演算子
      OP_RE = /([+-])/.freeze

      # 能力値
      ABI_RE = /(\d+)/.freeze

      # 技能値
      SKILL_RE = /(\d+)/.freeze

      # 修正値
      MOD_RE = /(\d+)/.freeze

      # 難易度
      TARGET_RE = /(\d+)/.freeze

      # クリティカル値
      CRITICAL_SIDE = 10

      # ファンブル値
      FUMBLE_SIDE = 1

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

      private

      def cp_roll_result(command)
        result = "(#{command})"
        total = 0

        cp_match = CP_RE.match(command)
        ability = nil
        ability ||= ABI_RE.match(cp_match[:ability])[1].to_i if cp_match[:ability]
        skill = nil
        skill ||= SKILL_RE.match(cp_match[:skill])[1].to_i if cp_match[:skill]
        modifier = nil
        modifier ||= SKILL_RE.match(cp_match[:modifier])[1].to_i if cp_match[:modifier]
        op = nil
        op ||= OP_RE.match(cp_match[:modifier]).to_s if cp_match[:modifier]
        target = nil
        target ||= TARGET_RE.match(cp_match[:target])[1].to_i if cp_match[:target]

        dice = []
        dice << @randomizer.roll_once(10)
        total += dice.first

        result += " ＞ #{dice.first}[#{dice.first}]"

        if dice.first.eql? 10
          Result.critical('決定的成功！')
          dice << @randomizer.roll_once(10)
          result += "+#{dice.last}[#{dice.last}]"
          total += dice.last
        elsif dice.first.eql? 1
          Result.fumble('決定的失敗！')
          dice << @randomizer.roll_once(10)
          result += "-#{dice.last}[#{dice.last}]"
          total -= dice.last
        end

        if ability
          result += "+#{ability}"
          total += ability
        end
        if skill
          result += "+#{skill}"
          total += skill
        end
        if modifier && op == '+'
          result += "+#{modifier}"
          total += modifier
        elsif modifier && op == '-'
          result += "-#{modifier}"
          total -= modifier
        end

        result += " ＞ #{total}"

        if target && total > target
          Result.success('成功！')
          result += ' ＞ 成功！'
        elsif target && total <= target
          Result.failure('失敗！')
          result += ' ＞ 失敗！'
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
