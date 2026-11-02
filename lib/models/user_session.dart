import 'package:flutter/services.dart';
import 'cuenta.dart';
import 'solicitud_salon.dart';

// Guarda en memoria los datos de la sesion mientras la app está abierta.
// Es temporal: cuando conecten la base de datos, esto se reemplaza.
class UserSession {
  // Cuenta del administrador. SOLO para el prototipo: con base de datos,
  // el admin se valida en el servidor y la clave no va escrita en el codigo.
  static const String adminCorreo = 'admin12@gmail.com';
  static const String adminPass = '4231';

  // false = invitado (puede mirar la app sin cuenta)
  static bool logueado = false;
  // 'mozo', 'salon' o 'admin' (se completa al registrarse o iniciar sesion)
  static String rol = '';
  static String nombre = '';
  static String apellido = '';
  static String correo = '';
  static String password = '';
  static String telefono = '';
  static String dni = '';
  static Uint8List? foto;
  // Curriculum en PDF (opcional, solo para quien busca trabajo)
  static String cvNombre = '';
  static Uint8List? cvBytes;
  // Datos del salon inscripto (solo para rol 'salon')
  static String salonNombre = '';
  static String salonDireccion = '';
  static String salonCapacidad = '';
  static List<Uint8List> salonFotos = [];
  // Solicitud del salon (para saber si el admin ya la aprobo)
  static SolicitudSalon? solicitudSalon;
  // Cuenta con la que se inicio sesion (null si es invitado o admin)
  static Cuenta? cuentaActual;

  // Vuelve a dejar la app como invitado
  static void cerrarSesion() {
    logueado = false;
    rol = '';
    nombre = '';
    apellido = '';
    correo = '';
    password = '';
    telefono = '';
    dni = '';
    foto = null;
    cvNombre = '';
    cvBytes = null;
    salonNombre = '';
    salonDireccion = '';
    salonCapacidad = '';
    salonFotos = [];
    solicitudSalon = null;
    cuentaActual = null;
  }
}