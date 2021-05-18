# frozen_string_literal: true

require "bcdice/game_system/StellarKnights"

module BCDice
  module GameSystem
    class StellarKnights_Korean < StellarKnights
      # ゲームシステムの識別子
      ID = "StellarKnights:Korean"

      # ゲームシステム名
      NAME = "은검의 스텔라나이츠"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Korean:은검의 스텔라나이츠"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정　nSK[d][,k>l,...]
        []안은 생략 가능.
        n: 다이스 개수, d: 공격 판정 대상의 방어력, k>l: 다이스를 굴려 k가 나오면 l로 변경(아마란서스 스킬 중「시작의 방」용）
        d 생략 시 다이스를 굴린 결과만 표시. (nSK는 nB6과 동일)

        4SK: 다이스 4개를 굴린 결과 표시.
        4+2SK: ダイスを4+2 (=6) 個振って、その結果を表示
        5/2SK: ダイスを5個の半分 (=2) 個振って、その結果を表示
        (5+3)/2SK: ダイスを(5+3)個の半分 (=4) 個振って、その結果を表示
        5SK3: 【공격 판정: 5다이스】, 대상의 방어력을 3으로 계산해 성공 수 표시.
        3SK,1>6: 다이스 3개 굴림, 1이 나오면 전부 6으로 변경, 대상의 방어력을 4로 계산해 성공 수 표시.
        6SK4,1>6,2>6: 【공격 판정: 6다이스】, 1과 2가 나오면 전부 6으로 변경, 대상의 방어력을 4로 계산해 성공 수 표시.

        ・기본
        TT: 소재 표
        STA: 상황 표 A: 시간 (Situation Table A)
        STB: 상황 표 B-1: 장소 (ST B)
        STB2[n]: 상황 표 B-2: 학원편 (ST B 2)
        　n: 1(아셀트레이 공립대학), 2(이데아글로리아 예술종합대학), 3(시트라 여학원), 4(필로소피아 대학), 5(성 아제티아 학원), 6(스폰 오브 아셀트레이)
        STC: 상황 표 C: 화제 (ST C)
        ALLS: 상황 표 전체 일괄 굴림 (학원편 제외)
        GAT: 소속 조직 결정 (Gakuen Table)
        HOT: 희망 표 (Hope Table)
        DET: 절망 표 (Despair Table)
        WIT: 소원 표 (Wish Table)
        YST: 당신의 이야기 표 (Your Story Table)
        YSTA: 당신의 이야기 표 (이세계) (YST Another World)
        PET: 성격 표 (Personality Table)
            성격 표를 2번 굴려 성격을 결정한다.

        ・안개와 벚꽃의 마르지날리아
        YSTM: 당신의 이야기 표 (마르지날리아) (YST Marginalia)
        STM: 상황 표: 마르지날리아 (ST Marginalia)
        YSTL: 당신의 이야기 표 (편지) (YST Letter)
        YSTR: 당신의 이야기 표 (리콜렉트 돌) (YST Recollect-doll)
        STBR: 상황 표 B: 장소 (리콜렉트 돌) (ST B Recollect-doll)
        STCR: 상황 표 C: 리콜렉트 (ST C Recollect)
        STBS: 상황 표 B: 시트라 세팅 (ST B Sut Tu Real)
        STE: 상황 표: 이클립스 전용 (ST Eclipse)

        ・자탄의 알트리부트
        FT: 프래그먼트 표 (Fragment Table)
            프래그먼트 표를 5번 굴린다.
        FTx: 프래그먼트 표를 x회 굴린다.
        YSTB: 당신의 이야기 (브링거) (YST Bringer)
        YSTF: 당신의 이야기 (포지) (YST Forge)
        STAL: 상황 표 (알트리부트) (ST Alt-Levoot)
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
    end
  end
end
