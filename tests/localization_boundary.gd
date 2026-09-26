extends "res://tests/creation_sdk_boundary.gd"
## The external translation service is substituted; authored controls and the
## generated SDK facade are real. Native app QA covers locale/domain selection.
var language := "en"
var english: Translation = load(ROOT + "i18n/en.tres")
var russian: Translation = load(ROOT + "i18n/ru.tres")

func Translate(message: String, _domain: String) -> String:
	var catalog := russian if language.begins_with("ru") else english
	var translated := str(catalog.get_message(message))
	return translated if not translated.is_empty() else message
