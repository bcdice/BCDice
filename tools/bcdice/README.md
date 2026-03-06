# bcdice custom build tools

このディレクトリは、`bcdice-js` をローカルでビルドして、プロダクトで使う `bcdice` の tgz を生成するためのものです。

推奨実行環境:

- Node.js `>=22`
- Ruby `3.2.x`

## 構成

- `patches/0001-nejikure-nejimaki.patch`
  - `NegikureNegimaki` (`NN`) 対応差分
- `build-custom-bcdice.sh`
  - `bcdice-js` を clone して patch を適用し、`npm pack` で tgz を生成

## 使い方

```bash
./tools/bcdice/build-custom-bcdice.sh
```

既定値:

- `BCDICE_JS_REF=v4.9.0`
- `CUSTOM_SUFFIX=nejikure.0`
- `BUNDLER_VERSION=2.6.3`

出力:

- `vendor/bcdice/bcdice-4.9.0-nejikure.0.tgz`（既存があれば `vendor/bcdice/archive/` に退避）

## オプション

```bash
BCDICE_JS_REF=v4.9.0 CUSTOM_SUFFIX=nejikure.1 BUNDLER_VERSION=2.6.3 KEEP_WORK_DIR=1 ./tools/bcdice/build-custom-bcdice.sh
```

## ログ出力

スクリプトは実行時に次を必ず出力します。

- `bcdice-js` の commit
- `BCDice` submodule commit（patch適用後）
- 出力 tgz ファイル名

## プロダクト側設定例

`package.json` の `dependencies` で `bcdice` を `file:` 参照にします。

```json
{
  "dependencies": {
    "bcdice": "file:vendor/bcdice/bcdice-4.9.0-nejikure.0.tgz"
  }
}
```

その後、利用しているパッケージマネージャで lockfile を更新します。

- npm: `npm install`
- pnpm: `pnpm install`
- yarn: `yarn install`
