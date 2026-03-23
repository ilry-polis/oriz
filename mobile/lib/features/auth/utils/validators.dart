final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String email) {
  if (email.isEmpty) return 'Informe seu email';
  if (!_emailRegex.hasMatch(email)) return 'Email invalido';
  return null;
}

String? validatePassword(String password) {
  if (password.isEmpty) return 'Informe sua senha';
  if (password.length < 8) return 'Minimo 8 caracteres';
  return null;
}

String? validateName(String name) {
  if (name.isEmpty) return 'Informe seu nome';
  return null;
}
