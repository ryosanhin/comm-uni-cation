# 非同期Resourceローダー

`async_resource_loader.gd` はRefCountedです。読み込み状況の再確認を知らせるSignalを
コンストラクタへ渡し、リクエストごとに `LoadRequest` を生成します。

```gdscript
const AsyncResourceLoader := preload("res://async_resource_loaders/async_resource_loader.gd")

var loader := AsyncResourceLoader.new(get_tree().process_frame)
var request := loader.create_request(resource_reference, "PackedScene")
if not request.is_completed():
	await request.completed
if not request.is_success():
	push_error(AsyncResourceLoader.format_error(request))
	return
var resource := request.resource
```

- `create_request()` は読み込みを開始して直ちにリクエストを返します。ローダーはリクエスト一覧や読み込み中のパスを管理しません。
- `LoadRequest` は1回の読み込み処理、完了状態、結果を保持します。読み込み処理は生成時に一度だけ開始し、再実行しません。
- `resource_reference` には `uid://...` のUIDを基本として指定します。`res://...` パスも利用できます。
- `resolve_resource_path()` でUIDを現在のパスへ解決し、要求・状態確認・結果取得には同じパスを使います。解決できないUIDは `RESOURCE_NOT_FOUND` になります。
- 各リクエストは `ResourceLoader.load_threaded_request()` で要求し、未完了なら渡されたシグナルを待ち、発火時に状態を再確認します。成功した要求は失敗時も含めて結果を一度回収します。
- 同じリソースへの複数要求も受け付けます。各呼び出しは別のリクエストを返し、実際の読み込みや標準キャッシュの共有はGodotに任せます。用途上の重複要求の抑制は呼び出し側で行います。
- リクエストは `error_code`、`resource`、呼び出し元が指定したUIDまたはパスを保持する `resource_path`、要求失敗時の `request_error` を保持します。
- `completed` は成功・失敗にかかわらず、結果と完了状態の確定後に一度だけ発火します。即時失敗やキャッシュ済みリソースでは、生成から戻る前に完了する場合があります。待機前に `is_completed()` を確認してください。完了通知は蓄積されません。
- `is_success()` は完了して成功した場合だけtrueを返します。読み込み中はfalseです。結果の型は呼び出し側で確認します。
- `format_error()` で説明文へ変換できます。表示は呼び出し側で行います（Godot内部のエラーログは出る場合があります）。
- エラーコードは `EMPTY_PATH`、`RESOURCE_NOT_FOUND`、`REQUEST_FAILED`、`LOAD_FAILED`、`INVALID_REQUEST` です。成功は `OK` です。
- 読み込み中はリクエストとシグナルの発行元を維持してください。生成元のローダーは、リクエストを返した後は保持する必要がありません。
- 完了後もリクエストは結果のResourceを保持します。不要になったリクエストへの参照を外すと、その保持も終了します。他のノードやResourceが参照するアセットは、その参照が残っている間は保持されます。
- シーン以外のResourceにも利用できます。生成・ツリーへの追加は呼び出し側の責務です。

## 確認タイミング

`SceneTree.process_frame` なら毎フレーム、繰り返すTimerの `timeout` なら一定間隔で確認します。
有効なシグナルを渡し、読み込み中も発火し続けるようにしてください。
待機前の発火は蓄積されません。バックグラウンド側で読み込みが終わっても、
次の通知がなければ待機中の処理は再開しません。
ローダーとリクエスト自身はNodeやSceneTreeを取得せず、ツリーへの配置も不要です。
