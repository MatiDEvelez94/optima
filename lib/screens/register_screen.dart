import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/validadores.dart';
import '../repositories/api_client.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cuadro_errores.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'home_screen.dart';
import 'recorte_foto_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _picker = ImagePicker();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _enviando = false;
  Uint8List? _photoBytes;
  String? _cvName;
  Uint8List? _cvBytes;
  List<String> _errores = [];

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final original = await picked.readAsBytes();
    if (!mounted) return;
    // Pantalla para encuadrar la foto a gusto (circulo guia)
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => RecorteFotoScreen(bytes: original, circular: true),
      ),
    );
    if (bytes == null || !mounted) return;
    setState(() => _photoBytes = bytes);
  }

  Future<void> _pickCv() async {
    // Sin filtro de extension: en el iPhone el filtro por tipo deja los
    // archivos en gris y no se pueden elegir. El control de que sea PDF
    // se hace despues, mirando el nombre del archivo.
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    final file = files.first;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El currículum tiene que ser un archivo PDF')),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _cvName = file.name;
      _cvBytes = bytes;
    });
  }

  // Revisa los datos; si algo falla, muestra que hay que corregir
  Future<void> _continue() async {
    if (_enviando) return;
    final correo = _correoCtrl.text.trim().toLowerCase();
    final errores = <String>[];

    if (_nombreCtrl.text.trim().isEmpty) errores.add('Escribe tu nombre');
    if (_apellidoCtrl.text.trim().isEmpty) errores.add('Escribe tu apellido');
    if (!Validadores.dni(_dniCtrl.text)) {
      errores.add('El DNI debe tener 7 u 8 números');
    }
    if (!Validadores.correo(correo)) {
      errores.add('Escribe un correo válido, por ejemplo nombre@gmail.com');
    }
    if (!Validadores.password(_passCtrl.text)) {
      errores.add('La contraseña debe tener al menos 6 caracteres');
    }
    if (!Validadores.telefono(_telefonoCtrl.text.trim())) {
      errores.add(
        'El teléfono debe tener 10 números: código de área y número, '
        'sin 0 ni 15',
      );
    }

    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }

    setState(() {
      _errores = [];
      _enviando = true;
    });
    try {
      // El servidor guarda la cuenta en la base de datos
      await AuthRepository.registrarMozo(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        dni: _dniCtrl.text.trim(),
        correo: correo,
        password: _passCtrl.text,
        telefono: _telefonoCtrl.text.trim(),
        foto: _photoBytes,
        cvNombre: _cvName ?? '',
        cvBytes: _cvBytes,
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errores = [e.mensaje];
        _enviando = false;
      });
      return;
    }
    if (!mounted) return;

    // La persona que busca trabajo no necesita aprobacion: va directo al inicio
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _dniCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  // Selector del curriculum (solo PDF)
  Widget _buildCvPicker() {
    final hasCv = _cvName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Currículum (PDF)', style: AppText.campo),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickCv,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.navy),
            ),
            child: Row(
              children: [
                Icon(
                  hasCv ? Icons.picture_as_pdf : Icons.upload_file,
                  color: AppColors.navy,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasCv ? _cvName! : 'Adjuntar currículum (solo PDF)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.input.copyWith(
                      color: hasCv ? Colors.black87 : AppColors.hint,
                    ),
                  ),
                ),
                if (hasCv)
                  GestureDetector(
                    onTap: () => setState(() {
                      _cvName = null;
                      _cvBytes = null;
                    }),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.navy,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        plano: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Crea tu cuenta', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 10),

              // Foto de perfil (se toca para elegir un archivo o foto)
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.navy,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.field,
                          backgroundImage: _photoBytes != null
                              ? MemoryImage(_photoBytes!)
                              : null,
                          child: _photoBytes == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.hint,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cream,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              OptimaTextField(
                label: 'Nombre',
                hint: '...',
                controller: _nombreCtrl,
              ),
              const SizedBox(height: 14),
              OptimaTextField(
                label: 'Apellido',
                hint: '...',
                controller: _apellidoCtrl,
              ),
              const SizedBox(height: 14),

              Text('DNI', style: AppText.campo),
              const SizedBox(height: 6),
              TextField(
                controller: _dniCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: AppText.input.copyWith(color: Colors.black87),
                decoration: optimaDecoration('...'),
              ),
              const SizedBox(height: 14),

              OptimaTextField(
                label: 'Correo electrónico',
                hint: 'maildeejemplo@gmail.com',
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              OptimaTextField(
                label: 'Contraseña',
                hint: 'mínimo 6 caracteres',
                controller: _passCtrl,
                obscure: true,
              ),
              const SizedBox(height: 14),

              Text('Teléfono', style: AppText.campo),
              const SizedBox(height: 6),
              Row(
                children: [
                  Image.asset('assets/icons/ar.png', width: 32),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 90,
                    child: OptimaTextField(hint: '+54 9', readOnly: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: AppText.input.copyWith(color: Colors.black87),
                      decoration: optimaDecoration('2611234567'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildCvPicker(),

              CuadroErrores(errores: _errores),

              const SizedBox(height: 28),
              Center(
                child: OptimaLink(
                  text: _enviando ? 'Creando cuenta...' : 'Continuar',
                  onPressed: _continue,
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