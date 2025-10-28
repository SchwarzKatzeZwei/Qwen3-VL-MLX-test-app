# Qwen3-VL MLX Demo (iPad)

このリポジトリは、iPad Pro 上で Apple の **MLX Swift** ランタイムを使って
[Qwen3-VL-4B-Instruct-MLX-4bit](https://huggingface.co/mlx-community/Qwen3-VL-4B-Instruct-MLX-4bit)
を実行する SwiftUI デモアプリです。カメラまたはフォトライブラリから写真を取得し、
任意のプロンプトでビジョン・ランゲージ推論を行い、生成された文章を画面に表示します。

> ⚠️ **注意**: MLX Swift の Vision-Language API は頻繁に更新されています。
> `QwenVLModel` の実装は最新の `mlx-swift` main ブランチを前提にしています。
> API の変更に合わせて型名 / メソッド名を調整してください。

## 構成

```
QwenVLDemo/
├─ QwenVLDemo.xcodeproj/      # iPad アプリの Xcode プロジェクト
├─ QwenVLDemo/
│  ├─ App/                    # SwiftUI 画面ロジック
│  ├─ ViewModel/              # 状態管理と推論トリガー
│  ├─ MLX/                    # MLX Swift によるビジョン言語パイプライン
│  ├─ Utils/                  # 画像読み込みやデフォルトプロンプト処理
│  ├─ Resources/              # Assets / プロンプト JSON / Info.plist
├─ Scripts/
│  └─ download_model.py       # Hugging Face からモデルを取得するヘルパー
└─ README.md                  # このファイル
```

## 必要条件

- iPad Pro (M2/M4 チップ) もしくは Apple シリコン搭載 Mac + Xcode 15 以降
- iPadOS 17.4 以降（MLX Swift がサポートする最小バージョンに合わせてください）
- Xcode 15.4 以降 & Swift 5.9 以上
- `mlx-swift` パッケージ (Xcode から自動取得)
- Hugging Face アカウントとアクセストークン（モデルのダウンロードに使用）

## セットアップ手順

### 1. リポジトリを取得

```
git clone <this-repo>
cd QwenVLDemo
open QwenVLDemo.xcodeproj
```

Xcode で開いたら、自動的に `mlx-swift` パッケージを解決します。失敗する場合は
`File > Packages > Reset Package Caches` を実行した後に再取得してください。

### 2. モデルをダウンロード

1. Python 3.11 以降と `huggingface_hub` をインストールします。
   ```bash
   pip install --upgrade huggingface_hub
   ```
2. スクリプトを実行してモデルをローカルに取得します。
   ```bash
   cd QwenVLDemo/Scripts
   python download_model.py --token hf_xxx --output ./Models/Qwen3-VL-4B-Instruct-MLX-4bit
   ```
3. ダウンロードされたフォルダを **アプリの Application Support/Models** 配下に配置します。
   - Mac でビルドする場合はビルド後に `~/Library/Containers/<bundle-id>/Data/Library/Application Support/Models/` にコピーします。
   - iPad にサイドロードする場合は、Finder または iCloud Drive を使って
     `Files` アプリ内の `Qwen VL Demo/Library/Application Support/Models/` に転送してください。

> **ヒント**: ディスク容量節約のため不要なファイル（README, LICENSE など）はダウンロード時に除外しています。

### 3. ビルド & 実行

1. ターゲットデバイスとして iPad（実機）を選択します。
2. 初回起動時にカメラとフォトライブラリのアクセス許可を求められるので許可してください。
3. アプリ画面で写真を撮影/選択し、デフォルトのプロンプトを必要に応じて編集して「文章を生成」をタップします。
4. 推論が完了すると生成テキストが表示されます。

## コードのポイント

- **ContentView**: `PhotosPicker` を使って画像を取得し、`TextEditor` で自由入力できるプロンプトを提供します。
- **QwenVLViewModel**: 画像の読み込み、モデル初期化、推論呼び出しのフローを管理。
- **QwenVLModel**: `mlx-swift` の Vision-Language API をラップし、画像エンコーディングとテキスト生成を行います。
- **PromptDefaults**: バンドル内の JSON から初期プロンプトを読み込むと同時に、Application Support 内のモデルパス解決を担当します。

## トラブルシューティング

| 症状 | 対処 |
| ---- | ---- |
| `mlx-swift` がビルドできない | Xcode の `File > Packages > Reset Package Caches` を実行、または `DerivedData` をクリアしてください。 |
| アプリ開始時に "モデルを初期化できませんでした" と表示 | モデルフォルダが Application Support の `Models/Qwen3-VL-4B-Instruct-MLX-4bit` に存在するか確認してください。 |
| 生成が極端に遅い | 温度や `maxTokens` を `QwenVLModel` の `GenerationConfig` 内で調整してください。 |
| API 変更でビルドが通らない | `QwenVLModel` 内のラッパークラス（`VisionLanguageChat`, `QwenVisionEncoder` 等）を最新の MLX Swift API に合わせて書き換えてください。 |

## ライセンスと利用規約

- Qwen3-VL モデルは Alibaba Cloud / Qwen チームのライセンスに従います。利用前に必ずライセンスを確認してください。
- このデモコードは学習用サンプルです。商用利用を行う場合はライセンス条件を遵守し、必要に応じて法務確認を行ってください。

## 参考リンク

- [mlx-swift GitHub リポジトリ](https://github.com/ml-explore/mlx-swift)
- [mlx-community / Qwen3-VL-4B-Instruct-MLX-4bit (Hugging Face)](https://huggingface.co/mlx-community/Qwen3-VL-4B-Instruct-MLX-4bit)
- [Pictures API / PhotosPicker 公式ドキュメント](https://developer.apple.com/documentation/photosui/photospicker)
