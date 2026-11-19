class_name RecoveryWindow
extends ModalWindow
# Recuperação de senha: pede o e-mail e solicita ao servidor o envio das instruções.

var auth: AuthService

var _email: PixelField
var _message: FormMessage
var _send_btn: PixelButton
var _busy: bool = false


func _init(p_auth: AuthService) -> void:
	super("RECUPERAR SENHA", 480.0)
	auth = p_auth

	var intro := LoginTheme.label("Informe o e-mail da sua conta. Se ele estiver cadastrado, enviaremos as instruções para criar uma nova senha.", 18)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(intro)

	_email = PixelField.new("E-mail", "nome@exemplo.com", "mail", false, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	_email.edit.max_length = 120
	_email.submitted.connect(_submit)
	body.add_child(_email)

	_message = FormMessage.new()
	body.add_child(_message)

	var back := HBoxContainer.new()
	back.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(back)
	var back_link := LoginTheme.link("Voltar ao login", 17)
	back_link.pressed.connect(close)
	back.add_child(back_link)

	_send_btn = PixelButton.new("ENVIAR INSTRUÇÕES", PixelButton.Kind.GOLD)
	_send_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_send_btn.custom_minimum_size = Vector2(0, 56)
	_send_btn.pressed.connect(_submit)
	footer.add_child(_send_btn)


func on_opened() -> void:
	_email.focus_edit()


func _submit() -> void:
	if _busy:
		return
	_message.clear_message()
	var e: String = Validators.email(_email.get_value())
	if e != "":
		_email.set_error(e)
		_email.focus_edit()
		return
	_busy = true
	_send_btn.set_loading(true, "ENVIANDO...")
	_email.set_enabled(false)
	var res: Dictionary = await auth.request_password_reset(_email.get_value())
	_busy = false
	_send_btn.set_loading(false)
	_email.set_enabled(true)

	if bool(res["ok"]):
		# Resposta genérica de propósito: não revela se o e-mail existe.
		_message.show_success("Pedido enviado. Se este e-mail estiver cadastrado, você receberá as instruções em instantes. Confira também o spam.")
		_send_btn.text = "ENVIAR NOVAMENTE"
		return
	var field_errors: Dictionary = res["errors"]
	if field_errors.has("email"):
		_email.set_error(str(field_errors["email"]))
	if not field_errors.has("email") or str(res["message"]) != "":
		_message.show_error(str(res["message"]))
	Audio.play_sfx("hurt", 0.03)