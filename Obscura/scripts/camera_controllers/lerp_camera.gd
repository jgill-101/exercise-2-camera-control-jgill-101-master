class_name LerpCameraController
extends CameraControllerBase

@export var follow_speed: float = 5.0
@export var catchup_speed: float = 20.0
@export var leash_distance: float = 9.0

var last_target_pos: Vector3

func _ready() -> void:
	super()
	draw_camera_logic = true
	
	if target:
		last_target_pos = target.position
		position = target.position
	else:
		print("WARNING: No target set in _ready!")

func _process(delta: float) -> void:
	
	if !current:
		return
		
	if !target:
		return
		
	
	var target_moved = target.position != last_target_pos
	var current_speed = follow_speed if target_moved else catchup_speed
	
	# Calculate desired position (where we want to be)
	var desired_pos = target.position
	var current_distance = position.distance_to(desired_pos)
	
	# If we're beyond leash distance, force a faster catch-up
	if current_distance > leash_distance:
		var dir_to_target = (desired_pos - position).normalized()
		position = desired_pos - (dir_to_target * leash_distance)
	else:
		# Normal smooth follow
		var new_pos = position.lerp(desired_pos, current_speed * delta)
		position.x = new_pos.x
		position.z = new_pos.z
	
	# Update last known position for next frame
	last_target_pos = target.position
	
	if draw_camera_logic:
		draw_logic()
		
	super(delta)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Draw a 5x5 cross
	var size := 2.5  # 5 units total
	
	# Horizontal line
	immediate_mesh.surface_add_vertex(Vector3(-size, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(size, 0, 0))
	
	# Vertical line
	immediate_mesh.surface_add_vertex(Vector3(0, 0, -size))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, size))
	
	immediate_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	await get_tree().process_frame
	mesh_instance.queue_free()
