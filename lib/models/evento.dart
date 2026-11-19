import 'package:flutter/material.dart';
import 'cuenta.dart';

// Un puesto que busca el evento: profesion, cuantas personas y pago por hora
class Puesto {
  const Puesto({
    required this.profesion,
    required this.cantidad,
    required this.pagoHora,
  });

  final String profesion;
  final int cantidad;
  final int pagoHora; // en pesos, por persona y por hora

  // Mozo x8 - $5.000/h
  String get etiqueta =>
      '$profesion x$cantidad - ${Evento.formatoDinero(pagoHora)}/h';
}

// Una persona que el dueño del salon confirmo para el evento
class Confirmado {
  Confirmado({required this.nombre, required this.profesion, this.cuenta});

  final String nombre;
  final String profesion;
  final Cuenta? cuenta; // null = persona de ejemplo (sin cuenta real)
}

class Evento {
  Evento({
    this.id,
    required this.tipo,
    required this.fecha,
    required this.inicio,
    required this.fin,
    required this.invitados,
    required this.puestos,
    this.notas = '',
  });

  // Identificador del evento en la base de datos (null = todavia no se guardo)
  final String? id;

  // Estos datos se pueden editar despues de publicar el evento
  String tipo;
  DateTime fecha;
  TimeOfDay inicio;
  TimeOfDay fin;
  int invitados; // 0 = no indicado
  List<Puesto> puestos;
  String notas;

  // Personas confirmadas para este evento
  final List<Confirmado> confirmados = [];
  // Nombres de las personas de EJEMPLO que ya fueron confirmadas o rechazadas
  final Set<String> decididos = {};

  // Horas que dura el evento
  double get horas => calcularHoras(inicio, fin);

  // Cuando empieza y cuando termina, como fecha y hora completas
  DateTime get inicioDT =>
      DateTime(fecha.year, fecha.month, fecha.day, inicio.hour, inicio.minute);
  DateTime get finDT =>
      inicioDT.add(Duration(minutes: (horas * 60).round()));

  // 17:30hs - 05:30hs
  String get horario => '${formatoHora(inicio)}hs - ${formatoHora(fin)}hs';

  // Cuantas personas pidio el evento para ese puesto
  int cupoDe(String profesion) => puestos
      .where((p) => p.profesion.toLowerCase() == profesion.toLowerCase())
      .fold<int>(0, (suma, p) => suma + p.cantidad);

  // Cuantas personas ya se confirmaron para ese puesto
  int confirmadosDe(String profesion) => confirmados
      .where((c) => c.profesion.toLowerCase() == profesion.toLowerCase())
      .length;

  // Lugares que todavia quedan para ese puesto (pedidos menos confirmados)
  int restantesDe(String profesion) {
    final r = cupoDe(profesion) - confirmadosDe(profesion);
    return r < 0 ? 0 : r;
  }

  // Puestos que todavia tienen lugares, con la cantidad que falta
  List<Puesto> get puestosAbiertos => puestos
      .where((p) => restantesDe(p.profesion) > 0)
      .map(
        (p) => Puesto(
          profesion: p.profesion,
          cantidad: restantesDe(p.profesion),
          pagoHora: p.pagoHora,
        ),
      )
      .toList();

  // true cuando ya se confirmo a todas las personas que pidio el evento
  bool get completo => puestosAbiertos.isEmpty;

  // Mozo x1 - $2.000/h  (o "Mozo (completo)" si ya no quedan lugares)
  String etiquetaRestante(Puesto p) {
    final falta = restantesDe(p.profesion);
    if (falta == 0) return '${p.profesion} (completo)';
    return '${p.profesion} x$falta - ${formatoDinero(p.pagoHora)}/h';
  }

  // Costo total: suma de (cantidad x horas x pago por hora) de cada puesto
  int get costoTotal => puestos.fold<int>(
        0,
        (suma, p) => suma + (p.cantidad * horas * p.pagoHora).round(),
      );

  // Si el horario de fin es menor al de inicio, el evento termina al dia
  // siguiente (por ejemplo 19:00 a 5:00 = 10 horas)
  static double calcularHoras(TimeOfDay inicio, TimeOfDay fin) {
    var minutos =
        (fin.hour * 60 + fin.minute) - (inicio.hour * 60 + inicio.minute);
    if (minutos <= 0) minutos += 24 * 60;
    return minutos / 60;
  }

  // ---------- formatos para mostrar en pantalla ----------

  static const _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // Sabado 22/11/2026
  static String formatoFecha(DateTime d) =>
      '${_dias[d.weekday - 1]} ${d.day}/${d.month}/${d.year}';

  // 19:00
  static String formatoHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // 4 / 4,5 (para mostrar estrellas)
  static String formatoEstrellas(double e) => e == e.roundToDouble()
      ? '${e.round()}'
      : e.toStringAsFixed(1).replaceAll('.', ',');

  // 10 hs / 10,5 hs
  static String formatoHoras(double h) {
    final texto = h == h.roundToDouble() ? '${h.round()}' : h.toStringAsFixed(1);
    return '${texto.replaceAll('.', ',')} hs';
  }

  // 480000 -> $480.000
  static String formatoDinero(num valor) {
    final s = valor.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '\$$buf';
  }

  // Evento activo del salon que inicio sesion (se carga desde la base de datos)
  static final List<Evento> publicados = [];

  // Por ahora un salon tiene un solo evento activo: el ultimo publicado
  static Evento? get activo => publicados.isEmpty ? null : publicados.last;

  static void eliminarActivo() => publicados.clear();
}