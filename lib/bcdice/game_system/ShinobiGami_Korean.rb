# frozen_string_literal: true

require "bcdice/dice_table/chain_table"
require "bcdice/dice_table/sai_fic_skill_table"
require "bcdice/dice_table/table"
require "bcdice/format"
require "bcdice/game_system/ShinobiGami"

module BCDice
  module GameSystem
    class ShinobiGami_Korean < ShinobiGami
      # ゲームシステムの識別子
      ID = 'ShinobiGami:Korean'

      # ゲームシステム名
      NAME = '시노비가미'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:시노비가미'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・행동 판정 nSG@s#f>=x
          2D6을 굴려 행동 판정을 합니다. 주사위 수가 지정된 경우, 그 중 큰 눈 2개를 채택합니다.
          n: 주사위 수 (표기 생략 시 기본 2)
          s: 스페셜치 (표기 생략 시 기본 12)
          f: 펌블치 (표기 생략 시 기본 2)
          x: 목표치 (표기 생략 가능)
          예시)SG, SG@11, SG@11#3, SG#3>=7, 3SG>=7

        ・행동 판정 이외의 표
          다음 표는 「굴릴 회수 + 명령어」로 여러 번 굴릴 수 있습니다.
          예시)3RCT, 2WT

        ・랜덤 특기 결정표 RTTn (n:특기분야 번호, 생략 가능)
          1 기술 2 체술 3 인술 4 모술 5 전술 6 요술

        ・랜덤 분야 표 RCT

        ・각종 표：기본 룰북 개정판 이후
          펌블 표 FT, 전장 표 BT, 감정 표 ET, 상태이상 표 WT, 전국 상태이상 표 GWT, 프라이즈 효과 표 PT
          요마화(이형 표, 요마 인법 표 일괄) MT, 이형표 MTR, 요마 인법 표(x:A,B,C) DSx

        ・각종 표：유파북 이후
          히라사카 유파북
            패닉 표 HRPT
          쿠라마 유파북
            새로운 전장 효과 표 BNT
          오토기 유파북
            각성 표 OTAT
            인법 수업 장면 표(x:1-공격계 2-방어계 3-보조계)NCTx
            【운명의 장난】OTS
          오니혈 유파북
            요술 상태이상 대응 표(x:없음-현대／전국, 1-현대, 2-전국)YWTx
            요마화(신 이형 표 사용) NMT, 신 이형 표 NMTR, 요마 인법 표(x:1-이령 2-흉신 3-신화 4-공격)DSNx
            매물 표 ONDT

        ・각종 표：기본 룰북 개정판 이전
          시노비가미 기본(문고판)
            구 펌블 표 OFT , 구 상태이상 표 OWT, 구 전장 표 OBT, 구 이형 표 MT
          시노비가미 괴(怪)
            괴 펌블 표 KFT, 괴 상태이상 표 KWT (기본 구판과 동일)

        ・장면 표
          기본 룰북
            기본 ST, 데지마 DST, 도시 CST, 저택 MST, 트러블 TST, 회상 KST, 일상 NST, 학교 GAST, 전국시대 GST
          인비전
            중급닌자 시험 HC, 멸망의 탑 HT, 그림자 거리에서 HK, 야행 열차 HY, 괴담 병동 HO, 린던 인법첩 이문 HR, 밀실 HM, 최면 HS
          정인기
            카지노 TC, 로드 무비 TRM, 마스커레이드 캐슬 TMC, 달밤에 피는 죽음 TGS, 연인과의 일상 TKH, 학교(흑성제) TKG, 마도학원 TMG, 마도도쿄 TMT
          유파북 이후
            오토기 유파북
              불량 고교 OTFK
          기본 룰북 개정판 이전
            死 기신궁전
              도쿄 TKST
            리플레이 전투 1~2권
              교토 KYST, 신사불각 JBST
          기타
            가을 하늘에 눈이 흩날리면 AKST, 여름의 끝 NTST, 데지마EX DXST, 재앙 CLST, 하스바 연구소 HLST, 배양 플랜트 PLST

        ・D66 주사위 포함
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
        @locale = :ko_kr
      end

      DEMON_SKILL_TABLES     = translate_demon_skill_tables(:ko_kr).freeze
      DEMON_SKILL_TABLES_NEW = translate_demon_skill_tables_new(:ko_kr).freeze
      TABLES                 = translate_tables(:ko_kr).freeze
      SCENE_TABLES           = translate_scene_tables(:ko_kr).freeze
      RTT                    = translate_rtt(:ko_kr)
    end
  end
end
