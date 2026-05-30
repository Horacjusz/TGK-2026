extends Control
class_name UI

var parent_menu = null

func turn_on() :
	Config.load_settings()
	self.show()
	
func turn_off() :
	self.hide()
	Config.save_settings()

func return_to_parent_menu() :
	self.get_parent().get_owner().change_menu(self.parent_menu)
