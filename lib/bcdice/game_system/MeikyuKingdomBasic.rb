# frozen_string_literal: true

require "bcdice/game_system/MeikyuKingdom"
require "bcdice/dice_table/table"

module BCDice
  module GameSystem
    class MeikyuKingdomBasic < MeikyuKingdom
      # ゲームシステムの識別子
      ID = 'MeikyuKingdomBasic'

      # ゲームシステム名
      NAME = '迷宮キングダム 基本ルールブック'

      # ゲームシステム名の読みがな
      SORT_KEY = 'めいきゆうきんくたむきほんるうるふつく'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
          ・判定　(nMK+m)
          　n個のD6を振って大きい物二つだけみて達成値を算出します。修正mも可能です。
          　絶対成功と絶対失敗も自動判定します。
          ・各種表
          　・休憩表：才覚 TBT／魅力 CBT／探索 SBT／武勇 VBT
                     お祭り FBT／空振り EBT／全体 WBT／カップル LBT
                     お食事 FDBT
          　・ハプニング表：才覚 THT／魅力 CHT／探索 SHT／武勇 VHT
          　・視察表 RT／情報収集表 IG／ランダムマップ選択表 RMS
          　・痛打表 CAT／致命傷表 FWT／戦闘ファンブル表 CFT
          　・道中表 TT／交渉表 NT／相場表 MPT／王国災厄表 KDT／王国変動表 KCT
          　・感情表 ET／好意表 FET／敵意表 HET
          　・お宝表１／２／３／４／５ T1T／T2T／T3T／T4T／T5T
          　・特殊遭遇表 SE
          　　　上級：人工 ARN／水域 WEN／自然 NEN／洞窟 CEN／天空 SEN／異界 OEN
          ・潜在能力：スキル決定表 SDT
          　　基本：肉弾 BUS／射撃 SHS／星術 ASS／召喚 SUS／科学 SCS
          　　　　　迷宮 LAS／交渉 NES／便利 COS／芸能 ENS／道具 TOS
          　　上級：肉弾 ABUS／射撃 ASHS／星術 AASS／召喚 ASUS／科学 ASCS
          　　　　　迷宮 ALAS／交渉 ANES／便利 ACOS／芸能 AENS／道具 ATOS
          ・アイテム関連（上級不使用の場合、カッコ書きのものを使用して下さい）
          　・コモンアイテムランダム決定表　CIR
          　　　コモンアイテム表：武具 WIT／生活 LIT／回復 RIT／探索 SIT
          　・レア武具アイテムランダム決定表　RWIR／レア一般アイテムランダム決定表　RUIR（上級込）
          　　　レアアイテム表：基本武具 NRWT／基本一般 NRUT／上級武具 ARWT／上級一般 ARUT
          　・デヴァイスファクトリー DFTx (xは特性の個数)
          ・王国人物作成関連
          　・王国名決定表１／２／３ KNT1／KNT2／KNT3
          　・王国環境表 KET：技術 TET／国風 NST／資源 RET／人材 HRT／施設 FAT／血族 BLT
          　・名前表 NAMEx (xは個数)
          　　　名前A NAMEA／名前B NAMEB／エキゾチック NAMEEX／ファンタジック NAMEFA
          　・新名前表 NNAMEx (xは個数)
          　　　芸術 NMAR／食べ物 NMFO／日用品 NMDN／地名 NMPL／機械 NMMA／神様 NMGO
          　・単語表１／２／３／４　WORD1／WORD2／WORD3／WORD4
          　・生まれ決定表 BDT／生まれ表：才覚 TBO／魅力 CBO／探索 SBO／武勇 VBO
          　・初期装備表 IEQ
        　・地名決定表　PNTx (xは個数)／迷宮風景表 MLTx (xは個数)
          ・百万世界AtoZ関連
          　・ご祝儀表 GIFT
          　・ニュース表 NWST
          　・遠征王国変動表 EKCT
          　・王国ハプニング表 KDHT
          　・王国試練表 KDTT
          　・騎士道表 CHVT
          　・儀式表 RITT
          　・限定表 LIMT
          　・固有の文化表 UNCT
          　・後世の評価表 POET
          　・高レベル特殊遭遇表 HSET
          　・死霊の日々表 DODT
          　・事件名表1／2 INT1／INT2
          　・守護星座表 GUCT
          　・需要表 DEMTx (x:名物レベル)
          　・小鬼と一緒表 WLDT
          　・侵略ハプニング表 INHT
          　・新・情報収集表 NIGT
          　・人種特徴表／人種名文字表 RACT／RNCTx (x:文字数)
          　・迷宮化現象表／人体迷宮化表 HBLT／LAPT
          　・勢力表 POWT
          　・中立特殊遭遇表 NSET
          　・超協調行動表 ECBT
          　・通貨外見表／通貨材質表／通貨名称表 CUAT／CUMT／CUNT
          　・天候表 WEAT
          　・毒の追加効果表 PAET
          　・媒体表 MEDT
          　・反応表／民の反応表 REAT／PRET
          　・遍歴表 HIST
          　・由来表 ORIT
          　・誘致表 ATRT
          　・妖精の悪戯表 FAMT
         ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix(
        '\d+MK', '\d+R6',
        'IG', 'TT', 'NT', 'RMS',
        'CFT', 'FWT', 'CAT', 'KDT', 'KCT',
        'TBT', 'CBT', 'SBT', 'VBT', 'FBT', 'EBT', 'WBT', 'LBT',
        'THT', 'CHT', 'SHT', 'VHT',
        'BDT', 'TBO', 'CBO', 'SBO', 'VBO',
        'ET', 'FET', 'HET', 'SDT', 'IEQ', 'FRT',
        'T1T', 'T2T', 'T3T', 'T4T', 'T5T',
        'MPT', 'KNT', 'WORD', 'NAME', 'NNAME', 'NM',
        'RT', 'CIR', 'RUIR', 'RWIR',
        'WIT', 'LIT', 'RIT', 'SIT', 'NRWT', 'NRUT', 'ARWT', 'ARUT',
        'KET', 'TET', 'NST', 'RET', 'FAT', 'HRT', 'BLT',
        'BUS', 'SHS', 'ASS', 'SUS', 'SCS', 'LAS', 'NES', 'COS', 'ENS', 'TOS',
        'ABUS', 'ASHS', 'AASS', 'ASUS', 'ASCS', 'ALAS', 'ANES', 'ACOS', 'AENS', 'ATOS',
        'SE', 'ARN', 'WEN', 'NEN', 'CEN', 'SEN', 'OEN',
        'DFT',
        'PNT', 'MLT',
        'FDBT', 'GIFT', 'NWST', 'EKCT', 'KDHT', 'KDTT', 'CHVT', 'RITT', 'LIMT', 'UNCT', 'POET',
        'HSET', 'DODT', 'INT1', 'INT2', 'GUCT', 'DEMT', 'WLDT', 'INHT', 'NIGT', 'RACT', 'RNCT',
        'HBLT', 'POWT', 'NSET', 'ECBT', 'CUAT', 'CUMT', 'CUNT', 'WEAT', 'PAET', 'MEDT', 'REAT',
        'HIST', 'PRET', 'LAPT', 'ORIT', 'ATRT', 'FAMT'
      )

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def kiryoku_result(_total_n, dice_list, _diff)
        num_6 = dice_list.count(6)

        if num_6 == 0
          ""
        else
          " ＆ 《気力》#{num_6}点獲得"
        end
      end

      def eval_game_system_specific_command(command)
        output = ""
        type = ""
        total_n = ""

        if (output = roll_tables(command, TABLES))
          return output
        elsif (output = roll_tables(command, A2Z_TABLES))
          return output
        else

          case command
          when /^DFT(\d*)$/i
            feature_count = Regexp.last_match(1).to_i
            return roll_device_factory_table(feature_count)

          when /^NRWT/i
            type = '基本レア武具アイテム'
            total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
            output = mk_normal_rare_weapon_item_table(total_n)
          when /^NRUT/i
            type = '基本レア一般アイテム'
            total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
            output = mk_normal_rare_item_table(total_n)
          when /^ARWT/i
            type = '上級レア武具アイテム'
            total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
            output = mk_advanced_rare_weapon_item_table(total_n)
          when /^ARUT/i
            type = '上級レア一般アイテム'
            total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
            output = mk_advanced_rare_item_table(total_n)
          when /^CIR/i
            type = 'コモンアイテムランダム決定'
            total_n = @randomizer.roll_once(4)
            output = mk_common_item_random_table(total_n)
          when /^RWIR/i
            type = 'レア武具アイテムランダム決定'
            total_n = @randomizer.roll_once(6)
            output = mk_rare_weapon_item_random_table(total_n)
          when /^RUIR/i
            type = 'レア一般アイテムランダム決定'
            total_n = @randomizer.roll_once(6)
            output = mk_rare_usual_item_random_table(total_n)
          when /^NMAR/i
            debug("namea passed")
            type = '芸術系名前'
            total_n = @randomizer.roll_d66(D66SortType::ASC)
            output = mk_name_ar_table(total_n)
          when /^NMFO/i
            type = '食べ物系名前'
            total_n = @randomizer.roll_d66(D66SortType::ASC)
            output = mk_name_fo_table(total_n)
          when /^NMDN/i
            type = '日用品系名前'
            total_n = @randomizer.roll_d66(D66SortType::ASC)
            output = mk_name_dn_table(total_n)
          when /^NMPL/i
            type = '地名系名前'
            total_n = @randomizer.roll_d66(D66SortType::ASC)
            output = mk_name_pl_table(total_n)
          when /^NMMA/i
            type = '機械系名前'
            total_n = @randomizer.roll_d66(D66SortType::ASC)
            output = mk_name_ma_table(total_n)
          when /^NMGO/i
            type = '神様系名前'
            total_n = @randomizer.roll_d66(D66SortType::ASC)
            output = mk_name_go_table(total_n)
          when /^NNAME(\d*)/i
            type = '新名前'
            count = getCount(Regexp.last_match(1))
            names = ""
            count.times do |_i|
              name, dice = mk_new_name_table
              names += "[#{dice}]#{name} "
              output = names
              total_n = count
            end
            output = output.strip
          when /^RMS/i
            type = 'ランダムマップ選択'
            total_n = @randomizer.roll_d66(D66SortType::NO_SORT)
            output = mk_random_map_select_table(total_n)

          when /^KNT(\d+)/i
            type = '王国名決定'
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

          when /^KET/i
            type = '王国環境'
            total_n = @randomizer.roll_once(6)
            output = mk_kingdom_environment_table(total_n)
          when /^TET/i
            type = '技術決定'
            total_n = @randomizer.roll_once(6)
            output = mk_technic_decide_table(total_n)
          when /^NST/i
            type = '国風決定'
            total_n = @randomizer.roll_once(6)
            output = mk_national_style_decide_table(total_n)
          when /^RET/i
            type = '資源決定'
            total_n = @randomizer.roll_once(6)
            output = mk_resource_decide_table(total_n)
          when /^FAT/i
            type = '施設決定'
            total_n = @randomizer.roll_once(6)
            output = mk_facility_decide_table(total_n)
          when /^HRT/i
            type = '人材決定'
            total_n = @randomizer.roll_once(6)
            output = mk_human_resources_decide_table(total_n)
          when /^BLT/i
            type = '血族決定'
            total_n = @randomizer.roll_once(6)
            output = mk_blood_decide_table(total_n)
          when /^ABUS/i
            type = '上級肉弾スキル'
            output, total_n = mk_advanced_bullet_skill_table
          when /^ASHS/i
            type = '上級射撃スキル'
            output, total_n = mk_advanced_shooting_skill_table
          when /^AASS/i
            type = '上級星術スキル'
            output, total_n = mk_advanced_astrology_skill_table
          when /^ASUS/i
            type = '上級召喚スキル'
            output, total_n = mk_advanced_summon_skill_table
          when /^ASCS/i
            type = '上級科学スキル'
            output, total_n = mk_advanced_science_skill_table
          when /^ALAS/i
            type = '上級迷宮スキル'
            output, total_n = mk_advanced_labyrinth_skill_table
          when /^ANES/i
            type = '上級交渉スキル'
            output, total_n = mk_advanced_negotiation_skill_table
          when /^ACOS/i
            type = '上級便利スキル'
            output, total_n = mk_advanced_convenient_skill_table
          when /^AENS/i
            type = '上級芸能スキル'
            output, total_n = mk_advanced_entertainment_skill_table
          when /^ATOS/i
            type = '上級道具スキル'
            output, total_n = mk_advanced_tool_skill_table
          when /^GUCT/i
            type = '守護星座'
            total_n = @randomizer.roll_once(6) * 100 + @randomizer.roll_once(6) * 10 + @randomizer.roll_once(6)
            output = mk_guardian_constellation_table(total_n)
          when /^DEMT(\d+)/i
            type = '需要'
            count = getCount(Regexp.last_match(1))
            output, total_n = get_demand_table(count)
          when /^RNCT(\d*)/i
            type = '人種名文字'
            count = getCount(Regexp.last_match(1))
            output, total_n = get_race_name_character_table(count)
          when /^CUMT/i
            type = '通貨材質'
            @total = [@randomizer.roll_barabara(2, 6).sum(), @randomizer.roll_once(6)]
            total_n = @total.join(',')
            output = get_currency_material_table(*@total)
          end

          if !output.nil?
            debug("output", output)
            output = "#{type}表(#{total_n}) ＞ #{output}"
          else
            super(command)
          end
        end
      end
    end
  end
end
require "bcdice/game_system/meikyu_kingdom_basic/item_table"
require "bcdice/game_system/meikyu_kingdom_basic/kingdom_table"
require "bcdice/game_system/meikyu_kingdom_basic/name_table"
require "bcdice/game_system/meikyu_kingdom_basic/word_table"
require "bcdice/game_system/meikyu_kingdom_basic/table"
require "bcdice/game_system/meikyu_kingdom_basic/atoz_table"
