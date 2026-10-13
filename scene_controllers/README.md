# シーン切り替え

このディレクトリは、専用ルート配下のシーン交換と画面遷移を管理します。
読み込みには `async_resource_loaders/async_resource_loader.gd` を利用します。
ゲーム固有のIDは `scenes/scene_ids.gd` と `scenes/transition_ids.gd`、
登録内容は `scenes/settings/` に置き、`scenes/core.tscn` で設定します。

## 設定

- `SceneRegistry` は `StringName` のIDと `SceneEntry` を対応付けます。
  `SceneEntry.scene_path` にシーンのUIDを設定します。通常のリソースパスも利用できます。登録だけではシーンを読み込みません。
- `TransitionRegistry` は `StringName` のIDと `TransitionEntry` を対応付けます。
- `SceneController` の `_scene_registry` と、子の `TransitionController` の
  `_transition_registry` は、利用するプロジェクト側で設定します。
- `_main_scenes_root` には交換対象のシーンだけを配置します。交換時にはすべての子を削除します。
- 初期シーンは外部で配置し、対応する `init_scene_id` を設定します。
  IDの設定だけではシーンを生成しません。空のIDは未設定を表します。
- 常駐ノードは専用ルートの外へ置き、各シーンの子シーンはそのシーン自身で管理します。

## 通知

| シグナル | タイミング |
|---|---|
| `scene_change_started` | 要求を受理し、画面を覆う演出を始める前 |
| `scene_replaced` | 新シーンを追加して1フレーム待ち、現在IDを更新した後。画面を戻す演出の前 |
| `scene_changed` | 画面を戻す演出と遷移中状態の解除が済んだ後 |

各通知には切り替え先のIDを渡します。`scene_replaced` はBGMの変更や表示前の設定に使えます。
シーン独自の非同期初期化や、通知を受けた処理の非同期完了を待つものではありません。

## 読み込み

ローダーはRefCountedとしてシーン読み込み時に生成し、`get_tree().process_frame` を渡します。
子ノードの配置やローダーのNodePath設定は不要です。

`is_loaded()` はUIDを現在のパスへ解決し、ノードの `scene_file_path` と比較します。

画面を覆った後、`AsyncResourceLoader.new(entry.scene_path, get_tree().process_frame, "PackedScene")` でリクエストを生成します。
未完了なら `completed` をawaitします。即時完了の場合はそのまま結果を利用します。
SceneControllerが渡す `process_frame` シグナルで完了状態を確認し、読み込んだResourceを取得してからメインスレッドで
シーンを生成・追加します。生成や `_ready()` 自体はバックグラウンド処理ではありません。
読み込みや生成に失敗した場合は旧シーンを残し、画面を戻して遷移中状態を解除します。
成功した交換・全体完了の通知は送りません。

生成したローダー自身が1件のリクエストとして読み込み結果を保持します。生成したノードや他のResourceが参照する
アセットは、その参照が残っている間は保持されます。
パス指定だけのシーンもエクスポート対象に含めてください。


## 要求の結果

`change_main_scene()` は `ChangeResult` を返します。結果が必要な呼び出し側は
`await` で待ちます。既存の通知シグナルも引き続き利用できます。

```gdscript
var result := await scene_controller.change_main_scene(scene_id, transition_id)
if result == SceneController.ChangeResult.LOAD_FAILED:
	# 必要に応じて失敗を表示する。
	pass
```

| 結果 | 意味 |
|---|---|
| `SUCCESS` | シーン交換、画面を戻す演出、遷移中状態の解除、完了通知が済んだ |
| `BUSY` | 別の切り替えが処理中で、要求を受理しなかった |
| `ALREADY_CURRENT` | 現在のシーンへの要求で、切り替えなかった |
| `INVALID_SCENE` | IDが未登録、エントリーがnull、またはシーン参照が未設定だった |
| `LOAD_FAILED` | 読み込み・型確認・生成に失敗し、画面を戻して遷移中状態を解除した |

要求を受理しない場合は開始通知を送りません。失敗の詳細は既存のエラーログで確認できます。
遷移エフェクトが未登録の場合は、従来どおりログを出し、演出を省略してシーン交換を続けます。
