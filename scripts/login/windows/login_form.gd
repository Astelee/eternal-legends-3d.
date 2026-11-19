class_name LoginForm
extends PixelPanel
# Painel principal de login (flutuante, à direita da tela).

signal login_succeeded(response: Dictionary)
signal register_requested
signal recovery_requested

var auth: AuthService

var _user: PixelField
var _pass: PixelField
var _remember: PixelCheck
var _message: FormMessage
var _submit_btn: PixelButton
var _busy: bool = false


func _init(p_auth: AuthService) -> void:
	super()
	auth = p_auth

	var title := LoginTheme.label("BEM-VINDO, AVENTUREIRO", 22, LoginTheme.GOLD_LIGHT)
	title.add_theme_font_override("font", LoginTheme.title_font())
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title)
	content.add_child(LoginTheme.divider())

	_user = PixelField.new("Usuário ou e-mail", "Seu nome de herói ou e-mail", "user", false, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	_user.edit.max_length = 80
	content.add_child(_user)

	_pass = PixelField.new("Senha", "Sua senha secreta", "lock", true)
	_pass.edit.max_length = 128
	content.add_child(_pass)

	var options := HBoxContainer.new()
	content.add_child(options)
	_remember = PixelCheck.new("Lembrar-me")
	_remember.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_child(_remember)
	var forgot := LoginTheme.link("Esqueceu sua senha?", 17)
	forgot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	forgot.pressed.connect(func() -> void: recovery_requested.emit())
	options.add_child(forgot)

	_message = FormMessage.new()
	content.add_child(_message)

	_submit_btn = PixelButton.new("ENTRAR", PixelButton.Kind.GOLD)
	_submit_btn.custom_minimum_size = Vector2(0, 58)
	_submit_btn.add_theme_font_size_override("font_size", 26)
	_submit_btn.pressed.connect(_submit)
	content.add_child(_submit_btn)

	var signup := HBoxContainer.new()
	signup.alignment = BoxContainer.ALIGNMENT_CENTER
	signup.add_theme_constant_override("separation", 8)
	content.add_child(signup)
	signup.add_child(LoginTheme.label("Não possui uma conta?", 17, LoginTheme.PARCHMENT_DIM))
	var reg := LoginTheme.link("Cadastre-se", 17)
	reg.pressed.connect(func() -> void: register_requested.emit())
	signup.add_child(reg)

	_user.submitted.connect(func() -> void:
		if _pass.get_value() == "":
			_pass.focus_edit()
		else:
			_submit())
	_pass.submitted.connect(_submit)

	var saved: String = LoginPrefs.remembered_identifier()
	if saved != "":
		_user.set_value(saved)
		_remember.checked = true


# Elementos que aparecem em sequência na animação de abertura.
func stagger_items() -> Array:
	return content.get_children()


func focus_first_empty() -> void:
	if _user.get_value() == "":
		_user.focus_edit()
	else:
		_pass.focus_edit()


func set_interactive(on: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE


func _submit() -> void:
	if _busy:
		return
	_message.clear_message()
	var e_user: String = Validators.login_identifier(_user.get_value())
	var e_pass: String = Validators.login_password(_pass.get_value())
	if e_user != "":
		_user.set_error(e_user)
	if e_pass != "":
		_pass.set_error(e_pass)
	if e_user != "" or e_pass != "":
		(_user if e_user != "" else _pass).focus_edit()
		return

	_set_busy(true)
	var identifier: String = _user.get_value().strip_edges()
	var res: Dictionary = await auth.login(identifier, _pass.get_value(), _remember.checked)
	_set_busy(false)

	if bool(res["ok"]):
		var data: Dictionary = res["data"]
		Session.start(data, identifier)
		if not Session.is_active():
			_message.show_error("O servidor respondeu sem uma sessão válida. Tente novamente.")
			return
		if _remember.checked:
			LoginPrefs.set_remembered_identifier(identifier)
		else:
			LoginPrefs.clear_remembered_identifier()
		_pass.set_value("")
		login_succeeded.emit(data)
		return
	_show_failure(res)


func _show_failure(res: Dictionary) -> void:
	var errors: Dictionary = res["errors"]
	var handled: bool = false
	if errors.has("identifier"):
		_user.set_error(str(errors["identifier"]))
		handled = true
	if errors.has("password"):
		_pass.set_error(str(errors["password"]))
		handled = true
	if not handled or str(res["message"]) != "":
		_message.show_error(str(res["message"]))
	Audio.play_sfx("hurt", 0.03)


func _set_busy(on: bool) -> void:
	_busy = on
	_submit_btn.set_loading(on, "ENTRANDO...")
	_user.set_enabled(not on)
	_pass.set_enabled(not on)