extends CharacterBody3D

@onready var camera = $Camera3D
var tree_scene = preload("res://scenes/tree.tscn")

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	$Slicer.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta: float) -> void:
	
	if !is_multiplayer_authority():
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("f"):
		if get_parent().get_node("Environment").get_node("Tree").in_range:
			slice()

func slice():
	var mesh_slicer = MeshSlicer.new()
	var cross_section_mat = load("res://objects/CrossSection.tres")
	
	var Transform = $Slicer.global_transform
	var tree = get_parent().get_node("Environment").get_node("Tree")
	var tree_mesh = tree.get_node("MeshInstance3D")
	
	add_child(mesh_slicer)
	
	Transform.origin = tree.to_local(Transform.origin)
	Transform.basis.x = tree.to_local(Transform.basis.x + tree.global_position)
	Transform.basis.y = tree.to_local(Transform.basis.y + tree.global_position)
	Transform.basis.z = tree.to_local(Transform.basis.z + tree.global_position)
	
	var meshes = mesh_slicer.slice_mesh(Transform, tree_mesh.mesh, cross_section_mat)
	
	tree_mesh.mesh = meshes[0]
	
	var trunk_mesh = tree_mesh.mesh
	var trunk_collision_shape = trunk_mesh.create_convex_shape()
	var trunk_col_node = tree.get_node("CollisionShape3D")
	trunk_col_node.shape = trunk_collision_shape
	trunk_col_node.position = Vector3.ZERO 
	trunk_col_node.rotation = Vector3.ZERO
	
	var log = tree_scene.instantiate()
	
	get_parent().add_child(log)
	
	log.global_position = tree.global_position
	
	log.get_node("MeshInstance3D").mesh = meshes[1]
	var log_mesh = log.get_node("MeshInstance3D").mesh
	var log_collision_shape = log_mesh.create_convex_shape()
	var log_col_node = log.get_node("CollisionShape3D")
	log_col_node.shape = log_collision_shape
	log_col_node.position = Vector3.ZERO 
	log_col_node.rotation = Vector3.ZERO
