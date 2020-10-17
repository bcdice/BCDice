# frozen_string_literal: true

require "bcdice/game_system/Dracurouge"

module BCDice
  module GameSystem
    class Dracurouge_Korean < Dracurouge
      # ゲームシステムの識別子
      ID = 'Dracurouge:Korean'

      # ゲームシステム名
      NAME = '드라크루주'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:드라크루주'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・행동판정（DRx+y）
        　x：굴리는 주사위의 수（생략시４）, y：갈증수정（생략시０）
        　예） DR　DR6　DR+1　DR5+2
        ・저항판정（DRRx）
        　x：굴리는 주사위의
        　예） DRR3
        ・原風景表（ST）, 叙勲表（CO）, 叙勲後表（CA）, 遥か過去表（EP）
        　原罪表（OS）, 受難表（PN）, 近況表（RS）, 平和な過去表（PP）
        ・타락표（CTx） x：갈증（예） CT3
        ・타락의 전조표（CS）, 拡張・堕落の兆し表（ECS）
        ・인연 내용 결정표（BT）
        ・반응표（RTxy）x：혈통, y：길　xy생략으로 일괄표시
        　　혈통　D：드라크, R：로젠부르크, H：헬스가르드, M：더스트하임,
        　　　　　A：아발롬　N：노스페라스
        　　길　　F：영주, G：근위, R：방랑, W：현자, J：사냥꾼, N：야수
        　예）RT（일괄표시）, RTDF（드라크 영주）, RTAN（아발롬 야수）
        ・異端の反応表（HRTxy）x：血統, y：道　xy省略で一括表示
        　血統　L：異端卿, V：ヴルコラク, N：ナハツェーラ, K：カルンシュタイン
        　　　　G：グリマルキン, S：ストリガ, M：メリュジーヌ, F：フォーン
        　　　　H：ホムンクルス, E：エナメルム, S2：サングィナリエ, A：アールヴ
        　　　　V2：ヴィーヴル, L2：ルーガルー, A2：アルラウネ, F2：フリッガ
        　道　W：野伏, N：流浪, S：密使, H：魔女, F：剣士, X：検体
        ・D66 다이스 있음
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)
    end
  end
end
