# 非同期Resourceローダー

`async_resource_loader.gd` をツリー内のNodeとして配置し、次のように呼び出します。

```gdscript
var resource := await loader.load_resource(resource_path, "PackedScene")
```

- `ResourceLoader.load_threaded_request()` で読み込みを開始し、完了状態を毎フレーム確認します。
- 結果はResource、失敗時はnullです。型の確認は呼び出し側で行います。
- シーン以外のResourceにも利用できます。生成・ツリーへの追加は呼び出し側の責務です。
- 同じローダーへの異なるパスの要求は並行して待機できます。同じパスの読み込み中の重複要求は拒否します。
- 同じパスの読み込みはこのローダーへ集約してください。読み込み中にローダーをツリーから削除しないでください。
- 結果をキャッシュする独自の保持処理や完了シグナルはありません。呼び出し側はawaitで結果を受け取ります。
- エンジンの標準キャッシュを利用します。パス方式でも他のノードやResourceの参照があるアセットは保持されます。
