# シーン切り替え

このディレクトリは、専用ルート配下のシーン交換と画面遷移を管理します。
読み込みには `resource_loading/async_resource_loader.gd` を利用します。
ゲーム固有のIDは `scenes/scene_ids.gd` と `scenes/transition_ids.gd`、
登録内容は `scenes/settings/` に置き、`scenes/core.tscn` で設定します。

## 設定

- `SceneRegistry` は `StringName` のIDと `SceneEntry` を対応付けます。
  `SceneEntry.scene_path` にシーンのパスを設定します。登録だけではシーンを読み込みません。
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

ローダーはRefCountedとして `_ready()` で生成し、`get_tree().process_frame` を渡します。
子ノードの配置やローダーのNodePath設定は不要です。

画面を覆った後、汎用ローダーの `load_resource(path, "PackedScene")` をawaitします。
SceneControllerが渡す `process_frame` シグナルで完了状態を確認し、読み込んだResourceを取得してからメインスレッドで
シーンを生成・追加します。生成や `_ready()` 自体はバックグラウンド処理ではありません。
読み込みや生成に失敗した場合は旧シーンを残し、画面を戻して遷移中状態を解除します。
成功した交換・全体完了の通知は送りません。

ローダーは読み込み結果を保持しません。生成したノードや他のResourceが参照する
アセットは、その参照が残っている間は保持されます。
パス指定だけのシーンもエクスポート対象に含めてください。
