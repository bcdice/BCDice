# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      private

      def roll_muchaburi_table(command)
        case command
        when "LUR"
          title = "地方アイドル無茶ぶり表"
          table1 = [
            "地元の商店街で",
            "マスコットキャラクターと",
            "地元のプールで",
            "地元の小学校で",
            "地元のショッピングモールで",
            "田んぼの真ん中で",
          ]
          table2 = [
            "愛について叫ぶ",
            "民謡を歌う",
            "ファッションショー",
            "水着で宣伝",
            "ネット配信",
            "お祭り騒ぎ",
          ]
          return textFrom1D6Table(title, table1, table2)

        when "SUR"
          title = "情熱の夏無茶ぶり表"
          table1 = [
            "海水浴場で",
            "偉い人の前で",
            "あの有名アイドルの前で",
            "仲間の前で",
            "カメラの前で",
            "一般客の前で",
          ]
          table2 = [
            "かき氷いっき食い",
            "ナンパ",
            "スイカ割り",
            "カッコいいポーズ",
            "満面の笑顔",
            "喧嘩のふり",
          ]
          return textFrom1D6Table(title, table1, table2)

        when "WUR"
          title = "ぬくもりの冬無茶ぶり表"
          table1 = [
            "クリスマスツリーの前で",
            "子供たちの前で",
            "大雪の中で",
            "雪が降り始めた街で",
            "暖かい部屋の中で",
            "暖房が効きすぎの部屋の中で",
          ]
          table2 = [
            "雪かき",
            "アイスを食べる",
            "薄着で登場",
            "歌ってください",
            "サンタのコスプレ",
            "おでんを急いで食べる",
          ]
          return textFrom1D6Table(title, table1, table2)

        when "NUR"
          title = "大自然無茶ぶり表"
          table1 = [
            "斧を持って",
            "クワを持って",
            "釣竿を持って",
            "虫取り網を持って",
            "栄養ドリンクの宣伝をしながら",
            "命綱をつけて",
          ]
          table2 = [
            "木を倒す",
            "畑を耕す",
            "昆虫採集",
            "大物を釣る",
            "一晩過ごす",
            "崖を登る",
          ]
          return textFrom1D6Table(title, table1, table2)

        when "GUR"
          title = "聖デトワール女学園無茶ぶり表"
          table1 = [
            "裏山で",
            "食堂で",
            "先輩の前で",
            "全国放送で",
            "全校生徒の前で",
            "学園の様子を伝えるネット中継で",
          ]
          table2 = [
            "歌を披露",
            "乗馬",
            "テニス",
            "「個性とは何か」を語る",
            "「アイドルとは何か」を語る",
            "「アイドルをやっていてよかった瞬間」を語る",
          ]
          return textFrom1D6Table(title, table1, table2)

        when "BUR"
          title = "アカデミー無茶ぶり表"
          table1 = [
            "TVカメラの前で",
            "ライバルと一緒に",
            "試験で",
            "寮で",
            "幼年部で",
            "初等部で",
          ]
          table2 = [
            "反省会",
            "ゲリラライブ",
            "宿題をこなす",
            "食事を作る",
            "自作の歌を披露",
            "自作のポエムを披露",
          ]
          return textFrom1D6Table(title, table1, table2)
        end

        return nil
      end
    end
  end
end
