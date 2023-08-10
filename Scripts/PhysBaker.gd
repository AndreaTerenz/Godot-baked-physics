class_name PhysBaker
extends Node3D

signal recording_start
signal recording_stop

# TODO parameters
#	recording length
#	recording timestep
#	autorecord on ready
#	physbake data resource

@onready var debug_ui = $DebugUI

var target_kids : Array[NodePath] = []
var recording := true :
	set (r):
		if r == recording:
			return
			
		recording = r
		if recording:
			recording_start.emit()
			print("Started recording...")
		else:
			recording_stop.emit()
			print("Stopped recording")
			print(data)
			print("Frames: %d" % [frames_recorded])
var data := {}
var frames_recorded := 0

func _ready():
	debug_ui.visible = true
	
	for kid in get_children():
		if kid is RigidBody3D:
			var kp := kid.get_path()
			var kid_pos : Vector3 = kid.position
			var kid_rot : Vector3 = kid.rotation
			
			target_kids.append(kp)
			data[kp] = [[kid_pos, kid_rot]]
			
	print("Found %d RgidBodies out of %d total children" % [len(target_kids), get_child_count()])
	print(data)

func _input(event):
	if event.is_action_released("record_toggle"):
		recording = not recording

func _physics_process(delta):
	if recording:
		for kp in target_kids:
			var kid : RigidBody3D = (get_node(kp) as RigidBody3D)
			var kid_pos := kid.position
			var kid_rot := kid.rotation
			var to_append = []
			
			if false:
				# TODO
				# Implement some baisc memory saving...
				var last_pos := len(data[kp])-1
				var kid_pos_last : Vector3 = data[kp][last_pos][0]
				var kid_rot_last : Vector3 = data[kp][last_pos][1]
				
				var pos_diff := kid_pos_last.distance_squared_to(kid_pos)
				var rot_diff := kid_rot_last.distance_squared_to(kid_rot)
				
				# (squared distances)
				if pos_diff >= (.001**2) or rot_diff >= (.001**2):
					data[kp].append([kid_pos, kid_rot])
			else:
				data[kp].append([kid_pos, kid_rot])
		
		frames_recorded += 1
