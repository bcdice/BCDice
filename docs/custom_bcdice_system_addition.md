# 新規システム追加マニュアル（カスタム BCDice 同梱運用）

このマニュアルは、以下の2リポジトリで運用する前提です。

- BCDice 側: `/home/mrrlll/program/BCDice`
- プロダクト側: `/home/mrrlll/program/ccfolian`

目的は「npm 公開や upstream PR をせず、`bcdice-js` カスタム tgz をプロダクトへ同梱して使う」ことです。

## 0. 前提

- Node.js `>=22`
- Ruby `3.2.x` 推奨（手元で動くなら `3.1.x` でも可）
- Bundler `2.6.3` を使用（`2.1.4` は環境によって不安定）

確認例:

```bash
node --version
ruby --version
bundle _2.6.3_ --version
```

## 1. BCDice 本体に新規システムを実装

以下を編集します。

1. `lib/bcdice/game_system/<SystemID>.rb` を追加
2. `lib/bcdice/game_system.rb` に `require "bcdice/game_system/<SystemID>"` を追加
3. `test/data/<SystemID>.toml` を追加

注意:

- `SORT_KEY` は規約に従うこと（`docs/dicebot_sort_key.md` を参照）
- `n=0` のような無効入力を `nil` にしたい場合はテストで `output = ""` を使う

## 2. BCDice のテストを通す

```bash
cd /home/mrrlll/program/BCDice
BUNDLE_WITH=development:test BUNDLE_WITHOUT= bundle exec rake test:dicebots target=<SystemID>
BUNDLE_WITH=development:test BUNDLE_WITHOUT= bundle exec rake test:unit
```

## 3. `bcdice-js` 用 patch を更新

この運用では `tools/bcdice/patches/0001-nejikure-nejimaki.patch` を再利用します。  
新規システム追加後はこの patch も更新してください。

最低限、次の差分を patch に含めます。

- `lib/bcdice/game_system/<SystemID>.rb`
- `lib/bcdice/game_system.rb`
- `test/data/<SystemID>.toml`

### 3-1. patch 再生成の実例（推奨）

`bcdice-js` の submodule 基準で patch を作り直す方法です。

```bash
cd /home/mrrlll/program/BCDice
TMP_DIR=$(mktemp -d /tmp/bcdice-js.XXXXXX)

git clone --depth 1 --branch v4.9.0 https://github.com/bcdice/bcdice-js.git "$TMP_DIR/bcdice-js"
git -C "$TMP_DIR/bcdice-js" submodule update --init --recursive

# ローカルの実装済みファイルを submodule 側にコピー
cp -f lib/bcdice/game_system/<SystemID>.rb "$TMP_DIR/bcdice-js/BCDice/lib/bcdice/game_system/"
cp -f lib/bcdice/game_system.rb "$TMP_DIR/bcdice-js/BCDice/lib/bcdice/"
cp -f test/data/<SystemID>.toml "$TMP_DIR/bcdice-js/BCDice/test/data/"

# patch を再生成
git -C "$TMP_DIR/bcdice-js/BCDice" diff > tools/bcdice/patches/0001-nejikure-nejimaki.patch

# 後片付け
rm -rf "$TMP_DIR"
```

## 4. カスタム tgz を再生成

```bash
cd /home/mrrlll/program/BCDice
CUSTOM_SUFFIX=nejikure.1 ./tools/bcdice/build-custom-bcdice.sh
```

ポイント:

- `CUSTOM_SUFFIX` は更新のたびにインクリメント（`nejikure.0 -> nejikure.1 -> ...`）
- 既存 tgz は自動で `vendor/bcdice/archive/` に退避される
- 必要なら Bundler を明示:

```bash
BUNDLER_VERSION=2.6.3 CUSTOM_SUFFIX=nejikure.1 ./tools/bcdice/build-custom-bcdice.sh
```

## 5. 生成物を確認

```bash
cd /home/mrrlll/program/BCDice
ls -la vendor/bcdice
tar -tzf vendor/bcdice/bcdice-4.9.0-nejikure.1.tgz | rg "lib/bcdice/game_system/<SystemID>.js"
```

## 6. プロダクトへ反映（ccfolian）

### 6-1. tgz をコピー

```bash
mkdir -p /home/mrrlll/program/ccfolian/vendor/bcdice
cp -f /home/mrrlll/program/BCDice/vendor/bcdice/bcdice-4.9.0-nejikure.1.tgz \
  /home/mrrlll/program/ccfolian/vendor/bcdice/
```

### 6-2. `package.json` を更新

`/home/mrrlll/program/ccfolian/package.json` の `dependencies.bcdice` を変更:

```json
"bcdice": "file:vendor/bcdice/bcdice-4.9.0-nejikure.1.tgz"
```

### 6-3. lockfile を更新

`ccfolian` は `bun.lock` を使うため、次を実行:

```bash
cd /home/mrrlll/program/ccfolian
bun install
```

## 7. プロダクト側の動作確認

```bash
cd /home/mrrlll/program/ccfolian
node - <<'NODE'
const { DynamicLoader } = require('bcdice');
(async () => {
  const loader = new DynamicLoader();
  const ids = loader.listAvailableGameSystems().map(s => s.id);
  console.log("has system:", ids.includes("<SystemID>"));
  const GS = await loader.dynamicLoad("<SystemID>");
  const result = GS.eval("<command sample>");
  console.log(result && result.text);
})();
NODE
```

加えて、既存代表システムも1つ確認します（例: `Cthulhu7th`）。

## 8. ロールバック手順

1. `package.json` の `bcdice` を旧 tgz に戻す
2. `bun install` を実行
3. 起動/判定を再確認

旧 tgz は `BCDice/vendor/bcdice/archive/` に残るため、必要に応じて `ccfolian/vendor/bcdice/` へコピーして使います。

## 9. 更新時のチェックリスト

1. BCDice 実装（3ファイル以上）を更新した
2. `test:dicebots` / `test:unit` が通った
3. `tools/bcdice/patches/0001-nejikure-nejimaki.patch` を更新した
4. 新しい `CUSTOM_SUFFIX` で tgz を再生成した
5. `package.json` / lockfile を更新した
6. 新システムの読み込みとコマンド実行を確認した
