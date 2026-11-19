class_name RegisterWindow
extends ModalWindow
# Janela de cadastro. A escolha de classe NÃO acontece aqui: ela vem depois
# de entrar na conta, dentro do jogo.

signal legal_requested(kind: String)
signal enter_game_requested(response: Dictionary)

var auth: AuthService

var _username: PixelField
var _email: PixelField
var _password: PixelField
var _confirm: PixelField
var _terms: PixelCheck
var _privacy: PixelCheck
var _message: FormMessage
var _create_btn: PixelButton
var _enter_btn: PixelButton
var _back_btn: PixelButton
var _form_box: VBoxContainer
var _success_box: VBoxContainer
var _success_title: Label
var _success_text: Label
var _success_icon: TextureRect
var _response: Dictionary = {}
var _busy: bool = false


func _init(p_auth: AuthService) -> void:
	super("CRIAR CONTA", 520.0)
	auth = p_auth

	_form_box = VBoxContainer.new()
	_form_box.add_theme_constant_override("separation", 12)
	body.add_child(_form_box)

	_username = PixelField.new("Nome de usuário", "3 a 16 letras, números ou _", "user")
	_username.edit.max_length = 16
	_form_box.add_child(_username)

	_email = PixelField.new("E-mail", "nome@exemplo.com", "mail", false, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	_email.edit.max_length = 120
	_form_box.add_child(_email)

	_password = PixelField.new("Senha", "Mín. 8 caracteres, com letras e números", "lock", true)
	_password.edit.max_length = 128
	_form_box.add_child(_password)

	_confirm = PixelField.new("Confirmar senha", "Repita a senha", "lock", true)
	_confirm.edit.max_length = 128
	_form_box.add_child(_confirm)

	_terms = PixelCheck.new("Li e aceito os [color=#7cc0ff][url=terms]Termos de Serviço[/url][/color]")
	_terms.link_clicked.connect(func(id: String) -> void: legal_requested.emit(id))
	_form_box.add_child(_terms)

	_privacy = PixelCheck.new("Li e aceito a [color=#7cc0ff][url=privacy]Política de Privacidade[/url][/color]")
	_privacy.link_clicked.connect(func(id: String) -> void: legal_requested.emit(id))
	_form_box.add_child(_privacy)

	_message = FormMessage.new()
	_form_box.add_child(_message)

	var have := HBoxContainer.new()
	have.alignment = BoxContainer.ALIGNMENT_CENTER
	have.add_theme_constant_override("separation", 8)
	_form_box.add_child(have)
	have.add_child(LoginTheme.label("Já tem uma conta?", 17, LoginTheme.PARCHMENT_DIM))
	var back_link := LoginTheme.link("Voltar ao login", 17)
	back_link.pressed.connect(close)
	have.add_child(back_link)

	_build_success_view()

	_create_btn = PixelButton.new("CRIAR CONTA", PixelButton.Kind.GOLD)
	_create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_create_btn.custom_minimum_size = Vector2(0, 56)
	_create_btn.pressed.connect(_submit)
	footer.add_child(_create_btn)

	_enter_btn = PixelButton.new("ENTRAR NO REINO", PixelButton.Kind.GOLD)
	_enter_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enter_btn.custom_minimum_size = Vector2(0, 56)
	_enter_btn.visible = false
	_enter_btn.pressed.connect(func() -> void: enter_game_requested.emit(_response))
	footer.add_child(_enter_btn)

	_back_btn = PixelButton.new("VOLTAR AO LOGIN", PixelButton.Kind.GOLD)
	_back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back_btn.custom_minimum_size = Vector2(0, 56)
	_back_btn.visible = false
	_back_btn.pressed.connect(close)
	footer.add_child(_back_btn)

	_username.submitted.connect(_email.focus_edit)
	_email.submitted.connect(_password.focus_edit)
	_password.submitted.connect(_confirm.focus_edit)
	_confirm.submitted.connect(_submit)


func on_opened() -> void:
	_username.focus_edit()


func _build_success_view() -> void:
	_success_box = VBoxContainer.new()
	_success_box.add_theme_constant_override("separation", 14)
	_success_box.visible = false
	body.add_child(_success_box)

	_success_icon = LoginTheme.icon("check", 72, LoginTheme.LIFE)
	_success_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_success_box.add_child(_success_icon)

	_success_title = LoginTheme.label("Conta criada!", 28, LoginTheme.GOLD_LIGHT)
	_success_title.add_theme_font_override("font", LoginTheme.title_font())
	_success_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_box.add_child(_success_title)

	_success_text = LoginTheme.label("", 19)
	_success_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_success_box.add_child(_success_text)


func _submit() -> void:
	if _busy:
		return
	_message.clear_message()
	var errors: Array = []  # [campo, mensagem]
	var e: String = Validators.username(_username.get_value())
	if e != "":
		errors.append([_username, e])
	e = Validators.email(_email.get_value())
	if e != "":
		errors.append([_email, e])
	var e_pass: String = Validators.new_password(_password.get_value())
	if e_pass != "":
		errors.append([_password, e_pass])
	e = Validators.confirm_password(_password.get_value(), _confirm.get_value())
	if e != "" and e_pass == "":
		errors.append([_confirm, e])
	for pair in errors:
		(pair[0] as PixelField).set_error(str(pair[1]))
	var terms_ok: bool = _terms.checked
	var privacy_ok: bool = _privacy.checked
	if not terms_ok:
		_terms.set_error("É preciso aceitar os Termos de Serviço.")
	if not privacy_ok:
		_privacy.set_error("É preciso aceitar a Política de Privacidade.")
	if not errors.is_empty():
		(errors[0][0] as PixelField).focus_edit()
		return
	if not (terms_ok and privacy_ok):
		return

	_set_busy(true)
	var username: String = _username.get_value().strip_edges()
	var res: Dictionary = await auth.register(username, _email.get_value(), _password.get_value())
	_set_busy(false)

	if bool(res["ok"]):
		_show_success(res["data"], username)
		return
	_show_failure(res)


func _show_failure(res: Dictionary) -> void:
	var field_errors: Dictionary = res["errors"]
	var handled: bool = false
	var map: Dictionary = {"username": _username, "email": _email, "password": _password}
	for key in map.keys():
		if field_errors.has(key):
			(map[key] as PixelField).set_error(str(field_errors[key]))
			handled = true
	if not handled or str(res["message"]) != "":
		_message.show_error(str(res["message"]))
	Audio.play_sfx("hurt", 0.03)


func _show_success(data: Dictionary, username: String) -> void:
	_response = data
	Session.start(data, username)
	var can_enter: bool = Session.is_active()
	set_title("CONTA CRIADA")
	_form_box.visible = false
	_success_box.visible = true
	_create_btn.visible = false
	if can_enter:
		_success_text.text = "Bem-vindo, %s! Sua jornada está pronta para começar." % username
		_enter_btn.visible = true
	else:
		_success_text.text = "Sua conta foi criada, %s. Se o servidor pediu confirmação por e-mail, verifique sua caixa de entrada e depois entre com seus dados." % username
		_back_btn.visible = true
	Audio.play_sfx("levelup")
	if Motion.on():
		_success_icon.pivot_offset = Vector2(36, 36)
		_success_icon.scale = Vector2(0.3, 0.3)
		var tw := create_tween()
		tw.tween_property(_success_icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_busy(on: bool) -> void:
	_busy = on
	_create_btn.set_loading(on, "CRIANDO...")
	for f in [_username, _email, _password, _confirm]:
		(f as PixelField).set_enabled(not on)