# frozen_string_literal: true

module BCDice
  module GameSystem
    class MeikyuKingdom < Base
      # ゲームシステムの識別子
      ID = 'MeikyuKingdom'

      # ゲームシステム名
      NAME = '迷宮キングダム'

      # ゲームシステム名の読みがな
      SORT_KEY = 'めいきゆうきんくたむ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定　(nMK+m)
        　n個のD6を振って大きい物二つだけみて達成値を算出します。修正mも可能です。
        　絶対成功と絶対失敗も自動判定します。
        ・各種表
        　・散策表(〜RT)：生活散策表 LRT／治安散策表 ORT／文化散策表 CRT／軍事散策表 ART／お祭り表 FRT
        　・休憩表(〜BT)：才覚休憩表 TBT／魅力休憩表 CBT／探索休憩表 SBT／武勇休憩表 VBT／お祭り休憩表 FBT／捜索後休憩表 ABT／全体休憩表 WBT／カップル休憩表 LBT
        　・ハプニング表(〜HT)：才覚ハプニング表 THT／魅力ハプニング表 CHT／探索ハプニング表 SHT
        　　／武勇ハプニング表 VHT
        　・王国災厄表 KDT／王国変動表 KCT／王国変動失敗表 KMT
        　・王国名決定表１／２／３／４／５ KNT1／KNT2／KNT3／KNT4
        　・痛打表 CAT／致命傷表 FWT／戦闘ファンブル表 CFT
        　・道中表 TT／交渉表 NT／感情表 ET／相場表 MPT
        　・お宝表１／２／３／４／５ T1T／T2T／T3T／T4T／T5T
        　・名前表 NAMEx (xは個数)
        　・名前表A NAMEA／名前表B NAMEB／エキゾチック名前表 NAMEEX／ファンタジック名前表 NAMEFA
        　・アイテム関連（猟奇戦役不使用の場合をカッコ書きで出力）
        　　・デバイスファクトリー　　DFT
        　　・アイテムカテゴリ決定表　IDT
        　　・アイテム表（〜IT)：武具 WIT／生活 LIT／回復 RIT／探索 SIT／レア武具 RWIT／レア一般 RUIT
        　　・アイテム特性決定表　　　IFT
        　・ランダムエンカウント表　nRET (nはレベル,1〜6)
        　・地名決定表　　　　PNTx (xは個数)
        　・迷宮風景表　　　　MLTx (xは個数)
        　・単語表１／２／３／４　WORD1／WORD2／WORD3／WORD4
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix(
        '\d+MK.*', '\d+R6.*',
        'LRT', 'ORT', 'CRT', 'ART', 'FRT',
        'TBT', 'CBT', 'SBT', 'VBT', 'FBT', 'ABT', 'WBT', 'LBT',
        'THT', 'CHT', 'SHT', 'VHT',
        'KDT', 'KCT', 'KMT',
        'CAT', 'FWT', 'CFT',
        'TT', 'NT', 'ET', 'MPT',
        'T1T', 'T2T', 'T3T', 'T4T', 'T5T',
        'NAME.*',
        'DFT', 'IDT\d*',
        'WIT', 'LIT', 'RIT', 'SIT', 'RWIT', 'RUIT',
        'IFT',
        '\d+RET',
        'PNT\d*', 'MLT\d*',
        'KNT\d+', 'WORD\d+'
      )

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      def replace_text(string)
        debug("change_text before string", string)

        string = string.gsub(/(\d+)MK6/i) { "#{Regexp.last_match(1)}R6" }
        string = string.gsub(/(\d+)MK/i) { "#{Regexp.last_match(1)}R6" }

        debug("change_text after string", string)

        return string
      end

      def check_nD6(total, dice_total, dice_list, cmp_op, target)
        return '' if target == '?'

        result = get2D6Result(total, dice_total, cmp_op, target)
        result += getKiryokuResult(total, dice_list, target)

        return result
      end

      alias check_2D6 check_nD6

      def get2D6Result(total_n, dice_n, signOfInequality, diff)
        return '' unless signOfInequality == :>=

        if dice_n <= 2
          " ＞ 絶対失敗"
        elsif dice_n >= 12
          " ＞ 絶対成功"
        else
          get2D6ResultOnlySuccess(total_n, diff)
        end
      end

      def get2D6ResultOnlySuccess(total_n, diff)
        if total_n >= diff
          " ＞ 成功"
        else
          " ＞ 失敗"
        end
      end

      def getKiryokuResult(total_n, dice_list, diff)
        num_6 = dice_list.count(6)

        if num_6 == 0
          return ""
        elsif num_6 >= 2
          return " ＆ 《気力》#{num_6}点獲得"
        end

        none6_list = dice_list.reject { |i| i == 6 }.sort

        maxDice1 = none6_list.pop.to_i
        maxDice2 = none6_list.pop.to_i
        debug("maxDice1", maxDice1)
        debug("maxDice2", maxDice2)

        debug("total_n", total_n)
        none6Total_n = total_n - 6 + maxDice2
        debug("none6Total_n", none6Total_n)

        none6Dice_n = maxDice1 + maxDice2
        debug("none6Dice_n", none6Dice_n)
        debug("diff", diff)
        none6DiceReuslt = get2D6ResultOnlySuccess(none6Total_n, diff)

        return " (もしくは) #{none6Total_n}#{none6DiceReuslt} ＆ 《気力》1点獲得"
      end

      def mayokin_check(string)
        debug("mayokin_check string", string)

        string = replace_text(string)

        m = /^S?((\d+)R6([\+\-\d]*)(([>=]+)(\d+))?)/i.match(string)
        unless m
          return nil
        end

        string = m[1]
        diceCount = m[2].to_i
        modifyText = m[3]
        signOfInequality = m[5] || ""
        diff = m[6].to_i

        bonus = modifyText ? ArithmeticEvaluator.eval(modifyText) : 0

        dice_list = @randomizer.roll_barabara(diceCount, 6).sort
        dice_str = dice_list.join(",")

        dice1 = diceCount >= 2 ? dice_list[diceCount - 2] : 0
        dice2 = diceCount >= 1 ? dice_list[diceCount - 1] : 0
        dice_now = dice1 + dice2
        debug("dice1, dice2, dice_now", dice1, dice2, dice_now)

        total_n = dice_now + bonus
        dice_str = "[#{dice_str}]"

        output = "#{dice_now}#{dice_str}"
        if bonus > 0
          output += "+#{bonus}"
        elsif bonus < 0
          output += bonus.to_s
        end

        if output =~ /[^\d\[\]]+/
          output = "(#{string}) ＞ #{output} ＞ #{total_n}"
        else
          output = "(#{string}) ＞ #{total_n}"
        end

        if signOfInequality != "" # 成功度判定処理
          cmp_op = Normalize.comparison_operator(signOfInequality)
          output += check_result(total_n, dice_now, dice_list, 6, cmp_op, diff)
        end

        return output
      end

      def eval_game_system_specific_command(command)
        output = ""
        type = ""
        total_n = ""

        if (result = mayokin_check(command))
          return result
        end

        case command

        when /^NAMEA/i
          debug("namea passed")
          type = '名前Ａ'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_name_a_table(total_n)
        when /^NAMEB/i
          type = '名前Ｂ'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_name_b_table(total_n)
        when /^NAMEEX/i
          type = 'エキゾチック名前'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_name_ex_table(total_n)
        when /^NAMEFA/i
          type = 'ファンタジック名前'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_name_fa_table(total_n)

        when /^NAME(\d*)/i
          type = '名前'
          count = getCount(Regexp.last_match(1))
          names = ""
          count.times do |_i|
            name, dice = mk_name_table
            names += "[#{dice}]#{name} "
          end
          output = names.strip
          total_n = count

        when /^PNT(\d*)/i
          type = '地名'
          count = getCount(Regexp.last_match(1))
          output = mk_pn_decide_table(count)
          total_n = count

        when /^MLT(\d*)/i
          type = '地名'
          count = getCount(Regexp.last_match(1))
          output = mk_ls_decide_table(count)
          total_n = count
        when /^DFT/i
          type = 'デバイスファクトリー'
          output = mk_device_factory_table()
          total_n = 1
        when /^LRT/i
          type = '生活散策'
          output, total_n = mk_life_research_table
        when /^ORT/i
          type = '治安散策'
          output, total_n = mk_order_research_table
        when /^CRT/i
          type = '文化散策'
          output, total_n = mk_calture_research_table
        when /^ART/i
          type = '軍事散策'
          output, total_n = mk_army_research_table
        when /^FRT/i
          type = 'お祭り'
          output, total_n = mk_festival_table

          # 休憩表(2D6)
        when /^TBT/i
          type = '才覚休憩'
          output, total_n = mk_talent_break_table
        when /^CBT/i
          type = '魅力休憩'
          output, total_n = mk_charm_break_table
        when /^SBT/i
          type = '探索休憩'
          output, total_n = mk_search_break_table
        when /^VBT/i
          type = '武勇休憩'
          output, total_n = mk_valor_break_table
        when /^FBT/i
          type = 'お祭り休憩'
          output, total_n = mk_festival_break_table
          # ハプニング表(2D6)
        when /^THT/i
          type = '才覚ハプニング'
          output, total_n = mk_talent_happening_table
        when /^CHT/i
          type = '魅力ハプニング'
          output, total_n = mk_charm_happening_table
        when /^SHT/i
          type = '探索ハプニング'
          output, total_n = mk_search_happening_table
        when /^VHT/i
          type = '武勇ハプニング'
          output, total_n = mk_valor_happening_table
          # お宝表
        when /^MPT/i
          type = '相場'
          output, total_n = mk_market_price_table
        when /^T1T/i
          type = 'お宝１'
          output, total_n = mk_treasure1_table
        when /^T2T/i
          type = 'お宝２'
          output, total_n = mk_treasure2_table
        when /^T3T/i
          type = 'お宝３'
          output, total_n = mk_treasure3_table
        when /^T4T/i
          type = 'お宝４'
          output, total_n = mk_treasure4_table
        when /^T5T/i
          type = 'お宝５'
          output, total_n = mk_treasure5_table

          # アイテム表
        when /^RWIT/i
          type = 'レア武具アイテム'
          total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
          output = mk_rare_weapon_item_table(total_n)
        when /^RUIT/i
          type = 'レア一般アイテム'
          total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
          output = mk_rare_item_table(total_n)
        when /^WIT/i
          type = '武具アイテム'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_weapon_item_table(total_n)
        when /^LIT/i
          type = '生活アイテム'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_life_item_table(total_n)
        when /^RIT/i
          type = '回復アイテム'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_rest_item_table(total_n)
        when /^SIT/i
          type = '探索アイテム'
          total_n = @randomizer.roll_d66(D66SortType::ASC)
          output = mk_search_item_table(total_n)
        when /^IFT/i
          type = 'アイテム特性'
          total_n = @randomizer.roll_sum(2, 6)
          output = mk_item_features_table(total_n)
        when /^IDT/i
          type = 'アイテムカテゴリ決定'
          total_n = @randomizer.roll_once(6)
          output = mk_item_decide_table(total_n)

          # ランダムエンカウント表
        when /^1RET/i
          type = '1Lvランダムエンカウント'
          total_n = @randomizer.roll_once(6)
          output = mk_random_encount1_table(total_n)
        when /^2RET/i
          type = '2Lvランダムエンカウント'
          total_n = @randomizer.roll_once(6)
          output = mk_random_encount2_table(total_n)
        when /^3RET/i
          type = '3Lvランダムエンカウント'
          total_n = @randomizer.roll_once(6)
          output = mk_random_encount3_table(total_n)
        when /^4RET/i
          type = '4Lvランダムエンカウント'
          total_n = @randomizer.roll_once(6)
          output = mk_random_encount4_table(total_n)
        when /^5RET/i
          type = '5Lvランダムエンカウント'
          total_n = @randomizer.roll_once(6)
          output = mk_random_encount5_table(total_n)
        when /^6RET/i
          type = '6Lvランダムエンカウント'
          total_n = @randomizer.roll_once(6)
          output = mk_random_encount6_table(total_n)

          # その他表
        when /^KDT/i
          type = '王国災厄'
          output, total_n = mk_kingdom_disaster_table
        when /^KCT/i
          type = '王国変動'
          output, total_n = mk_kingdom_change_table
        when /^KMT/i
          type = '王国変動失敗'
          output, total_n = mk_kingdom_mischange_table
        when /^CAT/i
          type = '痛打'
          output, total_n = mk_critical_attack_table
        when /^FWT/i
          type = '致命傷'
          output, total_n = mk_fatal_wounds_table
        when /^CFT/i
          type = '戦闘ファンブル'
          output, total_n = mk_combat_fumble_table
        when /^TT/i
          type = '道中'
          output, total_n = mk_travel_table
        when /^NT/i
          type = '交渉'
          output, total_n = mk_negotiation_table
        when /^ET/i
          type = '感情'
          output, total_n = mk_emotion_table

        when /^KNT(\d+)/i
          type = '王国名'
          count = getCount(Regexp.last_match(1))
          total_n = @randomizer.roll_d66(D66SortType::ASC)

          case count
          when 1
            output = mk_kingdom_name_1_table(total_n)
          when 2
            output = mk_kingdom_name_2_table(total_n)
          when 3
            output = mk_kingdom_name_3_table(total_n)
          end

        when /^WORD(\d+)/i
          type = '単語'
          count = getCount(Regexp.last_match(1))
          total_n = @randomizer.roll_d66(D66SortType::ASC)

          case count
          when 1
            output = mk_word_1_table(total_n)
          when 2
            output = mk_word_2_table(total_n)
          when 3
            output = mk_word_3_table(total_n)
          when 4
            output = mk_word_4_table(total_n)
          end

        when /^ABT/i
          type = '捜索後休憩'
          output, total_n = getAftersearchBreakTable()
        when /^WBT/i
          type = '全体休憩'
          output, total_n = getWholeBreakTable()
        when /^LBT/i
          type = 'カップル休憩'
          output, total_n = getLoversBreakTable()
        else
          return nil
        end

        if output != '1'
          return "#{type}表(#{total_n}) ＞ #{output}"
        else
          return nil
        end
      end

      def getCount(countText)
        if countText.empty?
          return 1
        end

        return countText.to_i
      end
    end
  end
end

require 'bcdice/game_system/meikyu_kingdom/item_table'
require 'bcdice/game_system/meikyu_kingdom/kingdom_name_table'
require 'bcdice/game_system/meikyu_kingdom/landscape_table'
require 'bcdice/game_system/meikyu_kingdom/name_tables'
require 'bcdice/game_system/meikyu_kingdom/placename_table'
require 'bcdice/game_system/meikyu_kingdom/word_table'
require 'bcdice/game_system/meikyu_kingdom/tables'
