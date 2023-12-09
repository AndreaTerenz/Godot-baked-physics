class_name PhysBaker
extends Node3D

enum PHYS_BAKER_STATE {
	IDLE,
	BAKING,
	REPLAY
}

signal state_changed(s: PHYS_BAKER_STATE)


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

		toggle_targets_freeze(s != PHYS_BAKER_STATE.BAKING)
		
		match s:
			PHYS_BAKER_STATE.REPLAY:
				playback_frame = 0
			PHYS_BAKER_STATE.BAKING:
				playback_frame = -1
		
		state = s 
		state_changed.emit(s)

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
	
	toggle_targets_freeze(true)
func _input(event):
	if event.is_action_released("record_toggle"):
		if state == PHYS_BAKER_STATE.IDLE:
			state = PHYS_BAKER_STATE.BAKING
		elif state == PHYS_BAKER_STATE.BAKING:
			state = PHYS_BAKER_STATE.REPLAY

func _physics_process(_delta):
	if state == PHYS_BAKER_STATE.IDLE:
		return
		
	if state == PHYS_BAKER_STATE.BAKING:
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
		if playback_frame >= frames_recorded:
			playback_frame = 0
		
		var source : Array = data[data.keys()[0]]
		var frame : Array = source[playback_frame]
		
		target.position = frame[0]
		target.rotation = frame[1]
		
		playback_frame += 1

func toggle_targets_freeze(value: bool):
	for kid in target_kids:
		kid.freeze = value
