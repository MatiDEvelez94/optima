import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/recorte_foto_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Fotos de un salon: agregar, quitar, elegir la portada y
// volver a encuadrar una foto. Se usa al inscribir y al editar el salon.
// La primera foto es la portada: es la que sale en las tarjetas.
class GrillaFotos extends StatelessWidget {
  const GrillaFotos({
    super.key,
    required this.fotos,
    required this.onChanged,
    this.max = 10,
    this.vacioGrande = false,
  });

  final List<Uint8List> fotos;
  final ValueChanged<List<Uint8List>> onChanged;
  final int max;
  final bool vacioGrande; // sin fotos: muestra un cuadro grande "Agregar"

  Future<Uint8List?> _encuadrar(BuildContext context, Uint8List bytes) {
    return Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => RecorteFotoScreen(bytes: bytes)),
    );
  }

  Future<void> _agregar(BuildContext context) async {
    final picker = ImagePicker();
    final elegidas = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (elegidas.isEmpty) return;
    if (!context.mounted) return;

    final lista = List<Uint8List>.of(fotos);
    final lugar = max - lista.length;
    final messenger = ScaffoldMessenger.of(context);

    for (final archivo in elegidas.take(lugar)) {
      final bytes = await archivo.readAsBytes();
      if (!context.mounted) return;
      // Se agrega directo, sin pantalla de recorte (se puede encuadrar despues con el icono)
      lista.add(bytes);
      onChanged(List<Uint8List>.of(lista));
      if (!context.mounted) return;
    }

    if (elegidas.length > lugar) {
      messenger.showSnackBar(
        SnackBar(content: Text('Solo se pueden agregar hasta $max fotos')),
      );
    }
  }

  Future<void> _reencuadrar(BuildContext context, int i) async {
    final nueva = await _encuadrar(context, fotos[i]);
    if (nueva == null) return;
    final lista = List<Uint8List>.of(fotos)..[i] = nueva;
    onChanged(lista);
  }

  void _quitar(int i) {
    onChanged(List<Uint8List>.of(fotos)..removeAt(i));
  }

  void _hacerPortada(int i) {
    final lista = List<Uint8List>.of(fotos);
    final foto = lista.removeAt(i);
    lista.insert(0, foto);
    onChanged(lista);
  }

  BoxDecoration get _caja => BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy),
      );

  // Amarillo de la portada
  static const Color _amarillo = Color(0xFFF5B800);

  Widget _boton(
    IconData icono,
    VoidCallback onTap, {
    String? tip,
    Color fondo = AppColors.navy,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tip ?? '',
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: fondo,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 14, color: AppColors.cream),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty && vacioGrande) {
      return GestureDetector(
        onTap: () => _agregar(context),
        child: Container(
          height: 170,
          width: double.infinity,
          decoration: _caja,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 56, color: Colors.black87),
              const SizedBox(height: 4),
              Text(
                'Agregar fotos del salón',
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

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var i = 0; i < fotos.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(fotos[i], fit: BoxFit.cover),
              ),
              // Quitar
              Positioned(
                top: 4,
                right: 4,
                child: _boton(Icons.close, () => _quitar(i), tip: 'Quitar'),
              ),
              // Portada
              Positioned(
                top: 4,
                left: 4,
                // Portada: estrella y circulo amarillos. Las demas: estrella vacia azul
                child: i == 0
                    ? _boton(
                        Icons.star,
                        () {},
                        tip: 'Portada',
                        fondo: _amarillo,
                      )
                    : _boton(
                        Icons.star_border,
                        () => _hacerPortada(i),
                        tip: 'Hacer portada',
                      ),
              ),
              // Volver a encuadrar
              Positioned(
                bottom: 4,
                right: 4,
                child: _boton(
                  Icons.crop,
                  () => _reencuadrar(context, i),
                  tip: 'Encuadrar',
                ),
              ),
            ],
          ),
        if (fotos.length < max)
          GestureDetector(
            onTap: () => _agregar(context),
            child: Container(
              decoration: _caja,
              child: const Icon(Icons.add, size: 36, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}