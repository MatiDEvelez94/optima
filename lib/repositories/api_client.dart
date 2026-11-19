import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Error "bonito" para mostrarle a la persona (ya viene en español del servidor)
class ApiError implements Exception {
  ApiError(this.mensaje, [this.codigo]);

  final String mensaje;
  final int? codigo;

  @override
  String toString() => mensaje;
}

// Habla con el servidor Flask del proyecto (carpeta backend).
//
// - En la web (iPhone por Safari) la app se abre desde el mismo servidor
//   (http://IP:5001/m/), asi que la direccion y la cookie de sesion son
//   las mismas y no hace falta configurar nada.
// - En un celular con la app instalada (Android) hay que poner abajo la IP
//   de la PC en [servidorApp].
class ApiClient {
  // Solo se usa cuando la app NO corre en el navegador
  static const String servidorApp = 'http://192.168.10.152:5001';

  static String get base => kIsWeb ? Uri.base.origin : servidorApp;

  static final http.Client _cliente = http.Client();
  // Cookie de sesion (solo hace falta guardarla a mano fuera del navegador)
  static String _cookie = '';

  static Future<Map<String, dynamic>> get(String ruta) =>
      _pedir('GET', ruta);

  static Future<Map<String, dynamic>> post(
    String ruta, [
    Map<String, dynamic>? cuerpo,
  ]) =>
      _pedir('POST', ruta, cuerpo ?? {});

  static Future<Map<String, dynamic>> put(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) =>
      _pedir('PUT', ruta, cuerpo);

  static Future<Map<String, dynamic>> delete(String ruta) =>
      _pedir('DELETE', ruta);

  static Future<Map<String, dynamic>> _pedir(
    String metodo,
    String ruta, [
    Map<String, dynamic>? cuerpo,
  ]) async {
    final uri = Uri.parse('$base$ruta');
    final cabeceras = <String, String>{
      'Content-Type': 'application/json',
      if (_cookie.isNotEmpty && !kIsWeb) 'Cookie': _cookie,
    };
    try {
      final pedido = http.Request(metodo, uri)..headers.addAll(cabeceras);
      if (cuerpo != null) pedido.body = jsonEncode(cuerpo);
      final enviado = await _cliente.send(pedido).timeout(
            const Duration(seconds: 60),
          );
      final resp = await http.Response.fromStream(enviado);

      final sc = resp.headers['set-cookie'];
      if (sc != null && sc.isNotEmpty) _cookie = sc.split(';').first;

      Map<String, dynamic> datos = {};
      try {
        final d = jsonDecode(utf8.decode(resp.bodyBytes));
        if (d is Map<String, dynamic>) datos = d;
      } catch (_) {}

      if (resp.statusCode >= 400 || datos['ok'] == false) {
        throw ApiError(
          (datos['error'] as String?) ?? 'Error del servidor (${resp.statusCode})',
          resp.statusCode,
        );
      }
      return datos;
    } on ApiError {
      rethrow;
    } on TimeoutException {
      throw ApiError('El servidor tardó demasiado en responder');
    } catch (_) {
      throw ApiError(
        'No se pudo conectar con el servidor. Revisá que esté prendido '
        'y que el celular esté en la misma red.',
      );
    }
  }

  // Descarga una foto o un PDF guardado en el servidor (o decodifica un data URL)
  static Future<Uint8List?> bytesDe(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('data:')) {
        return base64Decode(url.substring(url.indexOf(',') + 1));
      }
      final destino = url.startsWith('http') ? url : '$base$url';
      final r = await _cliente.get(Uri.parse(destino));
      if (r.statusCode != 200) return null;
      return r.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  // Convierte bytes en el texto que espera el servidor para guardar el archivo
  static String dataUrl(Uint8List bytes, {String? mime}) {
    final tipo = mime ?? _detectarTipo(bytes);
    return 'data:$tipo;base64,${base64Encode(bytes)}';
  }

  static String _detectarTipo(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 4 && b[0] == 0x25 && b[1] == 0x50) return 'application/pdf';
    if (b.length > 12 && b[8] == 0x57 && b[9] == 0x45) return 'image/webp';
    return 'image/jpeg';
  }
}