extends ContainerScope

@export var scene_controller: SceneController

func _register_instance(container: InjectionContainer) -> void:
	container.register(ServiceRegistration.create_instance_registration(scene_controller))
