class_name Motion
extends RefCounted
# Atalhos para respeitar a redução de movimento.


static func on() -> bool:
	return not LoginPrefs.reduced_motion


# Duração efetiva: 0 quando o movimento está reduzido.
static func dur(seconds: float) -> float:
	return seconds if on() else 0.0