import 'package:flutter/foundation.dart';
import 'cuenta.dart';
import 'evento.dart';
import 'evento_aceptado.dart';

// Una postulacion enviada por quien busca trabajo a un puesto de un evento
class Postulacion {
  Postulacion({
    this.id,
    this.eventoId,
    required this.salon,
    required this.fecha,
    required this.horario,
    required this.puesto,
    required this.pagoHora,
    required this.horas,
    this.inicio,
    this.fin,
    this.destino,
  });

  final String? id; // identificador en la base de datos
  final String? eventoId; // evento al que se postulo
  final String salon;
  final String fecha;
  final String horario;
  final String puesto;
  final int pagoHora; // en pesos
  final double horas;
  final DateTime? inicio; // cuando empieza el evento
  final DateTime? fin; // cuando termina
  // Cuenta del dueño del salon que recibe la postulacion.
  // null = salon de ejemplo (no hay nadie que la reciba)
  final Cuenta? destino;

  // Copia de la postulacion con los datos nuevos del evento (cuando el
  // dueño lo edita). Devuelve null si el evento ya no busca ese puesto.
  Postulacion? conDatosDe(Evento ev) {
    for (final p in ev.puestos) {
      if (p.profesion.toLowerCase() == puesto.toLowerCase()) {
        return Postulacion(
          id: id,
          eventoId: eventoId,
          salon: salon,
          fecha: Evento.formatoFecha(ev.fecha),
          horario: ev.horario,
          puesto: puesto,
          pagoHora: p.pagoHora,
          horas: ev.horas,
          inicio: ev.inicioDT,
          fin: ev.finDT,
          destino: destino,
        );
      }
    }
    return null;
  }

  // Postulaciones pendientes de la persona (se cargan desde la base de datos)
  static final List<Postulacion> enviadas = [];

  // Avisa a las pantallas que la lista cambio (para que se actualicen)
  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);
  static void notificar() => cambios.value++;

  // Devuelve el motivo por el que NO se puede enviar una postulacion nueva,
  // o null si se puede. Reglas:
  //  1) en un mismo salon solo se puede elegir un puesto
  //  2) no se puede postular a un evento que se superponga en horario con una
  //     postulacion ya enviada o con un evento en el que ya fue aceptado
  // (El servidor vuelve a revisar estas reglas al guardar.)
  static String? motivoBloqueo({
    required String salon,
    DateTime? inicio,
    DateTime? fin,
  }) {
    for (final p in enviadas) {
      if (p.salon == salon) {
        return 'Ya te postulaste a este salón como ${p.puesto}. Solo se puede '
            'elegir un puesto por salón. Si quieres cambiar, cancela esa '
            'postulación.';
      }
    }

    if (inicio == null || fin == null) return null;

    for (final p in enviadas) {
      final i = p.inicio;
      final f = p.fin;
      if (i != null && f != null && _sePisan(inicio, fin, i, f)) {
        return 'Se superpone con tu postulación a ${p.salon} '
            '(${p.fecha}, ${p.horario}). No puedes estar en dos eventos a la '
            'vez.';
      }
    }

    for (final a in EventoAceptado.aceptados) {
      if (_sePisan(inicio, fin, a.inicio, a.fin)) {
        return 'Ya estás confirmado en ${a.salon} (${a.fecha}, ${a.horario}) '
            'en ese mismo horario.';
      }
    }

    return null;
  }

  // Dos eventos se pisan si cada uno empieza antes de que termine el otro
  static bool _sePisan(DateTime ai, DateTime af, DateTime bi, DateTime bf) =>
      ai.isBefore(bf) && bi.isBefore(af);
}