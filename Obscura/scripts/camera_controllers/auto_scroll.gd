class_name AutoScrollCamera
extends CameraControllerBase

@export var top_left: Vector2
@export var bottom_right: Vector2
@export var autoscroll_speed: Vector3

func _ready() -> void:
	super()
	draw_camera_logic = true

func _process(delta: float) -> void:
	if !current:
		return
		
	# Auto-scroll the camera
	position.x += autoscroll_speed.x * delta
	position.z += autoscroll_speed.z * delta
	
	if target:
		
		# Calculate box boundaries in world space
		var box_left = position.x + top_left.x
		var box_right = position.x + bottom_right.x
		var box_top = position.z + top_left.y
		var box_bottom = position.z + bottom_right.y
		
		# Constrain player within box bounds
		if target.position.x < box_left:
			target.position.x = box_left
		elif target.position.x > box_right:
			target.position.x = box_right
			
		if target.position.z < box_top:
			target.position.z = box_top
		elif target.position.z > box_bottom:
			target.position.z = box_bottom
			
	else:
		return
		
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
	
	# Draw the box border
	var corners = [
		Vector3(top_left.x, 0, top_left.y),        # Top left
		Vector3(bottom_right.x, 0, top_left.y),    # Top right
		Vector3(bottom_right.x, 0, bottom_right.y), # Bottom right
		Vector3(top_left.x, 0, bottom_right.y)     # Bottom left
	]
	
	
	# Connect corners to form box
	for i in range(4):
		var next_i = (i + 1) % 4
		immediate_mesh.surface_add_vertex(corners[i])
		immediate_mesh.surface_add_vertex(corners[next_i])
	
	immediate_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	await get_tree().process_frame
	mesh_instance.queue_free()
