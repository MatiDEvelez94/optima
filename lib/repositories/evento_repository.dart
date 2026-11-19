import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/cuenta.dart';
import '../models/evento.dart';
import '../models/evento_aceptado.dart';
import '../models/evento_finalizado.dart';
import '../models/postulacion.dart';
import '../models/user_session.dart';
import 'api_client.dart';

// Un evento activo tal como lo ve quien busca trabajo: el evento y los datos
// del salon que lo publico
class EventoPublico {
  const EventoPublico({
    required this.id,
    required this.salon,
    required this.direccion,
    required this.fotos,
    required this.evento,
  });

  final String id;
  final String salon;
  final String direccion;
  final List<Uint8List> fotos;
  final Evento evento;
}

// Una postulacion que le llego al dueño del salon, con la persona que la envio
class SolicitudRecibida {
  const SolicitudRecibida({
    required this.id,
    required this.nombre,
    required this.profesion,
    required this.telefono,
    this.calificacion,
    this.cuenta,
  });

  final String id; // identificador de la postulacion
  final String nombre;
  final String profesion;
  final String telefono;
  final double? calificacion; // null = todavia sin calificaciones
  final Cuenta? cuenta; // null = persona de ejemplo
}

// Eventos, postulaciones, avisos, historial y calificaciones contra el
// servidor. Despues de cada cambio vuelve a cargar los datos y deja listas
// las listas en memoria que usan las pantallas.
class EventoRepository {
  // Eventos activos de todos los salones (los ve quien busca trabajo)
  static final List<EventoPublico> activos = [];
  // Postulaciones pendientes que recibio el evento del dueño de salon
  static final List<SolicitudRecibida> recibidas = [];

  // Fotos y CVs ya descargados (para no bajarlos de nuevo)
  static final Map<String, Uint8List> _archivos = {};
  static final Set<String> _faltan = {};

