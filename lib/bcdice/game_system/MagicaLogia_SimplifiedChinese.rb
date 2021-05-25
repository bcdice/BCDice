# frozen_string_literal: true

require "bcdice/game_system/MagicaLogia"

module BCDice
  module GameSystem
    class MagicaLogia_SimplifiedChinese < MagicaLogia
      # ゲームシステムの識別子
      ID = "MagicaLogia:SimplifiedChinese"

      # ゲームシステム名
      NAME = "魔导书大战"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Simplified Chinese:魔导书大战"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        可以判定大成功／大失败／成功／失败
        ・各种表
        经历表　BGT/初期锚点表　DAT/命运属性表　FAT
        愿望表　WIT/战利品表　PT
        时间流逝表　TPT/大判时间流逝表　TPTB
        事件表　AT
        大失败表　FT／变调表　WT
        命运转变表表　FCT
        　典型性灾厄 TCT／物理性灾厄 PCT／精神性灾厄 MCT／狂气性灾厄 ICT
        　社会性灾厄 SCT／超自然灾厄 XCT／不可思议的灾厄 WCT／喜剧性灾厄 CCT
        　魔法使的灾厄 MGCT
        场景表　ST／大判场景表　STB
        　极限环境 XEST／内心世界 IWST／魔法都市 MCST
        　死后世界 WDST／迷宫世界 LWST
        　魔法书架 MBST／魔法学院 MAST／克雷德塔 TCST
        　平行世界 PWST／终末世界 PAST／异世界酒吧 GBST
        　星影 SLST／旧图书馆 OLST
        世界法则追加表 WLAT/徘徊怪物表 WMT
        随机领域表　RCT
        随机特技表　RTT
        　星领域随机特技表  RTS, RTT1
        　兽领域随机特技表  RTB, RTT2
        　力领域随机特技表  RTF, RTT3
        　歌领域随机特技表  RTP, RTT4
        　梦领域随机特技表  RTD, RTT5
        　暗领域随机特技表  RTN, RTT6
        空白秘密表　BST
        　宿敌表　MIT/谋略表　MOT/因缘表　MAT
        　奇人表　MUT/力场表　MFT/同盟表　MLT
        落花表　FFT
        那之后表 FLT
        ・可以使用D66
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :zh_hans
      end

      SKILL_TABLE = translate_skill_table(:zh_hans)
      TABLES = translate_tables(:zh_hans, SKILL_TABLE)
    end
  end
end
