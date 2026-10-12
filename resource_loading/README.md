# 非同期Resourceローダー

`async_resource_loader.gd` をツリー内のNodeとして配置し、次のように呼び出します。

```gdscript
const AsyncResourceLoader := preload("res://resource_loading/async_resource_loader.gd")

var result := await loader.load_resource(resource_path, "PackedScene")
if not result.is_success():
	push_error(AsyncResourceLoader.format_error(result))
	return
var resource := result.resource
```

- `ResourceLoader.load_threaded_request()` で読み込みを開始し、完了状態を毎フレーム確認します。
- 結果は `LoadResult` です。`error_code`、`resource`、`resource_path`、要求失敗時の `request_error` を保持します。
- `is_success()` で成否を判定します。成功時だけ `resource` を取得でき、型の確認は呼び出し側で行います。
- `format_error()` で説明文へ変換できます。ローダー自身はpush_errorを呼ばず、表示は呼び出し側で行います（Godot内部のエラーログは出る場合があります）。
- エラーコードは `EMPTY_PATH`、`RESOURCE_NOT_FOUND`、`ALREADY_LOADING`、`REQUEST_FAILED`、`LOAD_FAILED`、`INVALID_REQUEST` です。成功は `OK` です。
- シーン以外のResourceにも利用できます。生成・ツリーへの追加は呼び出し側の責務です。
- 同じローダーへの異なるパスの要求は並行して待機できます。同じパスの読み込み中の重複要求は拒否します。
- 同じパスの読み込みはこのローダーへ集約してください。読み込み中にローダーをツリーから削除しないでください。
- 結果をキャッシュする独自の保持処理や完了シグナルはありません。呼び出し側はawaitで結果を受け取ります。
- エンジンの標準キャッシュを利用します。パス方式でも他のノードやResourceの参照があるアセットは保持されます。
