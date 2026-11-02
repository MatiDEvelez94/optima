// Una persona que trabajo en un evento y la calificacion que le dio el salon
class Resenia {
  const Resenia({
    required this.nombre,
    required this.profesion,
    required this.estrellas,
    this.comentario = '',
  });

  final String comentario; // reseña opcional del salon
  final String nombre;
  final String profesion;
  final double estrellas; // 0 = no se califico, de 0,5 a 5 (con medias)
}

// Un evento que el dueño del salon ya dio por terminado (va al historial)
class EventoFinalizado {
  const EventoFinalizado({
    required this.tipo,
    required this.fecha,
    required this.horario,
    required this.salon,
    required this.costoTotal,
    required this.personas,
  });

  final String tipo;
  final String fecha; // Sabado 22/11/2026
  final String horario; // 19:00hs - 05:00hs
  final String salon;
  final int costoTotal; // lo que costaba el evento completo
  final List<Resenia> personas;
}

// Un evento en el que la persona que busca trabajo ya trabajo (su historial)
class TrabajoRealizado {
  const TrabajoRealizado({
    required this.salon,
    required this.tipo,
    required this.fecha,
    required this.horario,
    required this.direccion,
    required this.puesto,
    required this.pagoHora,
    required this.horas,
    required this.estrellas,
    this.comentario = '',
  });

  final String comentario; // reseña que dejo el salon (opcional)
  final String salon;
  final String tipo;
  final String fecha; // Sabado 22/11/2026
  final String horario; // 19:00hs - 05:00hs
  final String direccion;
  final String puesto;
  final int pagoHora;
  final double horas;
  final double estrellas; // la nota que le dio el salon (0 = sin calificar)

  // Lo que le correspondia cobrar por el evento
  int get pagoTotal => (pagoHora * horas).round();
}

// Un mensaje para quien busca trabajo (por ejemplo "tu solicitud fue
// rechazada"). Se queda en su inicio hasta que toca "Entendido".
class AvisoMozo {
  const AvisoMozo({required this.titulo, required this.detalle});

  final String titulo;
  final String detalle;
}
