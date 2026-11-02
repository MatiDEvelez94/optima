import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Fotos en un recuadro que se mueve de derecha a izquierda:
// con flechitas a los costados y deslizando con el dedo (o arrastrando con
// el mouse). Recibe una lista de imagenes, asi que sirve igual para fotos
// guardadas en la app o, mas adelante, para fotos que vengan de internet.
class CarruselFotos extends StatefulWidget {
  const CarruselFotos({super.key, required this.fotos, this.alto = 200});

  final List<ImageProvider> fotos;
  final double alto;

  @override
  State<CarruselFotos> createState() => _CarruselFotosState();
}

class _CarruselFotosState extends State<CarruselFotos> {
  final _controller = PageController();
  int _pagina = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ir(int pagina) {
    _controller.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.fotos.length;

    if (total == 0) {
      return Container(
        height: widget.alto,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.image_outlined, size: 48, color: AppColors.hint),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.alto,
        width: double.infinity,
        child: Stack(
          children: [
            // Las fotos (se mueven con el dedo o arrastrando con el mouse)
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (i) => setState(() => _pagina = i),
                itemBuilder: (context, i) => Image(
                  image: widget.fotos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            if (total > 1) ...[
              // Flechas: no aparece la de la izquierda en la primera foto ni
              // la de la derecha en la ultima
              if (_pagina > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Flecha(
                    icono: Icons.chevron_left,
                    onTap: () => _ir(_pagina - 1),
                  ),
                ),
              if (_pagina < total - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: _Flecha(
                    icono: Icons.chevron_right,
                    onTap: () => _ir(_pagina + 1),
                  ),
                ),
              // Contador: 2 de 5
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_pagina + 1} de $total',
                    style: AppText.eventText.copyWith(fontSize: 11),
                  ),
                ),
              ),
              // Puntitos
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < total; i++)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _pagina
                                  ? AppColors.cream
                                  : AppColors.cream.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({required this.icono, required this.onTap});

  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.65),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: AppColors.cream),
        ),
      ),
    );
  }
}