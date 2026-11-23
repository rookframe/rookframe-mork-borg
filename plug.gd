extends "res://addons/gd-plug/plug.gd"
var ui_kit = preload("res://.rookframe/rookframe_ui_kit.gd").new()

func _initialize() -> void:
    if ui_kit.dependency.is_empty():
        quit(1)
        return
    super._initialize()

func request_quit(exit_code := -1) -> bool:
    if not threadpool.is_all_thread_finished() or not threadpool.is_all_task_finished():
        return false
    var result := 0 if exit_code == -1 else exit_code
    var args := OS.get_cmdline_args()
    if result == 0 and ("install" in args or "update" in args):
        result = ui_kit.write_provenance()
    return super.request_quit(result)

func install_plugin(plugin):
    if plugin.name == "rookframe-ui-kit":
        ui_kit.install(self, plugin)
    else:
        super.install_plugin(plugin)

func update_plugin(plugin, checking=false):
    if plugin.name == "rookframe-ui-kit":
        if not checking:
            ui_kit.install(self, plugin)
        return false
    return super.update_plugin(plugin, checking)

func _plugging() -> void:
    plug("godot-gdunit-labs/gdUnit4", {"commit": "08ffc7c65b61b1b2edd545616061a99973c13ce1", "include": ["addons/gdUnit4"]})
    plug("rookframe/rookframe-sdk", {"commit": "05353d2565054406f5616df75cef1b6326ae49ee", "include": ["rookframe/sdk"]})
    plug("rookframe/rookframe-development-plugin", {"commit": "594c44483075bef8dcfaec5a5dc5d71ac25e67ef", "include": ["addons/rookframe_development"]})
    plug("rookframe/rookframe-ui-kit", {"commit": "17ab08839bb6369b89cdade64cfdd3d37b06f633", "include": ["rookframe/ui"]})
