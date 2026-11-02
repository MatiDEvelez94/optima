// Reglas simples para revisar lo que escribe la persona en los formularios
class Validadores {
  // algo@dominio.com (el final tiene que ser solo letras)
  static bool correo(String texto) =>
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$').hasMatch(texto.trim());

  // 7 u 8 numeros
  static bool dni(String texto) => texto.length >= 7 && texto.length <= 8;

  // 10 numeros: codigo de area + numero, sin 0 ni 15 (sirve para WhatsApp)
  static bool telefono(String texto) => texto.length == 10;

  // Al menos 6 caracteres
  static bool password(String texto) => texto.length >= 6;
}