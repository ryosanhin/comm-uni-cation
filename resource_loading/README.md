# 非同期Resourceローダー

`async_resource_loader.gd` はRefCountedです。読み込み状況の再確認を知らせるSignalを
コンストラクタへ渡し、次のように呼び出します。

```gdscript
const AsyncResourceLoader := preload("res://resource_loading/async_resource_loader.gd")

var loader := AsyncResourceLoader.new(get_tree().process_frame)
var result := await loader.load_resource(resource_path, "PackedScene")
if not result.is_success():
	push_error(AsyncResourceLoader.format_error(result))
	return
var resource := result.resource
```

- `ResourceLoader.load_threaded_request()` で読み込みを開始し、未完了なら渡されたシグナルを待ち、発火時に状態を再確認します。
- 結果は `LoadResult` です。`error_code`、`resource`、`resource_path`、要求失敗時の `request_error` を保持します。
- `is_success()` で成否を判定します。成功時だけ `resource` を取得でき、型の確認は呼び出し側で行います。
- `format_error()` で説明文へ変換できます。ローダー自身はpush_errorを呼ばず、表示は呼び出し側で行います（Godot内部のエラーログは出る場合があります）。
- エラーコードは `EMPTY_PATH`、`RESOURCE_NOT_FOUND`、`ALREADY_LOADING`、`REQUEST_FAILED`、`LOAD_FAILED`、`INVALID_REQUEST` です。成功は `OK` です。
- シーン以外のResourceにも利用できます。生成・ツリーへの追加は呼び出し側の責務です。
- 同じローダーへの異なるパスの要求は並行して待機できます。同じパスの読み込み中の重複要求は拒否します。
- 同じパスの読み込みはこのローダーへ集約してください。読み込み中はローダーとシグナルの発行元を維持してください。
- 結果をキャッシュする独自の保持処理や完了シグナルはありません。呼び出し側はawaitで結果を受け取ります。
- エンジンの標準キャッシュを利用します。パス方式でも他のノードやResourceの参照があるアセットは保持されます。

## 確認タイミング

`SceneTree.process_frame` なら毎フレーム、繰り返すTimerの `timeout` なら一定間隔で確認します。
有効なシグナルを渡し、読み込み中も発火し続けるようにしてください。
待機前の発火は蓄積されません。バックグラウンド側で読み込みが終わっても、
次の通知がなければ待機中の処理は再開しません。
ローダー自身はNodeやSceneTreeを取得せず、ツリーへの配置も不要です。
