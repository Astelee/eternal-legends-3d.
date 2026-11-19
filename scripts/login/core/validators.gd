class_name Validators
extends RefCounted
# Validações de formulário. Cada função devolve "" quando está tudo certo
# ou a mensagem de erro (pt-BR) a ser exibida no campo.

const USERNAME_MIN := 3
const USERNAME_MAX := 16
const PASSWORD_MIN := 8


static func is_email(value: String) -> bool:
	var re := RegEx.new()
	re.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}$")
	return re.search(value.strip_edges()) != null


static func login_identifier(value: String) -> String:
	if value.strip_edges() == "":
		return "Informe seu usuário ou e-mail."
	return ""


static func login_password(value: String) -> String:
	if value == "":
		return "Informe sua senha."
	return ""


static func username(value: String) -> String:
	var v := value.strip_edges()
	if v == "":
		return "Escolha um nome de usuário."
	if v.length() < USERNAME_MIN or v.length() > USERNAME_MAX:
		return "Use de %d a %d caracteres." % [USERNAME_MIN, USERNAME_MAX]
	var re := RegEx.new()
	re.compile("^[A-Za-z0-9_]+$")
	if re.search(v) == null:
		return "Use apenas letras, números e _ (sem espaços)."
	return ""


static func email(value: String) -> String:
	var v := value.strip_edges()
	if v == "":
		return "Informe seu e-mail."
	if not is_email(v):
		return "Digite um e-mail válido, como nome@exemplo.com."
	return ""


static func new_password(value: String) -> String:
	if value == "":
		return "Crie uma senha."
	if value.length() < PASSWORD_MIN:
		return "A senha precisa ter pelo menos %d caracteres." % PASSWORD_MIN
	var has_letter := false
	var has_digit := false
	for i in value.length():
		var ch := value.substr(i, 1)
		if ch.to_lower() != ch.to_upper():
			has_letter = true
		elif ch.is_valid_int():
			has_digit = true
	if not (has_letter and has_digit):
		return "Misture letras e números na senha."
	return ""


static func confirm_password(password: String, confirm: String) -> String:
	if confirm == "":
		return "Repita a senha para confirmar."
	if confirm != password:
		return "As senhas não conferem."
	return ""