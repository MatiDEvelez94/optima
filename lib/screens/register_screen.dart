import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'role_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _picker = ImagePicker();
  Uint8List? _photoBytes;

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Crea tu cuenta', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 20),

              // Foto de perfil (se toca para elegir un archivo o foto)
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 57,
                        backgroundColor: AppColors.navy,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.field,
                          backgroundImage: _photoBytes != null
                              ? MemoryImage(_photoBytes!)
                              : null,
                          child: _photoBytes == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
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
              const SizedBox(height: 24),

              const OptimaTextField(label: 'Nombre', hint: '...'),
              const SizedBox(height: 20),
              const OptimaTextField(label: 'Apellido', hint: '...'),
              const SizedBox(height: 20),
              const OptimaTextField(
                label: 'Correo electronico',
                hint: 'maildeejemplo@gmail.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              const OptimaTextField(
                label: 'Contraseña',
                hint: '...',
                obscure: true,
              ),
              const SizedBox(height: 20),

              Text('Telefono', style: AppText.label),
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
                  const Expanded(
                    child: OptimaTextField(
                      hint: '...',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('DNI', style: AppText.label),
              const SizedBox(height: 6),
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.input.copyWith(color: Colors.black87),
                decoration: optimaDecoration('...'),
              ),

              const SizedBox(height: 50),
              Center(
                child: OptimaLink(
                  text: 'Continuar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}