  static Future<Uint8List?> _bytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    final guardado = _archivos[url];
    if (guardado != null) return guardado;
    if (_faltan.contains(url)) return null;
    // Las fotos de los salones de ejemplo viven dentro de la app web
    final ruta = url.startsWith('/assets/') ? '/m/assets$url' : url;
    final bytes = await ApiClient.bytesDe(ruta);
    if (bytes == null) {
      _faltan.add(url);
    } else {
      _archivos[url] = bytes;
    }
    return bytes;
  }

  static Future<List<Uint8List>> _fotosDe(List<dynamic> urls) async {
    final lista = await Future.wait(urls.map((u) => _bytes(u as String?)));
    return lista.whereType<Uint8List>().toList();
  }

  // ---------- convertir lo que manda el servidor ----------

  static DateTime _fecha(String iso) {
    final p = iso.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static TimeOfDay _hora(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _fechaISO(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Evento _evento(Map<String, dynamic> j) {
    final puestos = <Puesto>[];
    for (final p in (j['puestos'] as List)) {
      puestos.add(
        Puesto(
          profesion: p['profesion'] as String,
          cantidad: (p['cantidad'] as num).toInt(),
          pagoHora: (p['pagoHora'] as num).toInt(),
        ),
      );
    }
    final ev = Evento(
      id: j['id'] as String?,
      tipo: j['tipo'] as String,
      fecha: _fecha(j['fecha'] as String),
      inicio: _hora(j['inicio'] as String),
      fin: _hora(j['fin'] as String),
      invitados: ((j['invitados'] as num?) ?? 0).toInt(),
      puestos: puestos,
      notas: (j['notas'] as String?) ?? '',
    );
    for (final c in ((j['confirmados'] as List?) ?? const [])) {
      ev.confirmados.add(
        Confirmado(
          nombre: c['nombre'] as String,
          profesion: c['profesion'] as String,
        ),
      );
    }
    return ev;
  }

  static int _pagoDe(Evento ev, String puesto) {
    for (final p in ev.puestos) {
      if (p.profesion.toLowerCase() == puesto.toLowerCase()) return p.pagoHora;
    }
    return 0;
  }

  // ---------- actualizar todo ----------

  // Trae de la base de datos lo que ve la persona segun su rol.
  // Si no hay conexion, la app sigue mostrando lo que ya tenia.
  static Future<void> refrescar() async {
    try {
      await _cargarActivos();
    } catch (e) {
      debugPrint('No se pudieron cargar los eventos: $e');
    }
    if (!UserSession.logueado) return;
    try {
      if (UserSession.rol == 'mozo') {
        await _cargarMozo();
      } else if (UserSession.rol == 'salon') {
        await _cargarSalon();
      }
    } catch (e) {
      debugPrint('No se pudieron cargar tus datos: $e');
    }
  }

  static Future<void> _cargarActivos() async {
    final r = await ApiClient.get('/api/eventos');
    final items = (r['eventos'] as List).cast<Map<String, dynamic>>();
    final lista = await Future.wait(
      items.map((j) async {
        return EventoPublico(
          id: j['id'] as String,
          salon: (j['salon'] as String?) ?? '',
          direccion: (j['direccion'] as String?) ?? '',
          fotos: await _fotosDe((j['fotos'] as List?) ?? const []),
          evento: _evento(j),
        );
      }),
    );
    activos
      ..clear()
      ..addAll(lista);
  }

  // ---------- quien busca trabajo ----------

  static Future<void> _cargarMozo() async {
    final cuenta = UserSession.cuentaActual;
    if (cuenta == null) return;

    // Postulaciones: pendientes y confirmadas
    final pr = await ApiClient.get('/api/postulaciones');
    final pendientes = <Postulacion>[];
    final aceptados = <EventoAceptado>[];
    for (final j in (pr['postulaciones'] as List).cast<Map<String, dynamic>>()) {
      final evJson = j['evento'] as Map<String, dynamic>?;
      if (evJson == null) continue;
      final ev = _evento(evJson);
      final puesto = j['puesto'] as String;
      final pago = _pagoDe(ev, puesto);
      final salon = (evJson['salon'] as String?) ?? '';
      final estado = j['estado'] as String?;
      if (estado == 'pendiente') {
        pendientes.add(
          Postulacion(
            id: j['id'] as String?,
            eventoId: j['eventoId'] as String?,
            salon: salon,
            fecha: Evento.formatoFecha(ev.fecha),
            horario: ev.horario,
            puesto: puesto,
            pagoHora: pago,
            horas: ev.horas,
            inicio: ev.inicioDT,
            fin: ev.finDT,
          ),
        );
      } else if (estado == 'confirmada') {
        final fotos = await _fotosDe((evJson['fotos'] as List?) ?? const []);
        aceptados.add(
          EventoAceptado(
            salon: salon,
            tipo: ev.tipo,
            fecha: Evento.formatoFecha(ev.fecha),
            horario: ev.horario,
            inicio: ev.inicioDT,
            fin: ev.finDT,
            direccion: (evJson['direccion'] as String?) ?? '',
            size: ev.invitados > 0 ? '${ev.invitados} personas' : '-',
            puesto: puesto,
            pagoHora: pago,
            horas: ev.horas,
            puestosEvento: ev.puestos.map((p) => p.etiqueta).toList(),
            imageBytes: fotos.isEmpty ? null : fotos.first,
            origen: j['eventoId'],
          ),
        );
      }
    }

    // Avisos (solicitud rechazada, evento cancelado)
    final ar = await ApiClient.get('/api/avisos');
    final avisos = <AvisoMozo>[
      for (final a in (ar['avisos'] as List).cast<Map<String, dynamic>>())
        AvisoMozo(
          id: a['id'] as String?,
          titulo: (a['titulo'] as String?) ?? '',
          detalle: (a['detalle'] as String?) ?? '',
        ),
    ];

    // Eventos ya trabajados y las notas que dieron los salones
    final tr = await ApiClient.get('/api/trabajos');
    final trabajos = <TrabajoRealizado>[];
    final notas = <Calificacion>[];
    for (final t in (tr['trabajos'] as List).cast<Map<String, dynamic>>()) {
      final fecha = Evento.formatoFecha(_fecha(t['fecha'] as String));
      final ini = Evento.formatoHora(_hora(t['inicio'] as String));
      final fin = Evento.formatoHora(_hora(t['fin'] as String));
      final estrellas = ((t['estrellas'] as num?) ?? 0).toDouble();
      final comentario = (t['comentario'] as String?) ?? '';
      trabajos.add(
        TrabajoRealizado(
          salon: (t['salon'] as String?) ?? '',
          tipo: (t['tipo'] as String?) ?? '',
          fecha: fecha,
          horario: '${ini}hs - ${fin}hs',
          direccion: (t['direccion'] as String?) ?? '',
          puesto: (t['puesto'] as String?) ?? '',
          pagoHora: ((t['pagoHora'] as num?) ?? 0).toInt(),
          horas: ((t['horas'] as num?) ?? 0).toDouble(),
          estrellas: estrellas,
          comentario: comentario,
        ),
      );
      if (estrellas > 0) {
        notas.add(
          Calificacion(
            estrellas: estrellas,
            salon: (t['salon'] as String?) ?? '',
            evento: '${t['tipo']} - $fecha',
            comentario: comentario,
          ),
        );
      }
    }

    // Todo listo: se reemplazan las listas de una vez
    Postulacion.enviadas
      ..clear()
      ..addAll(pendientes);
    EventoAceptado.aceptados
      ..clear()
      ..addAll(aceptados);
    cuenta.avisos
      ..clear()
      ..addAll(avisos);
    cuenta.historialTrabajos
      ..clear()
      ..addAll(trabajos);
    cuenta.calificaciones
      ..clear()
      ..addAll(notas);
    Postulacion.notificar();
  }

  static Future<void> postular({
    required String eventoId,
    required String puesto,
  }) async {
    await ApiClient.post('/api/postulaciones', {
      'eventoId': eventoId,
      'puesto': puesto,
    });
    await refrescar();
  }

  static Future<void> cancelarPostulacion(Postulacion p) async {
    final id = p.id;
    if (id == null) throw ApiError('La postulación no tiene identificador');
    await ApiClient.delete('/api/postulaciones/$id');
    Postulacion.enviadas.remove(p);
    Postulacion.notificar();
  }

  static Future<void> quitarAviso(AvisoMozo a) async {
    final id = a.id;
    if (id == null) return;
    await ApiClient.delete('/api/avisos/$id');
  }

  // ---------- dueño de salon ----------

  static Future<void> _cargarSalon() async {
    final cuenta = UserSession.cuentaActual;

    final r = await ApiClient.get('/api/evento/mio');
    final j = r['evento'] as Map<String, dynamic>?;
    Evento? ev;
    final recibidasNuevas = <SolicitudRecibida>[];
    if (j != null) {
      ev = _evento(j);
      final pr = await ApiClient.get('/api/eventos/${ev.id}/postulaciones');
      for (final p in (pr['postulaciones'] as List).cast<Map<String, dynamic>>()) {
        if (p['estado'] != 'pendiente') continue;
        recibidasNuevas.add(await _recibida(p));
      }
    }

    // Eventos ya finalizados (historial)
    final hr = await ApiClient.get('/api/historial');
    final historial = <EventoFinalizado>[];
    for (final h in (hr['historial'] as List).cast<Map<String, dynamic>>()) {
      historial.add(
        EventoFinalizado(
          tipo: (h['tipo'] as String?) ?? '',
          fecha: Evento.formatoFecha(_fecha(h['fecha'] as String)),
          horario: (h['horario'] as String?) ?? '',
          salon: (h['salon'] as String?) ?? '',
          costoTotal: ((h['costoTotal'] as num?) ?? 0).toInt(),
          personas: [
            for (final p in (h['personas'] as List))
              Resenia(
                nombre: p['nombre'] as String,
                profesion: p['profesion'] as String,
                estrellas: ((p['estrellas'] as num?) ?? 0).toDouble(),
                comentario: (p['comentario'] as String?) ?? '',
              ),
          ],
        ),
      );
    }

    Evento.publicados.clear();
    if (ev != null) Evento.publicados.add(ev);
    recibidas
      ..clear()
      ..addAll(recibidasNuevas);
    cuenta?.historial = historial;
  }

  static Future<SolicitudRecibida> _recibida(Map<String, dynamic> p) async {
    final m = p['mozo'] as Map<String, dynamic>;
    final cal = m['calificacion'] as Map<String, dynamic>?;
    final nombre = '${m['nombre'] ?? ''} ${m['apellido'] ?? ''}'.trim();
    final telefono = (m['telefono'] as String?) ?? '';

    // Las personas de ejemplo no tienen cuenta propia (se muestra un CV de ejemplo)
    Cuenta? cuenta;
    if (m['ejemplo'] != true) {
      final cv = m['cv'] as Map<String, dynamic>?;
      cuenta = Cuenta(
        correo: (m['correo'] as String?) ?? '',
        password: '',
        rol: 'mozo',
        nombre: (m['nombre'] as String?) ?? '',
        apellido: (m['apellido'] as String?) ?? '',
        dni: (m['dni'] as String?) ?? '',
        telefono: telefono,
        foto: await _bytes(m['foto'] as String?),
        cvNombre: cv == null ? '' : ((cv['nombre'] as String?) ?? ''),
        cvBytes: cv == null ? null : await _bytes(cv['datos'] as String?),
      );
      cuenta.cvUrl = cv == null ? null : cv['datos'] as String?;
    }

    return SolicitudRecibida(
      id: p['id'] as String,
      nombre: nombre,
      profesion: (p['puesto'] as String?) ?? '',
      telefono: telefono,
      calificacion: cal == null ? null : (cal['prom'] as num).toDouble(),
      cuenta: cuenta,
    );
  }

  // Publica un evento nuevo o guarda los cambios de uno ya publicado
  static Future<void> guardarEvento({
    Evento? editar,
    required String tipo,
    required DateTime fecha,
    required TimeOfDay inicio,
    required TimeOfDay fin,
    required int invitados,
    required List<Puesto> puestos,
    required String notas,
  }) async {
    final cuerpo = <String, dynamic>{
      'tipo': tipo,
      'fecha': _fechaISO(fecha),
      'inicio': Evento.formatoHora(inicio),
      'fin': Evento.formatoHora(fin),
      'invitados': invitados,
      'notas': notas,
      'puestos': [
        for (final p in puestos)
          {
            'profesion': p.profesion,
            'cantidad': p.cantidad,
            'pagoHora': p.pagoHora,
          },
      ],
    };
    final id = editar?.id;
    if (id != null) {
      await ApiClient.put('/api/eventos/$id', cuerpo);
    } else {
      await ApiClient.post('/api/eventos', cuerpo);
    }
    await refrescar();
  }

  // Cancela el evento: a las personas postuladas o confirmadas les llega un aviso
  static Future<void> eliminarEvento(Evento ev) async {
    final id = ev.id;
    if (id == null) throw ApiError('El evento no tiene identificador');
    await ApiClient.delete('/api/eventos/$id');
    await refrescar();
  }

  // El dueño confirma o rechaza a una persona
  static Future<void> decidir(
    SolicitudRecibida s, {
    required bool confirmar,
  }) async {
    final accion = confirmar ? 'confirmar' : 'rechazar';
    await ApiClient.post('/api/postulaciones/${s.id}/$accion');
    await refrescar();
  }

  // Termina el evento y guarda las calificaciones.
  // [resenias] va en el mismo orden que ev.confirmados.
  static Future<void> finalizarEvento(
    Evento ev,
    List<Map<String, dynamic>> resenias,
  ) async {
    final id = ev.id;
    if (id == null) throw ApiError('El evento no tiene identificador');
    await ApiClient.post('/api/eventos/$id/finalizar', {'resenias': resenias});
    await refrescar();
  }
}