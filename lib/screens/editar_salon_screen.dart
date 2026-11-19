import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_session.dart';
import '../repositories/api_client.dart';
import '../repositories/cuenta_repository.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cuadro_errores.dart';
import '../widgets/gradient_background.dart';
import '../widgets/grilla_fotos.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';

// Editar los datos del salon: nombre, direccion, capacidad y fotos
class EditarSalonScreen extends StatefulWidget {
  const EditarSalonScreen({super.key});

  @override
  State<EditarSalonScreen> createState() => _EditarSalonScreenState();
}

class _EditarSalonScreenState extends State<EditarSalonScreen> {
  late final _nombreCtrl = TextEditingController(text: UserSession.salonNombre);
  late final _direccionCtrl =
      TextEditingController(text: UserSession.salonDireccion);
  late final _capacidadCtrl =
      TextEditingController(text: UserSession.salonCapacidad);
  late final List<Uint8List> _photos = List.of(UserSession.salonFotos);
  List<String> _errores = [];
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final nombre = _nombreCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final capacidad = _capacidadCtrl.text.trim();

    final errores = <String>[];
    if (nombre.isEmpty) errores.add('Escribe el nombre del salón');
    if (direccion.isEmpty) errores.add('Escribe la dirección');
    if (capacidad.isEmpty || (int.tryParse(capacidad) ?? 0) < 1) {
      errores.add('Escribe la capacidad (cantidad de personas)');
    }
    if (_photos.isEmpty) errores.add('Agrega al menos una foto del salón');
    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }

    setState(() {
      _errores = [];
      _guardando = true;
    });
    try {
      // Se guarda en la base de datos
      await CuentaRepository.guardarSalon(
        nombre: nombre,
        direccion: direccion,
        capacidad: capacidad,
        fotos: List.of(_photos),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errores = [e.mensaje];
        _guardando = false;
      });
      return;
    }
    if (!mounted) return;

    UserSession.salonNombre = nombre;
    UserSession.salonDireccion = direccion;
    UserSession.salonCapacidad = capacidad;
    UserSession.salonFotos = List.of(_photos);
    final solicitud = UserSession.solicitudSalon;
    if (solicitud != null) {
      solicitud.salonNombre = nombre;
      solicitud.direccion = direccion;
      solicitud.capacidad = capacidad;
      solicitud.fotos = List.of(_photos);
    }
    final mensajes = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensajes.showSnackBar(
      const SnackBar(content: Text('Salón actualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Editar salón', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 12),
              OptimaTextField(
                label: 'Nombre del Salón',
                hint: 'texto',
                controller: _nombreCtrl,
              ),
              const SizedBox(height: 14),
              OptimaTextField(
                label: 'Dirección',
                hint: 'texto',
                controller: _direccionCtrl,
              ),
              const SizedBox(height: 14),
              Text('Capacidad', style: AppText.campo),
              const SizedBox(height: 6),
              TextField(
                controller: _capacidadCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.input.copyWith(color: Colors.black87),
                decoration: optimaDecoration('cantidad de personas'),
              ),
              const SizedBox(height: 20),
              Text('Fotos', style: AppText.campo),
              const SizedBox(height: 6),
              GrillaFotos(
                fotos: _photos,
                onChanged: (nuevas) => setState(() {
                  _photos
                    ..clear()
                    ..addAll(nuevas);
                }),
              ),
              CuadroErrores(errores: _errores),
              const SizedBox(height: 24),
              Center(
                child: OptimaLink(
                  text: _guardando ? 'Guardando...' : 'Guardar',
                  onPressed: _guardar,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}