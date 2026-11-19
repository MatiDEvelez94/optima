import 'package:flutter/services.dart';
import 'evento.dart';
import 'evento_aceptado.dart';
import 'evento_finalizado.dart';
import 'postulacion.dart';
import 'solicitud_salon.dart';
import 'user_session.dart';

// Una postulacion que le llego a un dueño de salon, con la persona que la envio
class PostulacionRecibida {
  const PostulacionRecibida(this.mozo, this.postulacion);

  final Cuenta mozo;
  final Postulacion postulacion;
}

// Una calificacion que un salon le dio a una persona despues de un evento
class Calificacion {
  const Calificacion({
    required this.estrellas,
    required this.salon,
    required this.evento,
    this.comentario = '',
  });

  final String comentario; // reseña opcional del salon
  final double estrellas; // de 0,5 a 5 (con medias estrellas)
  final String salon; // que salon la dio
  final String evento; // Casamiento - Sabado 22/11/2026
}

// Cuenta de una persona registrada (mozo o dueño de salon).
// "Base de datos" temporal: vive mientras la app esta abierta.
// Sirve para poder cerrar sesion y volver a entrar con correo y contraseña.
class Cuenta {
  Cuenta({
    required this.correo,
    required this.password,
    required this.rol,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.telefono,
    this.foto,
    this.cvNombre = '',
    this.cvBytes,
    this.solicitud,
  });

  final String correo;
  String password; // cambia cuando la persona cambia su contraseña
  final String rol; // 'mozo' o 'salon'
  String nombre; // se pueden editar desde el perfil
  String apellido;
  final String dni;
  String telefono;
  Uint8List? foto; // cambia cuando la persona cambia su foto de perfil
  final String cvNombre;
  final Uint8List? cvBytes;
  String? cvUrl; // direccion del PDF en el servidor (para abrirlo aparte)
  final SolicitudSalon? solicitud; // solo si es dueño de salon

  // Lo que la persona fue haciendo en la app
  Evento? evento;
  List<Postulacion> postulaciones = [];
  List<EventoAceptado> aceptados = []; // mozo: eventos donde fue confirmado
  List<EventoFinalizado> historial = []; // dueño: eventos ya terminados
  final List<Calificacion> calificaciones = []; // mozo: lo que le dieron los salones
  final List<TrabajoRealizado> historialTrabajos = []; // mozo: eventos ya hechos
  final List<AvisoMozo> avisos = []; // mozo: mensajes pendientes de "Entendido"

  // Promedio de las calificaciones (null si todavia no lo calificaron)
  double? get promedio {
    if (calificaciones.isEmpty) return null;
    final suma = calificaciones.fold<double>(0, (a, c) => a + c.estrellas);
    return suma / calificaciones.length;
  }

  static final List<Cuenta> todas = [];

  static Cuenta? buscar(String correo) {
    final buscado = correo.trim().toLowerCase();
    for (final c in todas) {
      if (c.correo == buscado) return c;
    }
    return null;
  }

  // Crea la cuenta con los datos que la persona acaba de completar
  static Cuenta crearDesdeSesion({SolicitudSalon? solicitud}) {
    final cuenta = Cuenta(
      correo: UserSession.correo.trim().toLowerCase(),
      password: UserSession.password,
      rol: UserSession.rol,
      nombre: UserSession.nombre,
      apellido: UserSession.apellido,
      dni: UserSession.dni,
      telefono: UserSession.telefono,
      foto: UserSession.foto,
      cvNombre: UserSession.cvNombre,
      cvBytes: UserSession.cvBytes,
      solicitud: solicitud,
    );
    todas.add(cuenta);
    UserSession.cuentaActual = cuenta;
    EventoAceptado.aceptados.clear(); // cuenta nueva: empieza sin eventos
    return cuenta;
  }

  // Cambia la contraseña de la cuenta y de la sesion
  void cambiarPassword(String nueva) {
    password = nueva;
    UserSession.password = nueva;
  }

  // Carga los datos de la cuenta en la sesion (al iniciar sesion)
  void iniciarSesion() {
    UserSession.logueado = true;
    UserSession.rol = rol;
    UserSession.nombre = nombre;
    UserSession.apellido = apellido;
    UserSession.correo = correo;
    UserSession.password = password;
    UserSession.dni = dni;
    UserSession.telefono = telefono;
    UserSession.foto = foto;
    UserSession.cvNombre = cvNombre;
    UserSession.cvBytes = cvBytes;
    UserSession.cuentaActual = this;

    final s = solicitud;
    if (s != null) {
      UserSession.solicitudSalon = s;
      UserSession.salonNombre = s.salonNombre;
      UserSession.salonDireccion = s.direccion;
      UserSession.salonCapacidad = s.capacidad;
      UserSession.salonFotos = List.of(s.fotos);
    }

    Evento.publicados.clear();
    if (evento != null) Evento.publicados.add(evento!);
    Postulacion.enviadas
      ..clear()
      ..addAll(postulaciones);
    EventoAceptado.aceptados
      ..clear()
      ..addAll(aceptados);
  }

