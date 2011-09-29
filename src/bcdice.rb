#!/bin/ruby -Ku 
#--*-coding:utf-8-*--
#=================================================================================
#【ソフト名】 ゲーム設定型ダイスボット「ボーンズ＆カーズ」
#【著作権者】 Faceless & たいたい竹流
#【対応環境】 
# Windows環境： 
#  bcdice.exe を直接実行してご利用ください。
# Windows以外のOS:
#  Ruby1.8をインストールした上で下記のコマンドでライブラリをインストール願います
#    gem install net-irc
#    gem install wxruby
#  後は ruby -Ku bcdice.rb で起動が可能です。
#【開発環境】 WindowsXP Pro SP2 + P4 
#【開発言語】 ActiveScriptRuby(1.8.7-p330)（DL元：http://www.artonx.org/data/asr/ )
# 開発時には【対応環境】記載のライブラリをインストール願います（Windowsの場合も）
# EXEファイルを作成する場合は添付の createExe.bat を実行願います。
#【 種 別 】 フリーウエア(修正BSDライセンスに準拠) 
#【転載条件】 修正BSDライセンス上で許可
#【連絡先 及び １次配布】 https://github.com/torgtaitai/BCDice
#=================================================================================

require 'config.rb'
require 'bcdiceGui.rb'

mainBcDiceGui
