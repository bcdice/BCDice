# frozen_string_literal: true

module BCDice
  module GameSystem
    class WoW < Base
      # ゲームシステムの識別子
      ID = 'WoW'

      # ゲームシステム名
      NAME = 'ワンダーオブワンダラー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わんたあおふわんたらあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        行為判定 nWW12@s#f<=x
        n: ダイス数
        @s = 大成功値（省略可：デフォルトは1）
        #f = 大失敗値（省略可：デフォルトは12）
        x = 目標値（省略可：デフォルトは6）
        例）1WW12 5WW12<=6 6WW12@5#3<=7+1

        ランダムギフトガチャ表 GG
        ランダムギフトガチャ表（アルファベット指定） GGx 例）GGA GGB

        ファンブル表 FT
      INFO_MESSAGE_TEXT

      register_prefix('\d*WW12', 'GG', 'GGA', 'GGB', 'GGC', 'GGD', 'GGE', 'GGF', 'GGG', 'GGH', 'FT')

      TABLES = {
        'A' => [
          '演者の声', '言いくるめ', '誤魔化し', '代弁者', '腕利き弁護人', '魔性', '魔術', '魔法的物理', '誤り指摘', '専門知識', '理力増幅', '協力的な有識者'
        ],
        'B' => [
          '百科全書', '地道な下調べ', '思い…出した！', '目星', 'ハッキング', '再考察', '迷探偵', '逆転の発想', '炯眼', '安楽椅子探偵', '密室トリック解明', '丁寧な処置'
        ],
        'C' => [
          '慈愛', 'クイックヒール', 'エリアヒール', 'クリアランス', '俯瞰視点', 'パターン化', '瞬時看破', '警鐘', '賢者の瞳', '千里眼', '危険感知', 'リバーサル'
        ],
        'D' => [
          '転禍為福', '受け身', '九死に一生', '軽業', 'バックドア', '着服', '闇に隠れる', '変装', '証拠隠滅', 'サポート', '技師の指', '妨害'
        ],
        'E' => [
          'ゴッドハンド', '生存者の切り札', '狙撃', 'プラチナ免許', 'ドライバーズ・ハイ', '相乗り', '愛車／愛馬', 'ビーストフレンズ', 'ドゥ・ライブ', 'カツアゲ', 'マッドドッグ', '目の上の瘤'
        ],
        'F' => [
          '叱咤激励', 'ふいに見せた優しさ', 'スゴ味', '達人', '必殺技', '二刀流', '急所狙い', 'ジャンプショット', 'パルクール', '疾風怒濤', 'スパート', '走為上'
        ],
        'G' => [
          'ヒット＆アウェイ', 'ウーバー', '割れもの注意', 'もしもの備え', 'アブダクション', '追加機材', '自在配送', '不屈の精神', '防壁', '心頭滅却', '三時間しか寝てない', 'βエンドルフィン'
        ],
        'H' => [
          '怒髪天', '頭の体操', '精神統一', 'リトルラック', 'いいね！', '幻視', '慎重性', 'バレットストッパー', '褪せぬ想い', 'アピール上手', '土俵際の魔術師', '真実の愛'
        ],
        'FT' => [
          '何も起きなかった！　ラッキー（？）',
          'ランダムに武器または防具が外れる。該当箇所に何も装備していなければ1点のダメージ（軽減無効）を受ける。',
          'GMの指定したLOVEの【深度】が1増加する。誰かに対するLOVEを新規取得させても良い。',
          'GMの指定したハンドアウト1つの強度が［自身のソウルLV／2］増加する。',
          '1点のダメージ（軽減無効）を受ける。',
          'プレイス内のPCが所持している消耗品からGMが1つ指定し、破壊する。破壊したくない場合、かわりに自身のHPを最大値の1／3（切り捨て）減らす。',
          '不調強度［自身のソウルLV／2］のランダムな不調を受ける。',
          'ファンブル表を2回振る。この効果は判定につき1度までで、以降は1点のダメージ（軽減無効）を受ける。',
          'ランダムなLOVEの【深度】が1減少する。',
          'ランダムなLOVEの【エモ】が2増加する。',
          'トラブルが発生する。ランダムトラブル表を使用し、場にトラブルのハンドアウトを追加する。',
          'ランダムなギフト1つのMPが0になる。'
        ]
      }.freeze

      def eval_game_system_specific_command(command)
        case command
        when 'GG'
          return roll_gg
        when /^GG([A-H])$/
          return roll_table(::Regexp.last_match(1))
        when 'FT'
          return roll_fumble_table
        else
          return roll_wow(command)
        end
      end

      private

      def roll_gg
        dice_results = @randomizer.roll_barabara(2, 12)
        first_roll = dice_results[0]
        second_roll = dice_results[1]

        if first_roll >= 9
          return "GG ＞ 自由（アルファベットを決めてGGXを振る）"
        end

        alphabet = (64 + first_roll).chr
        table = TABLES[alphabet]
        return "ランダムギフトガチャ #{alphabet}-#{second_roll} ＞ #{table[second_roll - 1]}"
      end

      def roll_table(alphabet)
        table = TABLES[alphabet]
        dice_result = @randomizer.roll_once(12)
        return "ランダムギフトガチャ #{alphabet}-#{dice_result} ＞ #{table[dice_result - 1]}"
      end

      def roll_fumble_table
        dice_result = @randomizer.roll_once(12)
        table = TABLES['FT']
        return "FT(#{dice_result}) ＞ #{table[dice_result - 1]}"
      end

      def roll_wow(command)
        # コマンドの解析
        m = /^(\d+)WW12(?:@(\d+))?(?:#(\d+))?(?:<=(\d+))?$/.match(command)
        return nil unless m

        num_dice = m[1].to_i # 振るダイスの数
        critical_success_value = m[2] ? m[2].to_i : 1 # 大成功の値（デフォルトは1）
        critical_fail_value = m[3] ? m[3].to_i : 12 # 大失敗の値（デフォルトは12）
        success_threshold = m[4] ? m[4].to_i : 6 # 成功の閾値（デフォルトは6）

        if m[4].nil?
          command_with_defaults = "#{m[1]}WW12<=#{success_threshold}"
        else
          command_with_defaults = command
        end

        # ダイスを振る
        dice_results = @randomizer.roll_barabara(num_dice, 12)

        # 出目を分類
        critical_success = dice_results.count { |r| r <= critical_success_value } # 大成功の数
        critical_fail = dice_results.count { |r| r >= critical_fail_value } # 大失敗の数
        normal_success = dice_results.count { |r| (r > critical_success_value) && (r <= success_threshold) && r < critical_fail_value }

        critical_success_first = critical_success
        critical_fail_first = critical_fail

        # 大成功と大失敗の相殺
        offset = [critical_success, critical_fail].min
        critical_success -= offset
        critical_fail -= offset

        # 成功数とファンブルの判定
        successes = normal_success + (critical_success * 2)
        is_fumble = critical_fail > 0

        # 結果をBCDICE::Resultで構造化
        BCDice::Result.new.tap do |r|
          r.text = "(#{command_with_defaults}) ＞ [#{dice_results.join(',')}] ＞ 成功数#{successes}（大成功#{critical_success_first}個、大失敗#{critical_fail_first}個）#{is_fumble ? ' ＞ ファンブル！' : ''}"
          r.critical = critical_success > 0
          r.fumble = is_fumble
          r.success = successes > 0 && !is_fumble  # 成功数が0より大きく、ファンブルがない場合に成功
          r.failure = successes == 0 || is_fumble  # 成功数が0、またはファンブルがある場合に失敗
        end
      end
    end
  end
end
