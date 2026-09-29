import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
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
  // Cantidad máxima de fotos que se pueden subir (cambiá este número si querés)
  static const int _maxPhotos = 10;

  final _picker = ImagePicker();
  final List<Uint8List> _photos = [];

  Future<void> _addPhotos() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;

    final remaining = _maxPhotos - _photos.length;
    final newBytes = <Uint8List>[];
    for (final file in picked.take(remaining)) {
      newBytes.add(await file.readAsBytes());
    }
    if (!mounted) return;
    setState(() => _photos.addAll(newBytes));

    if (picked.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solo se pueden agregar hasta $_maxPhotos fotos')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  BoxDecoration get _boxDecoration => BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy),
      );

  Widget _buildPhotosArea() {
    // Sin fotos: cuadrado grande "Agregar fotos"
    if (_photos.isEmpty) {
      return GestureDetector(
        onTap: _addPhotos,
        child: Container(
          height: 170,
          width: double.infinity,
          decoration: _boxDecoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 56, color: Colors.black87),
              const SizedBox(height: 4),
              Text(
                'Agregar fotos del salon',
                style: AppText.input.copyWith(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Con fotos: grilla de miniaturas + cuadradito "+" para seguir agregando
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var i = 0; i < _photos.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_photos[i], fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removePhoto(i),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (_photos.length < _maxPhotos)
          GestureDetector(
            onTap: _addPhotos,
            child: Container(
              decoration: _boxDecoration,
              child: const Icon(Icons.add, size: 36, color: Colors.black87),
            ),
          ),
      ],
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
              Center(child: Text('Datos del Salon', style: AppText.title)),
              const Divider(color: Colors.black87, indent: 20, endIndent: 20),
              const SizedBox(height: 24),
              const OptimaTextField(label: 'Nombre del Salon', hint: 'texto'),
              const SizedBox(height: 20),
              const OptimaTextField(label: 'Direccion', hint: 'texto'),
              const SizedBox(height: 20),
              Text('Capacidad', style: AppText.label),
              const SizedBox(height: 6),
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.input.copyWith(color: Colors.black87),
                decoration: optimaDecoration('cantidad de personas'),
              ),
              const SizedBox(height: 24),
              _buildPhotosArea(),
              const SizedBox(height: 40),
              Center(
                child: OptimaLink(
                  text: 'Continuar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RequestSentScreen(),
                      ),
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