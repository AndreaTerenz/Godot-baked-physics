class_name PhysBaker
extends Node3D

enum PHYS_BAKER_STATE {
	IDLE,
	BAKING,
	REPLAY
}

signal recording_start
signal recording_stop

# TODO
#	baking length
#	baking timestep
#	autorecord on ready
#	physbake data resource
#	link each tracked RB with a target mesh to move

@onready var debug_ui = $DebugUI
@onready var target := $Target

var target_kids : Array[RigidBody3D] = []
var state := PHYS_BAKER_STATE.IDLE :
	set (s):
		if s == state:
			return
		state = s 

var baking := true :
	set (r):
		if r == baking:
			return
			
		baking = r
		if baking:
			recording_start.emit()
		else:
			recording_stop.emit()
var data := {}
var frames_recorded := 0
var playback_frame := -1

func _ready():
	debug_ui.visible = true
	
	for kid in get_children():
		if kid is RigidBody3D:
			var kp := kid.get_path()
			var kid_pos : Vector3 = kid.position
			var kid_rot : Vector3 = kid.rotation
			
			target_kids.append(kid)
			data[kp] = [[kid_pos, kid_rot]]
			
	print("Found %d RgidBodies out of %d total children" % [len(target_kids), get_child_count()])
	print(data)

func _input(event):
	if event.is_action_released("record_toggle"):
		baking = not baking
		playback_frame = 0

func _physics_process(_delta):
	if baking:
		for kid in target_kids:
			var kp := kid.get_path()
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
	else:
		var source : Array = data[data.keys()[0]]
		if playback_frame >= len(source):
			return
		
		var frame : Array = source[playback_frame]
		
		target.position = frame[0]
		target.rotation = frame[1]
		
		playback_frame += 1

func toggle_targets_freeze(value: bool):
	for kid in target_kids:
		kid.freeze = value
