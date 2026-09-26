extends Resource
class_name SceneData

@export var _scene: PackedScene
var scene: PackedScene:
    get:
        return _scene

@export var _scene_type: SceneEnums.Type
var scene_type: SceneEnums.Type:
    get:
        return _scene_type
