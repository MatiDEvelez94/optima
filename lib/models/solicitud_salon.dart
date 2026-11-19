import 'package:flutter/foundation.dart';

enum EstadoSalon { pendiente, aprobada, rechazada }

// Pedido de un dueño para inscribir su salon. Lo revisa el administrador:
// si lo aprueba, el salon pasa a estar activo.
class SolicitudSalon {
  SolicitudSalon({
    this.id,
    required this.nombreDueno,
    required this.apellidoDueno,
    required this.correo,
    required this.telefono,
    required this.dni,
    required this.salonNombre,
    required this.direccion,
    required this.capacidad,
    required this.fotos,
    required this.fecha,
    this.estado = EstadoSalon.pendiente,
  });

  // Identificador del salon en la base de datos
  final String? id;
  final String nombreDueno;
  final String apellidoDueno;
  final String correo;
  final String telefono;
  final String dni;
  // El dueño puede editar los datos de su salon
  String salonNombre;
  String direccion;
  String capacidad;
  List<Uint8List> fotos;
  final DateTime fecha;
  EstadoSalon estado;
  // El dueño ya toco "Entendido" en el cartel de salon aprobado
  bool avisoVisto = false;

  String get nombreCompleto => '$nombreDueno $apellidoDueno'.trim();

  // Avisa a las pantallas del admin que algo cambio (para que se actualicen)
  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);
  static void notificar() => cambios.value++;

  static String formatoFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Solicitudes que ve el administrador (se cargan desde la base de datos)
  static final List<SolicitudSalon> todas = [];

  static List<SolicitudSalon> get pendientes =>
      todas.where((s) => s.estado == EstadoSalon.pendiente).toList();

  static List<SolicitudSalon> get activos =>
      todas.where((s) => s.estado == EstadoSalon.aprobada).toList();
}