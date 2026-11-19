import 'dart:typed_data';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import 'api_client.dart';

// Todo lo que tiene que ver con la cuenta y el salon contra el servidor:
// panel del administrador, editar perfil, foto, contraseña y datos del salon.
class CuentaRepository {
  // Fotos ya descargadas (para no bajarlas de nuevo cada vez)
  static final Map<String, Uint8List> _fotos = {};

  static Future<Uint8List?> _foto(String url) async {
    final guardada = _fotos[url];
    if (guardada != null) return guardada;
    final bytes = await ApiClient.bytesDe(url);
    if (bytes != null) _fotos[url] = bytes;
    return bytes;
  }

  static Future<List<Uint8List>> _fotosDe(List<dynamic> urls) async {
    final lista = await Future.wait(urls.map((u) => _foto(u as String)));
    return lista.whereType<Uint8List>().toList();
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

  // Actualiza los datos que cambian solos (por ejemplo cuando el admin
  // aprueba el salon). Se llama al abrir la app y al tocar las pestañas.
  static Future<void> refrescar() async {
    if (!UserSession.logueado) return;
    try {
      if (UserSession.rol == 'admin') {
        await cargarSolicitudes();
      } else if (UserSession.rol == 'salon') {
        await _refrescarMiSalon();
      }
    } catch (_) {
      // sin conexion: la app sigue mostrando lo que ya tenia
    }
  }

  // ---------- administrador ----------

  static Future<void> cargarSolicitudes() async {
    final r = await ApiClient.get('/api/admin/solicitudes');
    final items = (r['solicitudes'] as List).cast<Map<String, dynamic>>();
    final lista = await Future.wait(items.map(_solicitudDesde));
    SolicitudSalon.todas
      ..clear()
      ..addAll(lista);
    SolicitudSalon.notificar();
  }

  static Future<SolicitudSalon> _solicitudDesde(Map<String, dynamic> j) async {
    final d = (j['dueno'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final fotos = await _fotosDe((j['fotos'] as List?) ?? const []);
    return SolicitudSalon(
      id: j['id'] as String?,
      nombreDueno: (d['nombre'] as String?) ?? '',
      apellidoDueno: (d['apellido'] as String?) ?? '',
      correo: (d['correo'] as String?) ?? '',
      telefono: (d['telefono'] as String?) ?? '',
      dni: (d['dni'] as String?) ?? '',
      salonNombre: (j['salonNombre'] as String?) ?? '',
      direccion: (j['direccion'] as String?) ?? '',
      capacidad: '${j['capacidad']}',
      fotos: fotos,
      fecha: DateTime.fromMillisecondsSinceEpoch(
        ((j['fecha'] as num?) ?? 0).toInt(),
      ),
      estado: _estado(j['estado'] as String?),
    )..avisoVisto = j['avisoVisto'] == true;
  }

  // El administrador aprueba o rechaza una solicitud
  static Future<void> resolver(SolicitudSalon s, EstadoSalon estado) async {
    final id = s.id;
    if (id == null) throw ApiError('La solicitud no tiene identificador');
    await ApiClient.post('/api/admin/solicitudes/$id', {
      'estado': estado == EstadoSalon.aprobada ? 'aprobada' : 'rechazada',
    });
    s.estado = estado;
    SolicitudSalon.notificar();
  }

  // ---------- dueño de salon ----------

  static Future<void> _refrescarMiSalon() async {
    final r = await ApiClient.get('/api/yo');
    final s = r['solicitud'] as Map<String, dynamic>?;
    final actual = UserSession.solicitudSalon;
    if (s == null || actual == null) return;
    actual.estado = _estado(s['estado'] as String?);
    actual.avisoVisto = s['avisoVisto'] == true;
    actual.salonNombre = (s['salonNombre'] as String?) ?? actual.salonNombre;
    actual.direccion = (s['direccion'] as String?) ?? actual.direccion;
    actual.capacidad = '${s['capacidad']}';
    UserSession.salonNombre = actual.salonNombre;
    UserSession.salonDireccion = actual.direccion;
    UserSession.salonCapacidad = actual.capacidad;
  }

  static Future<void> guardarSalon({
    required String nombre,
    required String direccion,
    required String capacidad,
    required List<Uint8List> fotos,
  }) async {
    await ApiClient.put('/api/salon/mio', {
      'salonNombre': nombre,
      'direccion': direccion,
      'capacidad': int.tryParse(capacidad) ?? 0,
      'fotos': fotos.map((f) => ApiClient.dataUrl(f)).toList(),
    });
  }

  // El dueño toco "Entendido" en el cartel de salon aprobado
  static Future<void> marcarAvisoVisto() async {
    await ApiClient.put('/api/salon/mio', {'avisoVisto': true});
  }

  // ---------- cuenta ----------

  static Future<bool> correoExiste(String correo) async {
    final r = await ApiClient.get(
      '/api/correo-existe?correo=${Uri.encodeQueryComponent(correo)}',
    );
    return r['existe'] == true;
  }

  static Future<void> guardarPerfil({
    required String nombre,
    required String apellido,
    required String telefono, // solo los 10 numeros
  }) async {
    await ApiClient.put('/api/yo', {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
    });
  }

  static Future<void> guardarFoto(Uint8List bytes) async {
    await ApiClient.put('/api/yo', {'foto': ApiClient.dataUrl(bytes)});
  }

  static Future<void> cambiarPassword(String actual, String nueva) async {
    await ApiClient.post('/api/yo/password', {
      'actual': actual,
      'nueva': nueva,
    });
  }
}