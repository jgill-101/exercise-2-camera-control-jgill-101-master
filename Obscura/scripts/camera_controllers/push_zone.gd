class_name PushZoneCamera
extends CameraControllerBase

@export var push_ratio: float = 1.5
@export var pushbox_top_left: Vector2
@export var pushbox_bottom_right: Vector2
@export var speedup_zone_top_left: Vector2
@export var speedup_zone_bottom_right: Vector2

var last_target_pos: Vector3

func _ready() -> void:
	super()
	draw_camera_logic = true
	if target:
		last_target_pos = target.position
	print("PushZoneCamera ready")

func _process(delta: float) -> void:
	if !current or !target:
		return

	print("\n--- Frame Update ---")
	
	# Calculate target's movement
	var movement = target.position - last_target_pos
	var is_moving = movement.length() > 0.001
	
	# Get target's position relative to camera
	var rel_pos = Vector2(
		target.position.x - position.x,
		target.position.z - position.z
	)
	print("Relative position:", rel_pos)
	
	if is_moving:
		# Check if player is outside inner box but inside outer box
		var outside_inner_box = (
			rel_pos.x < speedup_zone_top_left.x or 
			rel_pos.x > speedup_zone_bottom_right.x or
			rel_pos.y < speedup_zone_top_left.y or 
			rel_pos.y > speedup_zone_bottom_right.y
		)
		
		if outside_inner_box:
			# Move camera smoothly like in stage 3/4
			var desired_pos = target.position
			position = position.lerp(desired_pos, push_ratio * delta)
			print("Moving camera, outside inner box")
	
	# Enforce outer box boundaries
	var new_pos = position
	
	if target.position.x < position.x + pushbox_top_left.x:
		new_pos.x = target.position.x - pushbox_top_left.x
	elif target.position.x > position.x + pushbox_bottom_right.x:
		new_pos.x = target.position.x - pushbox_bottom_right.x
		
	if target.position.z < position.z + pushbox_top_left.y:
		new_pos.z = target.position.z - pushbox_top_left.y
	elif target.position.z > position.z + pushbox_bottom_right.y:
		new_pos.z = target.position.z - pushbox_bottom_right.y
	
	position = new_pos
	
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
	
	# Draw outer pushbox
	draw_box(immediate_mesh, pushbox_top_left, pushbox_bottom_right)
	
	# Draw inner speedup zone
	draw_box(immediate_mesh, speedup_zone_top_left, speedup_zone_bottom_right)
	
	immediate_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	await get_tree().process_frame
	mesh_instance.queue_free()

func draw_box(immediate_mesh: ImmediateMesh, top_left: Vector2, bottom_right: Vector2) -> void:
	var corners = [
		Vector3(top_left.x, 0, top_left.y),
		Vector3(bottom_right.x, 0, top_left.y),
		Vector3(bottom_right.x, 0, bottom_right.y),
		Vector3(top_left.x, 0, bottom_right.y)
	]
	
	for i in range(4):
		var next_i = (i + 1) % 4
		immediate_mesh.surface_add_vertex(corners[i])
		immediate_mesh.surface_add_vertex(corners[next_i])
