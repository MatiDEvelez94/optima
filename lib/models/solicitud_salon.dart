import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum EstadoSalon { pendiente, aprobada, rechazada }

// Pedido de un dueño para inscribir su salon. Lo revisa el administrador:
// si lo aprueba, el salon pasa a estar activo.
class SolicitudSalon {
  SolicitudSalon({
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

  // "Base de datos" temporal: vive mientras la app esta abierta.
  // Los primeros son ejemplos inventados para que el admin vea contenido.
  static final List<SolicitudSalon> todas = [
    SolicitudSalon(
      nombreDueno: 'Carolina',
      apellidoDueno: 'Méndez',
      correo: 'carolina@ejemplo.com',
      telefono: '+54 9 261 555 0101',
      dni: '30111222',
      salonNombre: 'Salón Las Rosas',
      direccion: 'Calle San Juan 450',
      capacidad: '180',
      fotos: const [],
      fecha: DateTime(2026, 10, 12),
    ),
    SolicitudSalon(
      nombreDueno: 'Ricardo',
      apellidoDueno: 'Suárez',
      correo: 'ricardo@ejemplo.com',
      telefono: '+54 9 261 555 0202',
      dni: '28333444',
      salonNombre: 'Quinta El Molino',
      direccion: 'Ruta 7 km 12',
      capacidad: '350',
      fotos: const [],
      fecha: DateTime(2026, 10, 13),
    ),
    SolicitudSalon(
      nombreDueno: 'Laura',
      apellidoDueno: 'Giménez',
      correo: 'laura@ejemplo.com',
      telefono: '+54 9 261 555 0303',
      dni: '27555666',
      salonNombre: 'Salón Los Pinos',
      direccion: 'Av. Libertador 1500',
      capacidad: '250',
      fotos: const [],
      fecha: DateTime(2026, 9, 20),
      estado: EstadoSalon.aprobada,
    ),
    SolicitudSalon(
      nombreDueno: 'Hernán',
      apellidoDueno: 'Ortiz',
      correo: 'hernan@ejemplo.com',
      telefono: '+54 9 261 555 0404',
      dni: '25777888',
      salonNombre: 'Salón Aurora',
      direccion: 'Calle Mitre 320',
      capacidad: '120',
      fotos: const [],
      fecha: DateTime(2026, 9, 25),
      estado: EstadoSalon.aprobada,
    ),
  ];

  static List<SolicitudSalon> get pendientes =>
      todas.where((s) => s.estado == EstadoSalon.pendiente).toList();

  static List<SolicitudSalon> get activos =>
      todas.where((s) => s.estado == EstadoSalon.aprobada).toList();
}
