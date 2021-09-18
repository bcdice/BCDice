# frozen_string_literal: true

require 'bcdice/game_system/beginning_idol/chain_table'
require 'bcdice/game_system/beginning_idol/chain_d66_table'
require 'bcdice/game_system/beginning_idol/bad_status_table'
require 'bcdice/game_system/beginning_idol/random_event_table'
require 'bcdice/game_system/beginning_idol/my_skill_name_table'
require 'bcdice/game_system/beginning_idol/table'
require 'bcdice/game_system/beginning_idol/item_table'
require 'bcdice/game_system/beginning_idol/d6_twice_table'
require 'bcdice/game_system/beginning_idol/costume'
require 'bcdice/game_system/beginning_idol/accessories_table'
require 'bcdice/game_system/beginning_idol/heart_step_table'
require 'bcdice/game_system/beginning_idol/work_table'
require 'bcdice/game_system/beginning_idol/world_setting_table'

module BCDice
  module GameSystem
    class BeginningIdol < Base
      # ゲームシステムの識別子
      ID = 'BeginningIdol'

      # ゲームシステム名
      NAME = 'ビギニングアイドル'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひきにんくあいとる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・パフォーマンス　[r]PDn[+m/-m](r：場に残った出目　n：振る数　m：修正値)
        ・ワールドセッティング仕事表　BWT：大手芸能プロ　LWT：弱小芸能プロ
        　TWT：ライブシアター　CWT：アイドル部　LO[n]：地方アイドル(n：チャンス)
        　SU：情熱の夏　WI：ぬくもりの冬　NA：大自然　GA：女学園　BA：アカデミー
        ・仕事表　WT　VA：バラエティ　MU：音楽関係　DR：ドラマ関係
        　VI：ビジュアル関係　SP：スポーツ　CHR：クリスマス　PAR：パートナー関係
        　SW：お菓子　AN：動物　MOV：映画　FA：ファンタジー
        ・ランダムイベント　RE
        ・ハプニング表　HA
        ・特技リスト　AT[n](n：分野No.)
        ・アイドルスキル修得表　SGT：チャレンジガールズ　RS：ロードトゥプリンス
        ・変調　BT[n](n：発生数)
        ・アイテム　IT[n](n：獲得数)
        ・アクセサリー　ACT：種別決定　ACB：ブランド決定　ACE：効果表
        ・衣装　DT：チャレンジガールズ　RC：ロードトゥプリンス　FC:フォーチュンスターズ
        ・無茶ぶり表　LUR：地方アイドル　SUR：情熱の夏　WUR：ぬくもりの冬
        　NUR：大自然　GUR：女学園　BUR：アカデミー
        ・センタールール　HW：向かい風シーン表　FL：駆け出しシーン表　LN：孤独表
        　マイスキル【MS：名前決定　MSE：効果表】　演出表【ST　FST：ファンタジー】
        ・合宿ルール　散策表【SH：ショッピングモール　MO：山　SEA：海　SPA：温泉街】
        　TN：夜語りシチュエーション表　成長表【CG：コモン　GG：ゴールド】
        ・サビ表　CHO　SCH：情熱の夏　WCH：ぬくもりの冬　NCH：大自然
        　GCH：女性向け　PCH：力強い
        ・キャラ空白表　CBT：チャレンジガールズ　RCB：ロードトゥプリンス
        ・趣味空白表　HBT：チャレンジガールズ　RHB：ロードトゥプリンス
        ・マスコット暴走表　RU
        ・アイドル熱湯風呂　nC：バーストタイム(n：温度)　BU：バースト表
        ・攻撃　n[S]A[r][+m/-m](n：振る数　S：失敗しない　r：取り除く出目　m：修正値)
        ・かんたんパーソン表　SIP
        ・会場表
        　BVT：大手芸能プロ　LVT：弱小芸能プロ　TVT：ライブシアター　CVT：アイドル部
        ・場所表
        　BST：大手芸能プロ　LST：弱小芸能プロ　TST：ライブシアター　CST：アイドル部
        ・プレッシャー種別決定表
        　BPT：大手芸能プロ　LPT：弱小芸能プロ　TPT：ライブシアター　CPT：アイドル部
        ・道具表
        　BIT：大手芸能プロ　LIT：弱小芸能プロ　TIT：ライブシアター　CIT：アイドル部
        []内は省略可　D66入れ替えあり
      INFO_MESSAGE_TEXT

      register_prefix(
        '[1-7]*PD',
        'HW',
        'BWT',
        'LWT',
        'TWT',
        'CWT',
        'LO',
        'SU',
        'WI',
        'NA',
        'GA',
        'BA',
        'WT',
        'VA',
        'MU',
        'DR',
        'VI',
        'SP',
        'CHR',
        'PAR',
        'SW',
        'AN',
        'MOV',
        'FA',
        'RE',
        'HA',
        'AT[1-6]?',
        'LUR',
        'SUR',
        'WUR',
        'NUR',
        'GUR',
        'BUR',
        'BT',
        'SGT',
        'RS',
        'SH',
        'MO',
        'SEA',
        'SPA',
        'TN',
        'CG',
        'GG',
        'FL',
        'LN',
        'MS',
        'MSE',
        'ST',
        'FST',
        'CHO',
        'SCH',
        'WCH',
        'NCH',
        'GCH',
        'PCH',
        'IT',
        'ACT',
        'ACB',
        'ACE',
        'DT',
        'RC',
        'FC',
        'CBT',
        'RCB',
        'HBT',
        'RHB',
        'RU',
        '\d{2}C',
        'BU',
        '\d+S?A',
        'SIP',
        'BVT',
        'LVT',
        'TVT',
        'CVT',
        'BST',
        'LST',
        'TST',
        'CST',
        'BPT',
        'LPT',
        'TPT',
        'CPT',
        'BIT',
        'LIT',
        'TIT',
        'CIT'
      )

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def check_nD6(total, dice_total, _dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        if dice_total <= 2
          " ＞ ファンブル(変調がランダムに1つ発生し、PCは【思い出】を1つ獲得する)"
        elsif dice_total >= 12
          " ＞ スペシャル！(PCは【思い出】を1つ獲得する)"
        elsif total >= target
          " ＞ 成功"
        else
          " ＞ 失敗"
        end
      end

      alias check_2D6 check_nD6

      def eval_game_system_specific_command(command)
        roll_work_table(command) ||
        roll_heart_step_table(command) ||
        roll_accessories_table(command) ||
        roll_world_setting_table(command) ||
        roll_other_table(command) ||
        roll_attack(command) ||
        roll_burst(command) ||
        roll_performance(command) ||
        roll_tables(command, COSTUME_TABLES) ||
        SKILL_TABLE.roll_command(@randomizer, command) ||
        ItemTable.roll_command(@randomizer, command) ||
        BadStatusTable.roll_command(@randomizer, command)
      end

      private

      def roll_burst(command)
        m = /^(\d{2})C$/.match(command)
        unless m
          return nil
        end

        title = 'バーストタイム'
        degrees = Regexp.last_match(1).to_i
        counts = 6
        if (degrees < 45) || (degrees > 55)
          return nil
        elsif degrees <= 49
          counts = 3
        elsif degrees <= 52
          counts = 4
        elsif degrees <= 54
          counts = 5
        end

        dice_list = @randomizer.roll_barabara(counts, 6).sort
        total = dice_list.sum()
        dice = dice_list.join(",")
        total += degrees

        text = "#{title} ＞ #{degrees}+[#{dice}] ＞ #{total} ＞ "
        if total >= 80
          text += "Burst!\n「バースト表」を使用する。"
        elsif total >= 65
          string = "成功\n【獲得ファン人数】が2D6点上昇する。"
          if total >= 75
            string = "大#{string}\nPC全員が挑戦者ではない場合、自分以外のPCを一人指名する。指名されたPCは、新たな挑戦者として、【メンタル】を減少させずに「バーストタイム」を行う。"
          end
          text += string
        else
          text += '失敗'
        end
        return text
      end

      def roll_attack(command)
        m = /^(\d+)(S?)A([1-6]*)([+\-]\d+)?$/.match(command)
        unless m
          return nil
        end

        title = '攻撃'
        counts = Regexp.last_match(1).to_i
        return nil if counts <= 0

        sure = !Regexp.last_match(2).empty?
        remove = Regexp.last_match(3).each_char.map(&:to_i)
        adjust = Regexp.last_match(4)&.to_i
        adjust_str = Format.modifier(adjust)

        dice = @randomizer.roll_barabara(counts, 6).sort
        dice_str = dice.join(",")

        dice -= remove

        text = "#{title} ＞ [#{dice_str}]#{adjust_str} ＞ "

        unless (dice.count == counts) || dice.empty?
          text += "[#{dice.join(',')}]#{adjust_str} ＞ "
        end

        if sure || (dice.count == dice.uniq.count)
          total = adjust.to_i
          total += dice.sum()
          total = 0 if total < 0
          text += "#{total}ダメージ"
        else
          text += '失敗'
        end
        return text
      end

      def roll_performance(command)
        m = /^([1-7]*)PD(\d+)([+\-]\d+)?$/.match(command)
        unless m
          return nil
        end

        counts = m[2].to_i
        return nil if counts <= 0

        residual = m[1]
        adjust = m[3].to_i

        title = 'パフォーマンス'

        string = ''
        string += '+' if adjust > 0
        string += adjust.to_s unless adjust == 0

        dice_list = @randomizer.roll_barabara(counts, 6).sort
        dice_str = dice_list.join(",")
        diceAll = dice_list.join("") + residual

        total = 0
        diceUse = []
        (1..7).each do |i|
          if diceAll.count(i.to_s) == 1
            total += i
            diceUse.push(i)
          end
        end

        text = " ＞ [#{dice_str}]"

        if residual.empty?
          text = "#{title}#{text}"
        else
          text = "シンフォニー#{text}"
        end

        unless residual.empty?
          text += ',[' + residual.split("").sort.join(",") + ']'
        end

        text += "#{string} ＞ "

        if total == 0
          if residual.empty?
            total = 10 + adjust
            text += "【ミラクル】#{total}"
          else
            total = 15 + adjust
            text += "【ミラクルシンクロ】#{total}＋シンフォニーを行った人数"
          end
        elsif (total == 21) && !diceUse.include?(7)
          unless residual.empty?
            text += '[' + diceUse.join(',') + "]#{string} ＞ "
          end
          total = 30 + adjust
          text += "【パーフェクトミラクル】#{total}"
        else
          unless residual.empty? && (diceUse.count == diceAll.length)
            text += '[' + diceUse.join(',') + "]#{string} ＞ "
          end
          total += adjust
          text += total.to_s
        end

        return text
      end
    end
  end
end
