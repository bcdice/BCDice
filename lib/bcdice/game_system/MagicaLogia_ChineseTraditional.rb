# frozen_string_literal: true

require "bcdice/game_system/MagicaLogia"

module BCDice
  module GameSystem
    class MagicaLogia_ChineseTraditional < MagicaLogia
      # ゲームシステムの識別子
      ID = "MagicaLogia:ChineseTraditional"

      # ゲームシステム名
      NAME = "魔導書大戰"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Chinese Traditional:魔導書大戰"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        可以判定大成功／大失敗／成功／失敗
        ・各種表
        經歷表　BGT/初期錨點表　DAT/命運屬性表　FAT
        願望表　WIT/戰利品表　PT
        時間流逝表　TPT/大判時間流逝表　TPTB
        事件表　AT
        大失敗表　FT／變調表　WT
        命運轉變表表　FCT
        　典型性災厄 TCT／物理性災厄 PCT／精神性災厄 MCT／狂氣性災厄 ICT
        　社會性災厄 SCT／超自然災厄 XCT／不可思議的災厄 WCT／喜劇性災厄 CCT
        　魔法使的災厄 MGCT
        場景表　ST／大判場景表　STB
        　極限環境 XEST／內心世界 IWST／魔法都市 MCST
        　死後世界 WDST／迷宮世界 LWST
        　魔法書架 MBST／魔法學院 MAST／克雷德塔 TCST
        　平行世界 PWST／終末世界 PAST／異世界酒吧 GBST
        　星影 SLST／舊圖書館 OLST
        世界法則追加表 WLAT/徘徊怪物表 WMT
        隨機領域表　RCT
        隨機特技表　RTT
        　星領域隨機特技表 RTS, RTT1
        　獸領域隨機特技表 RTB, RTT2
        　力領域隨機特技表 RTF, RTT3
        　歌領域隨機特技表 RTP, RTT4
        　夢領域隨機特技表 RTD, RTT5
        　暗領域隨機特技表 RTN, RTT6
        空白秘密表　BST
        　宿敵表　MIT/謀略表　MOT/因緣表　MAT
        　奇人表　MUT/力場表　MFT/同盟表　MLT
        落花表　FFT
        那之後表 FLT
        ・可以使用D66
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :zh_hant
      end

      SKILL_TABLE = translate_skill_table(:zh_hant)
      TABLES = translate_tables(:zh_hant, SKILL_TABLE)
    end
  end
end
