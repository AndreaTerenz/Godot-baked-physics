class_name PhysBaker
extends Node3D

enum PHYS_BAKER_STATE {
	IDLE,
	BAKING,
	REPLAY
}

signal state_changed(s: PHYS_BAKER_STATE)

@export var bake_on_ready := false
@export_range(0, 8192) var max_frames : int = 2048

# TODO
#	baking length
#	baking timestep
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
			PHYS_BAKER_STATE.IDLE:
				if state == PHYS_BAKER_STATE.BAKING:
					print("Baking stopped (frames: %d)" % frames_recorded)
			PHYS_BAKER_STATE.REPLAY:
				playback_frame = 0
			PHYS_BAKER_STATE.BAKING:
				playback_frame = -1
		
		state = s 
		state_changed.emit(s)
var currently_idle : bool :
	get:
		return state == PHYS_BAKER_STATE.IDLE
var has_frames_left : int :
	get:
		return max_frames == 0 or frames_recorded < max_frames

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
	
	if bake_on_ready:
		state = PHYS_BAKER_STATE.BAKING
 
func _input(event):
	var new_state = null
	if event.is_action_pressed("start_stop_bake"):
		new_state = PHYS_BAKER_STATE.BAKING
	if event.is_action_pressed("replay"):
		new_state = PHYS_BAKER_STATE.REPLAY
		
	if new_state == null:
		return
		
	state = new_state if state != new_state else PHYS_BAKER_STATE.IDLE

func _physics_process(_delta):
	if state == PHYS_BAKER_STATE.IDLE:
		return
		
	if state == PHYS_BAKER_STATE.BAKING:
		for kid in target_kids:
			var kp := kid.get_path()
			var kid_pos := kid.position
			var kid_rot := kid.rotation
			var to_append = []
			
			data[kp].append([kid_pos, kid_rot])
		
		frames_recorded += 1
		if not has_frames_left:
			state = PHYS_BAKER_STATE.IDLE
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
