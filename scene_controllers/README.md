# シーン切り替え

このディレクトリは、専用ルート配下のシーン交換と画面遷移を管理します。
ゲーム固有のIDは `scenes/scene_ids.gd` と `scenes/transition_ids.gd`、
登録内容は `scenes/settings/` に置き、`scenes/core.tscn` で設定します。

## 設定

- `SceneRegistry` は `StringName` のIDと `SceneEntry` を対応付けます。
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
