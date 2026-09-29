import 'package:flutter/services.dart';

// Guarda en memoria los datos del registro mientras la app está abierta.
// Es temporal: cuando conecten la base de datos, esto se reemplaza.
class UserSession {
  static String nombre = '';
  static String apellido = '';
  static String correo = '';
  static String telefono = '';
  static String dni = '';
  static Uint8List? foto;
}