# frozen_string_literal: true

require "bcdice/game_system/CyberpunkRed"

module BCDice
  module GameSystem
    class CyberpunkRed_Korean < CyberpunkRed
      # ゲームシステムの識別子
      ID = 'CyberpunkRed:Korean'

      # ゲームシステム名
      NAME = '사이버펑크 RED'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:사이버펑크'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ・판정　CPx+y>z
          　(x＝능력치와 기능치의 합(base)、y＝수정치(mod)、z＝난이도(DV) or 방어자의 값　x、y、z는 생략 가능)
          　예시）CP12, CP10+2>12,　CP7-1,　CP8+4,　CP7>12,　CP,　CP>9

          각종 표
          ・치명적인 손상표
          　FFD　：신체에 치명적 손상
          　HFD　：머리에 치명적 손상
          ・조우 표
          　NCDT　：나이트시티(낮)
          　NCMT　：나이트 시티(심야)
          ・스크림 시트(신문)
          　SCSR　：스크림 시트(랜덤)
          　SCST　：스크림 시트 카테고리
          　SCSA　：헤드 라인A
          　SCSB　：헤드 라인B
          　SCSC　：헤드 라인C
          ・가장 가까운 자판기
          　VMCR　：가장 가까운 자판기표
          　VMCT　：자판기 유형 결정표
          　VMCE　：식품
          　VMCF　：패션
          　VMCS　：이상한 물건
          ・보데가(상점) 손님
          　STORE　：상점 손님과 점원
          　STOREA　：점주 또는 계산원
          　STOREB　：별난 손님 1
          　STOREC　：별난 손님 2
          ・야시장
          　NMCT　：상품의 분야
          　NMCFO　：음식과 약물
          　NMCME　：개인용 전자기기
          　NMCWE　：무기와 갑옷
          　NMCCY　：사이버웨어
          　NMCFA　：의류 및 패션웨어
          　NMCSU　：생존 장비(servival gear)
      HELP

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      register_prefix_from_super_class()
      TABLES = translate_tables(:ko_kr)
    end
  end
end
