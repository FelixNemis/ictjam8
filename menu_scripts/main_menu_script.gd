extends Node

var r_menu

func set_menu(menu):
	r_menu = menu

# close menu if return true
func handle_item_selected(value, extra) -> bool:
	match value:
		'return':
			return true
		'ignore':
			pass
		'get-job':
			if extra == -1:
				var max_job = get_node("/root/JobManager").get_next_job()
				if max_job == 1:
					get_node("/root/WorldControl").load_job(1)
					show_popup_on_unpause()
					return true
				else:
					#r_menu.add_child_numbers_prompt('get-job', 'Choose a job:', max_job, 1, max_job)
					r_menu.add_child_job_menu("Act 1", ["jobs"])
			else:
				get_node("/root/WorldControl").load_job(extra)
				show_popup_on_unpause()
				return true
		'restart-game':
			if extra == -1:
				r_menu.add_child_confirm_prompt('restart-game', 'Are you sure you want to reset?')
			else:
				if extra == 1:
					get_tree().reload_current_scene()
		'eval-job':
			if extra == 1:
				return true
			var job_passed = get_node("/root/WorldControl").is_job_completed()
			if job_passed:
				r_menu.add_child_confirm_prompt('finish-job', 'Great! That\'s perfect! Are you done here?')
			else:
				r_menu.add_text_popup("Hm, that's not quite right", 'eval-job', 1, true)
		'finish-job':
			if extra == 1:
				get_node("/root/WorldControl").leave_job(true)
				return true
			else:
				return true
		'leave-job':
			if extra == -1:
				r_menu.add_child_confirm_prompt('leave-job', 'Are you sure you leave?\n')
			else:
				if extra == 1:
					get_node("/root/WorldControl").leave_job(false)
					return true
		'view-job':
			show_popup_on_unpause()
			return true
		'save-game':
			if typeof(extra) == TYPE_INT and extra == -1:
				#var max_save = 6
				#r_menu.add_child_numbers_prompt('save-game', 'Choose a save:', 1, 1, max_save)
				if get_node("/root/GlobalData").has_saved():
					r_menu.add_child_file_menu('save-game', [get_node("/root/GlobalData").get_current_save_filename()], true)
				else:
					r_menu.add_child_file_menu('save-game', [], true)
			elif typeof(extra) == TYPE_STRING:
				var global = get_node("/root/GlobalData")
				var screenshotter = get_node("/root/Screenshotter")
				var scrn_name = screenshotter.get_screenshot_name(global.save_name) + '.png'
				r_menu.deactivate_menu()
				
				var pause_screen = get_node("/root/UI").get_pause_screen()
				pause_screen.queue_screenshot(scrn_name)
				#print('yielding for screenshot')
				yield(pause_screen, "took_screenshot")
				#print('done yielding for screenshot')
				
				r_menu.activate_menu()
				
				var saver = get_node("/root/SaveManager")
				if extra == '__new_file__':
					extra = saver.get_new_save_name(global.save_name)
					extra = saver.save_name_to_filename(extra)
				
				get_node("/root/GlobalData").set_current_save_filename(extra)
				saver.save_game(extra, scrn_name)
				return false
		'load-game':
			if typeof(extra) == TYPE_INT and extra == -1:
				r_menu.add_child_file_menu('load-game')
			elif typeof(extra) == TYPE_STRING:
				#print('want to load: ' + extra)
				get_node("/root/GlobalData").set_current_save_filename(extra)
				get_node("/root/SaveManager").load_game(extra)
				return true
		'set-name':
			if typeof(extra) == TYPE_INT and extra == -1:
				r_menu.add_child_text_prompt('set-name', 'What is your name???', get_node("/root/GlobalData").save_name)
			elif typeof(extra) == TYPE_STRING:
				print('setting name: ' + extra)
				get_node("/root/GlobalData").save_name = extra
		
		'help-menu':
			r_menu.add_child_list_menu('help_menu_script.gd')

		'options-menu':
			r_menu.add_child_list_menu('options_menu_script.gd')
		
		'save-load-menu':
			var options = get_file_menu_options()
			r_menu.add_child_list_menu('', options)
	
	# dont close menu
	return false

func can_load() -> bool:
	return len(get_node("/root/SaveManager").get_all_saves()) > 0

func get_file_menu_options() -> Array:
	var options = []
	options.append(make_menu_option("ignore", "Back"))
	options.append(make_menu_option("save-game", "Save"))
	if can_load():
		options.append(make_menu_option("load-game", "Load"))
	options.append(make_menu_option("restart-game", "New Game"))
	return options

func show_popup_on_unpause():
	var ui = get_node("/root/UI")
	ui.get_pause_screen().connect("unpaused", ui, "show_popup_goal", [], CONNECT_ONESHOT)
	
	
func make_menu_option(value, text : String) -> Dictionary:
	return {'value': value, 'text': text}
