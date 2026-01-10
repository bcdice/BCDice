# frozen_string_literal: true

require "bcdice/game_system/kizuna_bullet/tables"

module BCDice
  module GameSystem
    class KizunaBullet_Korean < KizunaBullet
      # ゲームシステムの識別子
      ID = 'KizunaBullet:Korean'

      # ゲームシステム名
      NAME = '키즈나 불릿'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:키즈나 불릿'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・다이스 롤
        nDM...n개의 6면 다이스를 굴려 가장 높은 값을 사용합니다.
        ・［조사 판정］
        nIN…n개의 6면 다이스를 굴려 가장 높은 값이 5 이상이면 성공합니다. ([파트너의 헬프] 사용가능)
        ・［진정 판정］
        SEn…2개의 6면 다이스를 굴려 합계치가 n([균열]상태의 [키즈나]의 개수)보다 높으면 성공합니다. ([강제 진정]사용가능)
        ・［해결］ ［액션］의 대미지와［액시던트］의 대미지 경감
        nSO…2+n개의 6면 다이스를 굴려 결과값을 모두 합산합니다. (n은 줄인 【여기치】. 생략 가능)

        ・각종표
        일상 표・장소 OP
        일상 표・내용 OC
        일상 표・장소 및 내용 OPC
        일상 표(일)・장소 OWP
        일상 표(일)・내용 OWC
        일상 표(일)・장소 및 내용 OWPC
        일상 표(휴가)・장소 OHP
        일상 표(휴가)・내용 OHC
        일상 표(휴가)・장소 및 내용 OHPC
        일상 표(출장)・장소 OTP
        일상 표(출장)・내용 OTC
        일상 표(출장)・장소 및 내용 OTPC

        턴 테마표 TT
        턴 테마표・친밀 TTI
        턴 테마표・쿨 TTC
        턴 테마표・주종 TTH

        조우 표・장소 EP
        조우 표・출현 순서 EO
        조우 표・상황(첫대면) EF
        조우 표・상황(아는 사이) EA
        조우 표・결착 EE
        조우 표·장소와 등장 순서와 상황(첫대면)과 결착 EFA
        조우 표·장소와 등장순서와 상황(아는 사이)과 결판 EAA

        교류 표·장소 CP
        교류 표·내용 CC
        교류 표·장소 및 내용 CPC

        조사 표 · 베이직 IB
        조사 표・다이나믹 ID
        조사 표・베이직과 다이나믹 IBD

        해저드 표 HA

        통상 다이제스트: 당신들에게 새로운 명령이 떨어졌다(조사가 의뢰되었다).
        1:그 사건의 내용은……. NI1
        2:조사하러 향한 장소는…… NI2
        3:범인인 기적사는…… NI3
        4:일어난 일은……. NI4
        5:불릿 사이에서는…… NI5
        6:싸움의 결말은…… NI6

        통상 다이제스트: 당신들은 여행(출장)으로 어느 장소를 찾았다.
        1:그 장소란…… NT1
        2:그곳에서 시작한 것은…… NT2
        3:극한의 상황 속에서…… NT3
        4:범인인 기적사는…… NT4
        5:불릿 사이에서는…… NT5
        6:싸움의 결말은…… NT6

        홀리데이 다이제스트: 당신들은 휴일에 나가기로 했다.
        1:그 장소란…… HH1
        2:약속하고 만나면…… HH2
        3:그리고 무려……… HH3
        4:두 사람이 결정한 것은…… HH4
        5:결과적으로…… HH5
        6:불릿은 마지막으로…… HH6

        홀리데이 다이제스트: 당신들은 기묘한 사건을 마주했다.
        1:그 장소란…… HC1
        2:일어난 사건은……. HC2
        3:범인인 시적사는…… HC3
        4:범인을 몰아붙이기 위해…… HC4
        5:싸움의 결과는…… HC5
        6:불릿은 마지막으로……HC6
      MESSAGETEXT

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)

      register_prefix_from_super_class()
    end
  end
end
