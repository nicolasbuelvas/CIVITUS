extends Node

func _ready() -> void:
	var p_seed: int = 700777
	var chemical: String = "h2o"
	
	var args = OS.get_cmdline_user_args()
	for i in range(args.size()):
		var arg = args[i].to_lower()
		if (arg == "--seed" or arg == "-s") and i + 1 < args.size():
			p_seed = int(args[i + 1])
		elif (arg == "--chem" or arg == "-c") and i + 1 < args.size():
			var val = args[i + 1].to_lower()
			if val in ["magma", "lava", "volcan", "fuego"]:
				chemical = "magma"
			elif val in ["acido", "acid", "sulfur", "sulfurico"]:
				chemical = "sulfuric_acid"
			elif val in ["metano", "methane", "cryo", "hielo"]:
				chemical = "methane"
			elif val in ["hycean", "hiceanico", "amoniaco", "ammonia"]:
				chemical = "hycean"
			elif val in ["random", "aleatorio"]:
				chemical = ""
			else:
				chemical = "h2o"

	# Generate realistic 100% oceanic world matching the specified chemistry
	var p = SolarSystem.generate_oceanic_world(chemical, p_seed)
	GameManager.select_planet(p)
	
	# Launch full normal mode survival gameplay expedition deferred so scene tree is ready
	GameManager.call_deferred("start_expedition")
