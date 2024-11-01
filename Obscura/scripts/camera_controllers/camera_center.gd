class_name CenteredCameraController
extends CameraControllerBase

func _ready() -> void:
	super()
	draw_camera_logic = true
	current = true
	# Set rotation for top-down view (rotate 90 degrees around X axis)
	#rotation_degrees.x = -90

func _process(delta: float) -> void:
	if !current:
		return
	
	# Keep perfectly centered on vessel
	if target:
		position.x = target.position.x
		position.z = target.position.z
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
	
	var size := 2.5  # 5 units total (2.5 in each direction)
	
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
	
	# Draw at vessel height
	if target:
		mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	# Clean up after one frame
	await get_tree().process_frame
	mesh_instance.queue_free()
