import 'dart:typed_data';
import '../models/cuenta.dart';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import 'api_client.dart';

// Cuenta y sesion contra el servidor: iniciar sesion, registrarse, salir.
// Despues de cada llamada deja cargados UserSession y Cuenta, asi el resto
// de la app (que todavia lee esos datos en memoria) sigue funcionando.
class AuthRepository {
  static Future<void> iniciarSesion(String correo, String password) async {
    final r = await ApiClient.post('/api/login', {
      'correo': correo.trim().toLowerCase(),
      'password': password,
    });
    await _cargar(r, password);
  }

  static Future<void> registrarMozo({
    required String nombre,
    required String apellido,
    required String dni,
    required String correo,
    required String password,
    required String telefono,
    Uint8List? foto,
    String cvNombre = '',
    Uint8List? cvBytes,
  }) async {
    final r = await ApiClient.post('/api/registro', {
      'rol': 'mozo',
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'correo': correo.trim().toLowerCase(),
      'password': password,
      'telefono': telefono,
      'foto': foto == null ? null : ApiClient.dataUrl(foto),
      'cv': cvBytes == null
          ? null
          : {
              'nombre': cvNombre,
              'datos': ApiClient.dataUrl(cvBytes, mime: 'application/pdf'),
            },
    });
    await _cargar(r, password);
  }

  // Registro del dueño de un salon: los datos del dueño estan en UserSession
  // (los cargo pantalla "Datos del Dueño") y los del salon vienen por parametro.
  static Future<void> registrarSalon({
    required String salonNombre,
    required String direccion,
    required String capacidad,
    required List<Uint8List> fotos,
  }) async {
    final r = await ApiClient.post('/api/registro', {
      'rol': 'salon',
      'nombre': UserSession.nombre,
      'apellido': UserSession.apellido,
      'dni': UserSession.dni,
      'correo': UserSession.correo.trim().toLowerCase(),
      'password': UserSession.password,
      'telefono': UserSession.telefono,
      'foto': null,
      'salon': {
        'salonNombre': salonNombre,
        'direccion': direccion,
        'capacidad': int.tryParse(capacidad) ?? 0,
        'fotos': fotos.map((f) => ApiClient.dataUrl(f)).toList(),
      },
    });
    await _cargar(r, UserSession.password);
  }

  static Future<void> cerrarSesion() async {
    try {
      await ApiClient.post('/api/logout');
    } catch (_) {
      // aunque no haya conexion, la app igual queda como invitado
    }
  }

  // Si ya habia una sesion abierta en el servidor, la recupera.
  // Devuelve true si habia sesion.
  static Future<bool> restaurarSesion() async {
    try {
      final r = await ApiClient.get('/api/yo');
      if (r['cuenta'] == null) return false;
      await _cargar(r, '');
      return true;
    } catch (_) {
      return false;
    }
  }

  // Convierte la respuesta del servidor en Cuenta + UserSession
  static Future<void> _cargar(Map<String, dynamic> r, String password) async {
    final c = r['cuenta'] as Map<String, dynamic>?;
    if (c == null) throw ApiError('No se pudo iniciar sesión');

    final correo = (c['correo'] as String).toLowerCase();
    final rol = c['rol'] as String;

    // El administrador no tiene datos de persona: solo entra al panel
    if (rol == 'admin') {
      UserSession.cerrarSesion();
      UserSession.rol = 'admin';
      UserSession.correo = correo;
      UserSession.nombre = (c['nombre'] as String?) ?? 'Administrador';
      UserSession.logueado = true;
      return;
    }

    final foto = await ApiClient.bytesDe(c['foto'] as String?);
    final cv = c['cv'] as Map<String, dynamic>?;
    final cvBytes = cv == null ? null : await ApiClient.bytesDe(cv['datos']);

    SolicitudSalon? solicitud;
    final s = r['solicitud'] as Map<String, dynamic>?;
    if (s != null) {
      final urls = (s['fotos'] as List).cast<String>();
      final fotos = await Future.wait(urls.map(ApiClient.bytesDe));
      solicitud = SolicitudSalon(
        nombreDueno: c['nombre'] as String,
        apellidoDueno: (c['apellido'] as String?) ?? '',
        correo: correo,
        telefono: (c['telefono'] as String?) ?? '',
        dni: (c['dni'] as String?) ?? '',
        salonNombre: s['salonNombre'] as String,
        direccion: s['direccion'] as String,
        capacidad: '${s['capacidad']}',
        fotos: fotos.whereType<Uint8List>().toList(),
        fecha: DateTime.fromMillisecondsSinceEpoch(
          ((s['fecha'] as num?) ?? 0).toInt(),
        ),
        estado: _estado(s['estado'] as String?),
      )..avisoVisto = s['avisoVisto'] == true;
    }

    final cuenta = Cuenta(
      correo: correo,
      password: password,
      rol: rol,
      nombre: c['nombre'] as String,
      apellido: (c['apellido'] as String?) ?? '',
      dni: (c['dni'] as String?) ?? '',
      telefono: (c['telefono'] as String?) ?? '',
      foto: foto,
      cvNombre: cv == null ? '' : ((cv['nombre'] as String?) ?? ''),
      cvBytes: cvBytes,
      solicitud: solicitud,
    );

    // Reemplaza una copia vieja de la misma cuenta (si la hubiera)
    Cuenta.todas.removeWhere((x) => x.correo == correo);
    Cuenta.todas.add(cuenta);
    UserSession.cerrarSesion();
    cuenta.iniciarSesion();
  }

  static EstadoSalon _estado(String? e) {
    switch (e) {
      case 'aprobada':
        return EstadoSalon.aprobada;
      case 'rechazada':
        return EstadoSalon.rechazada;
      default:
        return EstadoSalon.pendiente;
    }
  }
}