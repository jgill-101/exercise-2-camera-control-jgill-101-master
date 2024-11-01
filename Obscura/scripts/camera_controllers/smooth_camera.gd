class_name LeadCameraController
extends CameraControllerBase

@export var lead_speed: float = 15.0
@export var catchup_delay_duration: float = 0.5
@export var catchup_speed: float = 25.0
@export var leash_distance: float = 10.0

var last_target_pos: Vector3
var time_since_movement: float = 0.0
var current_mesh_instance: MeshInstance3D = null

func _ready() -> void:
	super()
	draw_camera_logic = true
	if target:
		last_target_pos = target.position


func _process(delta: float) -> void:
	if !current or !target:
		return
		
	
	# Clean up previous visualization
	if current_mesh_instance:
		current_mesh_instance.queue_free()
		current_mesh_instance = null
	
	# Calculate target's movement direction
	var movement = target.position - last_target_pos
	var is_moving = movement.length() > 0.001
	

	
	if is_moving:
		# Reset timer when target moves
		time_since_movement = 0.0
		
		# Move camera ahead in movement direction
		var movement_dir = movement.normalized()
		var desired_pos = target.position + (movement_dir * lead_speed)
		position = position.lerp(desired_pos, delta * lead_speed)
	else:
		# When target stops, wait for delay then move back
		time_since_movement += delta
		if time_since_movement >= catchup_delay_duration:
			position = position.lerp(target.position, delta * catchup_speed)
	
	# Enforce leash distance
	var dist_to_target = position.distance_to(target.position)
	if dist_to_target > leash_distance:
		var dir_to_target = (target.position - position).normalized()
		position = target.position - (dir_to_target * leash_distance)
	
	# Update last position
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
	current_mesh_instance = mesh_instance
	
	await get_tree().process_frame
	mesh_instance.queue_free()
