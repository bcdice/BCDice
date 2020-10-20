# frozen_string_literal: true

require "bcdice/game_system/KillDeathBusiness"

module BCDice
  module GameSystem
    class KillDeathBusiness_Korean < KillDeathBusiness
      # ゲームシステムの識別子
      ID = 'KillDeathBusiness:Korean'

      # ゲームシステム名
      NAME = 'Kill Death Business (한국어)'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:Kill Death Business'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정
        　JDx or JDx+y or JDx-y or JDx,z or JDx+y,z JDx-y,z
        　（x＝난이도、y＝보정、z＝펌블도(리스크)）
        ・이력표 (HST、HSTx) x에 숫자(1,2)로 표를 개별 롤
        ・소원표 (-WT)
        　죽음(DWT)、복수(RWT)、승리(VWT)、획득(PWT)、지배(CWT)、번영(FWT)
        　강화(IWT)、건강(HWT)、안전(SAWT)、장생(LWT)、삶(EWT)
        ・만능이름표 (NAME) x에 숫자(1,2,3)로 표를 개별 롤
        ・서브플롯표 (-SPT)
        　오컬트(OSPT)、가족(FSPT)、연애(LOSPT)、정의(JSPT)、수행(TSPT)
        　웃음(BSPT)、심술쟁이(MASPT)、원한(UMSPT)、인기(POSPT)、구분(PASPT)
        　돈벌이(MOSPT)、대(対)악마(ANSPT)
        ・씬 표 (ST)、서비스 씬 표 (EST)
        ・CM표 (CMT)
        ・소생 부작용 표 (ERT)
        ・일주일간 표（WKT)
        ・소울 방출표 (SOUL)
        ・범용연출표 (STGT)
        ・헬 스타일리스트 매도표 (HSAT、HSATx) x에 숫자(1,2)로 표를 개별 롤
        ・지정특기 랜덤 결정표 (SKLT)、지정특기 분야 랜덤 결정표 (SKLJ)
        ・엑스트라 표 (EXT、EXTx) x에 숫자(1,2,3,4)로 표를 개별 롤
        ・제작위원 결정표　PCDT/실제 어떠했는가 표　OHT
        ・태스크 표　헬 라이온　PCT1/헬 크로우　PCT2/헬 스네이크　PCT3/
        　헬 드래곤　PCT4/헬 플라이　PCT5/헬 갓　PCT6/헬 베어　PCT7
        ・D66 다이스 지원
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)
    end
  end
end
