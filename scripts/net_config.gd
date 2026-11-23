extends RefCounted
## Shared network defaults for slice 0.

const DEFAULT_PORT := 7777
const DEFAULT_HOST := "127.0.0.1"
const MAX_CLIENTS := 8

## Parse CLI after `--`. Returns a Dictionary with keys:
## mode ("server"|"client"), host, port, display_name
static func from_cmdline() -> Dictionary:
	var args := OS.get_cmdline_user_args()
	var cfg := {
		"mode": "client",
		"host": DEFAULT_HOST,
		"port": DEFAULT_PORT,
		"display_name": "",
		"bot": false,
	}
	var i := 0
	while i < args.size():
		var a: String = args[i]
		match a:
			"--server":
				cfg.mode = "server"
			"--client":
				cfg.mode = "client"
			"--bot":
				cfg.bot = true
			"--host":
				i += 1
				if i < args.size():
					cfg.host = args[i]
			"--port":
				i += 1
				if i < args.size():
					cfg.port = int(args[i])
			"--name":
				i += 1
				if i < args.size():
					cfg.display_name = args[i]
			_:
				if a.begins_with("--host="):
					cfg.host = a.get_slice("=", 1)
				elif a.begins_with("--port="):
					cfg.port = int(a.get_slice("=", 1))
				elif a.begins_with("--name="):
					cfg.display_name = a.get_slice("=", 1)
		i += 1
	return cfg
