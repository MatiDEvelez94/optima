import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'evento.dart';
import 'user_session.dart';

// Abre un chat de WhatsApp con el telefono de una persona.
class Whatsapp {
  // Para probar con las personas de EJEMPLO (que no tienen telefono real):
  // escribi aca TU numero, 10 numeros: codigo de area + numero, sin 0 ni 15.
  // Ejemplo: '2611234567'. Si queda vacio, las de ejemplo no se pueden
  // contactar. Las personas que se registran de verdad usan el telefono
  // que cargaron al crear su cuenta.
  static const String telefonoDePrueba = '1139373911';

  // Deja el numero como lo pide WhatsApp: 549 + codigo de area + numero.
  // Acepta "2611234567" o "+54 9 2611234567". Devuelve null si no sirve.
  static String? normalizar(String? telefono) {
    final digitos = (telefono ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.length == 10) return '549$digitos';
    if (digitos.length == 13 && digitos.startsWith('549')) return digitos;
    return null;
  }

  // "nicolas lopez" -> "Nicolas Lopez" (primera letra de cada palabra)
  static String _mayusculas(String texto) {
    return texto
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  // Mensaje que le llega a la persona que se postulo
  static String mensajeParaPostulante({
    required String nombre,
    required String profesion,
  }) {
    // Solo el primer nombre, con mayuscula inicial
    final primerNombre = _mayusculas(nombre.trim().split(' ').first);
    final salon = UserSession.salonNombre.trim().isEmpty
        ? 'nuestro salón'
        : _mayusculas(UserSession.salonNombre);
    final evento = Evento.activo;
    final cuando = evento == null
        ? ''
        : ' para el evento del ${Evento.formatoFecha(evento.fecha)} '
            'en el horario de ${evento.horario}';
    final direccion = UserSession.salonDireccion.trim();
    final donde = direccion.isEmpty ? '' : ' El evento es en $direccion.';
    return 'Hola $primerNombre! Te escribo de $salon por Óptima. '
        'Vimos tu postulación como $profesion$cuando.$donde '
        '¿Seguís disponible?';
  }

  // Abre WhatsApp con el chat listo para escribir
  static Future<void> abrir(
    BuildContext context, {
    required String? telefono,
    required String mensaje,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final numero = normalizar(telefono);
    if (numero == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No hay un teléfono válido para contactar a esta persona. '
            '(Personas de ejemplo: ver telefonoDePrueba en whatsapp.dart)',
          ),
        ),
      );
      return;
    }

    final url = Uri.https('wa.me', '/$numero', {'text': mensaje});
    final abrio = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!abrio) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }
}