# frozen_string_literal: true

require 'bcdice/game_system/HatsuneMiku'

module BCDice
  module GameSystem
    class HatsuneMiku_Korean < HatsuneMiku
      # ゲームシステムの識別子
      ID = 'HatsuneMiku:Korean'

      # ゲームシステム名
      NAME = '하츠네 미쿠TRPG 코코로 던전'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:하츠네 미쿠TRPG 코코로 던전'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정(Rx±y@z>=t)
        　능력치의 주사위마다 성공・실패 판정을 행합니다.
        　x:능력 랭크(S,A~D). 숫자 지정으로 직접 그 개수의 주사위를 굴릴 수 있습니다
        　y:수정값. A+2 또는 A++ 처럼 표기. 혼재 시 A++,+1 처럼 기술도 가능
        　z:스페셜 최저값(생략 시 6)　t:목표값(생략 시 4)
        　　예) RA　R2　RB+1　RC++　RD+,+2　RA>=5　RS-1@5>=6
        　결과는 음색을 취득한 나머지에서 최대값을 표시
        예) RB
        　HatsuneMiku : (RB>=4) ＞ [3,5] ＞
        　　음색에 3(파랑)을 취득한 경우 5:성공
        　　음색에 5(하양)을 취득한 경우 3:실패

        ・각종 표
        　펌블표 FT/치명상표 CWT/휴식표 BT/목표표 TT/관계표 RT
        　장애표 OT/리퀘스트표 RQT/크롤표 CLT/보상표 RWT/악몽표 NMT/정경표 ST

        ・키워드 표
        　다크 DKT/핫 HKT/러브 LKT/엑센트릭 EKT/멜랑콜리 MKT

        ・이름표 NT
        　코어별　다크 DNT/핫 HNT/러브 LNT/엑센트릭 ENT/멜랑콜리 MNT

        ・오토다마 각종 표
        　성격표A OPA/성격표B OPB/취미표 OHT/외견표 OLT/1인칭표 OIT/호칭표 OYT
        　리액션표 ORT/만남표 OMT
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze

      register_prefix_from_super_class()
    end
  end
end
