# frozen_string_literal: true

require "bcdice/game_system/DoubleCross"

module BCDice
  module GameSystem
    class DoubleCross_Korean < DoubleCross
      # ゲームシステムの識別子
      ID = 'DoubleCross:Korean'

      # ゲームシステム名
      NAME = '더블크로스2nd,3rd'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:더블크로스'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정 커맨드（xDX+y@c or xDXc+y）
        　"(개수)DX(수정)@(크리티컬치)" 혹은 "(개수)DX(크리티컬치)(수정)" 으로 지정합니다.
        　수정치도 붙일 수 있습니다.
        　예）10dx　　10dx+5@8（OD tool식)　　5DX7+7-3（질풍노도식）
        ・각종표
        　・감정표（ET）
        　　포지티브와 네거티브 양쪽을 굴려, 겉으로 나타는 쪽에 O를 붙여 표시합니다.
        　　물론 임의로 정하는 부분을 변경해도 괜찮습니다.
        ・해프닝차트（HC)
        ・RW프롤로그차트 포지티브（PCP）
        ・RW프롤로그차트 네거티브（PCN）
        ・D66다이스 있음
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      class DX < DoubleCross::DX
        # @param (see DoubleCross::DX#initialize)
        def initialize(num, critical_value, modifier, target_value)
          super(num, critical_value, modifier, target_value)

          @locale = :ko_kr
        end
      end

      # 感情表（ポジティブ）
      POSITIVE_EMOTION_TABLE = positive_emotion_table(:ko_kr).freeze
      # 感情表（ネガティブ）
      NEGATIVE_EMOTION_TABLE = negative_emotion_table(:ko_kr).freeze
      TABLES = translate_tables(:ko_kr).freeze
      register_prefix('\d+DX', TABLES.keys)
    end
  end
end