  // Guarda lo que hizo en la sesion (al cerrar sesion)
  void guardarSesion() {
    evento = Evento.activo;
    postulaciones = List.of(Postulacion.enviadas);
    aceptados = List.of(EventoAceptado.aceptados);
  }

  // ---------- conexion entre quien busca trabajo y el dueño del salon ----------

  // Salones con un evento publicado y aprobado: son los que ve quien busca
  // trabajo en su inicio (se actualiza cuando el dueño cierra sesion)
  static List<Cuenta> conEventoAbierto() => todas
      .where(
        (c) =>
            c.rol == 'salon' &&
            c.evento != null &&
            c.solicitud?.estado == EstadoSalon.aprobada,
      )
      .toList();

  // Postulaciones reales que le llegaron a este dueño de salon
  static List<PostulacionRecibida> recibidasPor(Cuenta dueno) {
    final lista = <PostulacionRecibida>[];
    for (final c in todas) {
      if (c.rol != 'mozo') continue;
      for (final p in c.postulaciones) {
        if (p.destino == dueno) lista.add(PostulacionRecibida(c, p));
      }
    }
    return lista;
  }

  // El evento de un dueño tal como lo ve la persona confirmada
  static EventoAceptado _aceptadoDesde(
    Evento ev,
    Cuenta dueno,
    String puesto,
    int pagoHora,
  ) {
    final s = dueno.solicitud;
    return EventoAceptado(
      salon: s?.salonNombre ?? dueno.nombre,
      tipo: ev.tipo,
      fecha: Evento.formatoFecha(ev.fecha),
      horario: ev.horario,
      inicio: ev.inicioDT,
      fin: ev.finDT,
      direccion: s?.direccion ?? '',
      size: ev.invitados > 0 ? '${ev.invitados} personas' : '-',
      puesto: puesto,
      pagoHora: pagoHora,
      horas: ev.horas,
      puestosEvento: ev.puestos.map((p) => p.etiqueta).toList(),
      imageBytes: (s != null && s.fotos.isNotEmpty) ? s.fotos.first : null,
      origen: ev,
    );
  }

  // El dueño confirmo esta postulacion: pasa a "Mis eventos" de la persona
  void aceptarPostulacion(Postulacion p, Evento ev) {
    postulaciones.remove(p);
    final dueno = p.destino;
    if (dueno == null) return;
    aceptados.add(_aceptadoDesde(ev, dueno, p.puesto, p.pagoHora));
  }

  // El dueño rechazo esta postulacion: se saca de la lista de la persona
  void rechazarPostulacion(Postulacion p) {
    postulaciones.remove(p);
    avisos.add(
      AvisoMozo(
        titulo: 'Tu solicitud fue rechazada',
        detalle: '${p.salon} no aceptó tu postulación como ${p.puesto} '
            '(${p.fecha}, ${p.horario}).',
      ),
    );
  }

  // El dueño edito su evento: se actualizan las postulaciones y los eventos
  // aceptados de todas las personas
  static void sincronizarEvento(Cuenta dueno, Evento ev) {
    for (final c in todas) {
      final nuevas = <Postulacion>[];
      for (final p in c.postulaciones) {
        if (p.destino != dueno) {
          nuevas.add(p);
          continue;
        }
        final actualizada = p.conDatosDe(ev);
        if (actualizada != null) nuevas.add(actualizada);
      }
      c.postulaciones = nuevas;

      c.aceptados = c.aceptados.map((a) {
        if (a.origen != ev) return a;
        var pago = a.pagoHora;
        for (final p in ev.puestos) {
          if (p.profesion.toLowerCase() == a.puesto.toLowerCase()) {
            pago = p.pagoHora;
          }
        }
        return _aceptadoDesde(ev, dueno, a.puesto, pago);
      }).toList();
    }
  }

  // El evento termino o se elimino: ya no hay postulaciones ni eventos
  // aceptados que dependan de el. Si se cancelo (no termino), a cada persona
  // afectada le llega un aviso.
  static void retirarEvento(Cuenta dueno, Evento ev, {bool cancelado = false}) {
    final salon = dueno.solicitud?.salonNombre ?? 'El salón';
    for (final c in todas) {
      final afectada = c.postulaciones.any((p) => p.destino == dueno) ||
          c.aceptados.any((a) => a.origen == ev);
      c.postulaciones.removeWhere((p) => p.destino == dueno);
      c.aceptados.removeWhere((a) => a.origen == ev);
      if (cancelado && afectada) {
        c.avisos.add(
          AvisoMozo(
            titulo: 'Evento cancelado',
            detalle: '$salon canceló el evento '
                '(${Evento.formatoFecha(ev.fecha)}).',
          ),
        );
      }
    }
  }
}