import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cuenta.dart';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cuadro_errores.dart';
import '../widgets/gradient_background.dart';
import '../widgets/grilla_fotos.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'request_sent_screen.dart';

class SalonDataScreen extends StatefulWidget {
  const SalonDataScreen({super.key});

  @override
  State<SalonDataScreen> createState() => _SalonDataScreenState();
}

class _SalonDataScreenState extends State<SalonDataScreen> {
  final _nombreCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  final List<Uint8List> _photos = [];
  List<String> _errores = [];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _addressCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  // Abre la direccion escrita en Google Maps para que el dueño la verifique
  Future<void> _openMaps() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la dirección primero')),
      );
      return;
    }
    final url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // Guarda los datos, crea la cuenta y manda la solicitud para que el
  // administrador la revise
  void _enviarSolicitud() {
    // Revisa los datos; si algo falla, muestra que hay que corregir
    final errores = <String>[];
    if (_nombreCtrl.text.trim().isEmpty) {
      errores.add('Escribe el nombre del salón');
    }
    if (_addressCtrl.text.trim().length < 5) {
      errores.add('Escribe la dirección completa (calle, número y ciudad)');
    }
    if ((int.tryParse(_capacidadCtrl.text.trim()) ?? 0) < 1) {
      errores.add('La capacidad tiene que ser mayor a 0');
    }
    if (_photos.isEmpty) {
      errores.add('Agrega al menos una foto del salón');
    }
    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }

    UserSession.salonNombre = _nombreCtrl.text.trim();
    UserSession.salonDireccion = _addressCtrl.text.trim();
    UserSession.salonCapacidad = _capacidadCtrl.text.trim();
    UserSession.salonFotos = List.of(_photos);
    UserSession.rol = 'salon';
    UserSession.logueado = true;

    final solicitud = SolicitudSalon(
      nombreDueno: UserSession.nombre,
      apellidoDueno: UserSession.apellido,
      correo: UserSession.correo,
      telefono: UserSession.telefono,
      dni: UserSession.dni,
      salonNombre: UserSession.salonNombre,
      direccion: UserSession.salonDireccion,
      capacidad: UserSession.salonCapacidad,
      fotos: List.of(_photos),
      fecha: DateTime.now(),
    );
    SolicitudSalon.todas.add(solicitud);
    UserSession.solicitudSalon = solicitud;
    SolicitudSalon.notificar();
    Cuenta.crearDesdeSesion(solicitud: solicitud);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestSentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Datos del Salón', style: AppText.title)),
              const Divider(color: Colors.black87, indent: 20, endIndent: 20),
              const SizedBox(height: 24),
              OptimaTextField(
                label: 'Nombre del Salón',
                hint: 'texto',
                controller: _nombreCtrl,
              ),
              const SizedBox(height: 20),
              OptimaTextField(
                label: 'Dirección',
                hint: 'calle, número, ciudad',
                controller: _addressCtrl,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OptimaButton(
                  text: 'Ver en Google Maps',
                  filled: false,
                  onPressed: _openMaps,
                ),
              ),
              const SizedBox(height: 20),
              Text('Capacidad', style: AppText.campo),
              const SizedBox(height: 6),
              TextField(
                controller: _capacidadCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.input.copyWith(color: Colors.black87),
                decoration: optimaDecoration('cantidad de personas'),
              ),
              const SizedBox(height: 24),
              GrillaFotos(
                fotos: _photos,
                vacioGrande: true,
                onChanged: (nuevas) => setState(() {
                  _photos
                    ..clear()
                    ..addAll(nuevas);
                }),
              ),
              CuadroErrores(errores: _errores),
              const SizedBox(height: 40),
              Center(
                child: OptimaLink(
                  text: 'Continuar',
                  onPressed: _enviarSolicitud,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
