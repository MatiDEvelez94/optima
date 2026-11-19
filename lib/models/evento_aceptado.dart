import 'package:flutter/services.dart';

// Un evento en el que la persona que busca trabajo fue aceptada:
// a donde tiene que ir, de que va a trabajar y cuanto se le paga.
class EventoAceptado {
  const EventoAceptado({
    required this.salon,
    required this.tipo,
    required this.fecha,
    required this.horario,
    required this.inicio,
    required this.fin,
    required this.direccion,
    required this.size,
    required this.puesto,
    required this.pagoHora,
    required this.horas,
    required this.puestosEvento,
    this.image = 'assets/images/salon.jpg',
    this.imageBytes,
    this.origen,
  });

  final String salon;
  final String tipo;
  final String fecha; // Sabado 28/11
  final String horario; // 17:30hs - 5:30hs
  final DateTime inicio; // cuando empieza (para no superponer eventos)
  final DateTime fin; // cuando termina
  final String direccion;
  final String size; // 250 personas
  final String puesto; // puesto asignado a esta persona
  final int pagoHora; // en pesos
  final double horas; // duracion del evento
  final List<String> puestosEvento; // todo lo que busca el evento
  final String image;
  final Uint8List? imageBytes; // foto subida por el salon (si hay)
  final Object? origen; // el Evento del salon que lo origino

  // Lo que cobraria por el evento completo
  int get pagoEstimado => (pagoHora * horas).round();

  // Eventos donde la persona fue confirmada (se cargan desde la base de datos)
  static final List<EventoAceptado> aceptados = [];
}