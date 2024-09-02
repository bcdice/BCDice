# frozen_string_literal: true

require "bcdice/game_system/SkynautsBouken"

module BCDice
  module GameSystem
    class SkynautsBouken_Korean < SkynautsBouken
      # ゲームシステムの識別子
      ID = 'SkynautsBouken:Korean'

      # ゲームシステム名
      NAME = '톱니바퀴 탑의 탐공사'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:톱니바퀴 탑의 탐공사'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・행위판정（nSNt#f） n:다이스 수(생략시 2), t:목표치(생략시 7), f:펌블치(생략시 1)
            예）SN6#2　3SN
        ・대미지 체크 (Dx/y@m) x:대미지 범위、y:공격횟수
        　　m:《탄도학》（생략 가능）상:8, 하:2, 좌:4, 우:6
        　　예） D/4　D19/2　D/3@8　D[진동]/2
        ・회피(AVO@m대미지)
        　　m:회피 방향(상:8, 하:2, 좌:4, 우:6), 대미지: 대미지 체크 결과
        　　예）AVO@8[1,4],[2,6],[3,8]　AVO@2[6,4],[2,6]
        ・FT 펌블표(p76)
        ・NV 항행표
        ・항행이벤트표
        　・NEN 항행계
        　・NEE 조우계
        　・NEO 선내계
        　・NEH 곤란계
        　・NEL 장거리 여행계

        ■ 판정 세트
        ・《회피운동》판정+회피（nSNt#f/AVO@대미지）
        　　nSNt#f → 성공하면 AVO@m
        　　예）SN/AVO@8[1,4],[2,6],[3,8]　3SN#2/AVO@2[6,4],[2,6]
        ・포격 판정+대미지 체크　(nSNt#f/Dx/y@m)
        　　행위 판정의 출발(出目) 변경 타이밍을 놓치므로 GM의 허가 필요
        　　nSNt#f → 성공하면 Dx/y@m
        　　예）SN/D/4　3SN#2/D[진동]/2
      MESSAGETEXT

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
      
      register_prefix_from_super_class()

      # 프록시 메서드 정의
      def tables
        call_private_translate_tables
      end
      def direction_infos
        call_private_translate_direction_infos
      end

      private

      def eval_game_system_specific_command(command)
        # 동적으로 TABLES와 DIRECTION_INFOS 사용
        command_sn(command) || command_d(command) || command_avo(command) || command_snavo(command) ||
          command_snd(command) || roll_tables(command, tables)
      end

      # command_d와 같은 메서드에서 direction_infos를 동적으로 호출
      def command_d(command)
        m = D_REGEXP.match(command)
        return nil unless m

        fire_count = m[3].to_i # 砲撃回数
        fire_range = m[1].to_s # 砲撃範囲
        ballistics = m[5].to_i # 《弾道学》

        points = get_fire_points(fire_count, fire_range)
        command = command.sub("SF/", "[#{translate('SkynautsBouken.big_shake')},#{translate('SkynautsBouken.fire')}]/")
                         .sub("FS/", "[#{translate('SkynautsBouken.fire')},#{translate('SkynautsBouken.big_shake')}]/")
                         .sub("F/", "[#{translate('SkynautsBouken.fire')}]/").sub("S/", "[#{translate('SkynautsBouken.big_shake')}]/")
        result = ["(#{command})", get_points_text(points, 0, 0)]
        if ballistics != 0
          dir = direction_infos[ballistics]
          diff_x, diff_y = dir[:position_diff]
          result[-1] += "\n"
          result << "《#{translate('SkynautsBouken.ballistics')}》#{dir[:name]}"
          result << get_points_text(points, diff_x, diff_y)
        end

        result.compact.join(" ＞ ")
      end

      def command_avo(command)
        debug("AVO", command)
        dmg = command.match(/^AVO@([2468])(.*?)$/)
        return nil unless dmg

        dir = direction_infos[dmg[1].to_i]
        diff_x, diff_y = dir[:position_diff]
        "《#{translate('SkynautsBouken.avoidance')}》#{dir[:name]} ＞ " + dmg[2].gsub(/\(?\[(\d),(\d{1,2})\]\)?/) do
          y = Regexp.last_match(1).to_i + diff_y
          x = Regexp.last_match(2).to_i + diff_x
          get_xy_text(x, y)
        end
      end

      # `send` 메서드를 사용하여 부모 클래스의 private 메서드 호출
      def call_private_translate_tables
        self.class.send(:translate_tables, @locale)
      end
      def call_private_translate_direction_infos
        self.class.send(:translate_direction_infos, @locale)
      end

    end
  end
end
