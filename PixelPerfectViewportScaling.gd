extends Node2D

# Set the bounds of your reference resolution
var min_x = 180
var max_x = 216
var min_y = 355
var max_y = 450

# This preferred y value is only used to catch any odd bugs
var preffered_y = 400

var mem_window : Vector2i
var ref_res : Vector2i

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().size = get_window().size * 2
	mem_window = get_window().size
	ameliorate_resolution()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# get_window().size_changed.connect(ameliorate_resolution) appears to break
	# after a few calls. So I have just been continously checking the window size
	if (get_window().size != mem_window):
		mem_window = get_window().size 
		ameliorate_resolution()

func ameliorate_resolution():
	# Current window resolution, need it to identify viewport scalability / aspect ratio
	var curr_res : Vector2i = DisplayServer.window_get_size()
	
	# Creates the maximum scale limits, as floats, given the minimum and maximum 
	# supported reference resolutions. I did not do this math through a direct 
	# aspect ratio calculation, but you could do this yourself
	var y_scale_max : float = max(float(curr_res.y) / float(min_y) , 1)
	var y_scale_min : float = max(float(curr_res.y) / float(max_y) , 1)
	var x_scale_max : float = max(float(curr_res.x) / float(min_x) , 1)
	var x_scale_min : float = max(float(curr_res.x) / float(max_x) , 1)
	
	# Use the scaling limits in each dimension to identify the largest common
	# interger. If one exists, it becomes our pixel perfect scale factor
	var scale : int = largest_common_int(x_scale_min, x_scale_max, y_scale_min, y_scale_max)
	
	# If a common interger does not exist in scale ranges of the two dimensions,
	# then the above function returns -1
	if (scale > 0):
		# we are pixel perfect: the current window resolution can be divided 
		# by an integer to land within a supported reference resolution.
		# scaling the viewport is now very simple, though there is sometimes 
		# an issue with .5 pixels left over.
		ref_res = curr_res / scale
		
		# set the viewport parameters for pixel perfect integer scaling
		get_window().content_scale_size = ref_res
		get_window().content_scale_mode = 0 # disabled scaling
		get_window().content_scale_aspect = 1 # keep aspect ratio
		get_window().content_scale_stretch = 1 # integer scaling mode
		get_window().content_scale_factor = scale # scale by the interger scale
	else:
		# we are NOT pixel perfect due to an unsupported aspect ratio or size
		# so we must resize the screen fractionally ='(
		var scalef : float = largest_common_float(x_scale_min, x_scale_max, y_scale_min, y_scale_max)
		
		# using the largest_common_float function lets us maintain an appropriate
		# aspect ratio even when scaling fractionally, though you may want to redo
		# this calculation to be based off the resolution aspect ratio instead 
		# for a better fit
		match scalef:
			-1.0:
				# Screen is too tall, max out the y, min the x
				ref_res.y = max_y
				ref_res.x = min_x
			-2.0:
				# Screen is too wide, use min y, max out the x
				ref_res.y = min_y
				ref_res.x = max_x
			0.0:
				# Catch for bugs / weird edge cases, just uses default values
				ref_res.y = preffered_y
				ref_res.x = min_x
			_:
				# scale the current resolution by the largest common scale float
				ref_res = curr_res / scalef
		
		# Some of the above conditions may provide an x or y value outside of the supported ranges
		ref_res.y = clamp(ref_res.y, min_y, max_y)
		ref_res.x = clamp(ref_res.x, min_x, max_x)
		
		# set the viewport parameters for fractional scaling
		get_window().content_scale_size = ref_res
		get_window().content_scale_mode = 2 # viewport scaling
		get_window().content_scale_aspect = 1 # keep aspect ratio
		get_window().content_scale_stretch = 0 # fractional scaling mode
		get_window().content_scale_factor = 1 # base scale value
	
	# you can add code here to reposition gameplay elements if you so choose


func largest_common_int(xmin, xmax, ymin, ymax) -> int:
	# returns -1 if no meaningful overlap exists between the x range and y range
	var LCI : int = -1
	
	if ((ceil(xmin)>xmax) || (ceil(ymin)>ymax)):
		return LCI
	
	# Can't use ciel(xmax) instead of floor(xmax) + 1 because that fails when 
	# xmax is exactly 1. The range function is non-inclusive for the upper bound
	var x_range = range(ceil(xmin), floor(xmax) + 1)
	var y_range = range(ceil(ymin), floor(ymax) + 1)
	
	for i in x_range:
		if (y_range.has(i)):
			LCI = i
		
	return LCI

func largest_common_float(xmin, xmax, ymin, ymax) -> float:
	# returns 0 for weird edge cases
	# returns -1 if screen is too tall
	# returns -2 if screen is too wide
	# otherwise returns the largest common float
	
	var LCF : float = 0.0
	
	if (xmax < ymin):
		LCF = -1.0
	elif (ymax < xmin):
		LCF = -2.0
	elif ((xmax <= ymax) && (xmax >= ymin)):
		LCF = xmax
	elif ((ymax <= xmax) && (ymax >= xmin)):
		LCF = ymax
		
	return LCF
