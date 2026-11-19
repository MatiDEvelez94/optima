import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';

// Pantalla para encuadrar una foto: se mueve y se hace zoom con los dedos
// (o el mouse) y se guarda solo lo que queda dentro del recuadro.
// Vuelve con los bytes de la foto recortada, o null si se descarta la foto.
// Por defecto el recuadro es 4:3 (fotos del salon). Con circular: true es
// cuadrado y muestra un circulo de guia (foto de perfil).
// No usa librerias externas, asi que funciona igual en Chrome, Android e iOS.
class RecorteFotoScreen extends StatefulWidget {
  const RecorteFotoScreen({
    super.key,
    required this.bytes,
    this.circular = false,
  });

  final Uint8List bytes;
  final bool circular; // true = foto de perfil (cuadrado con circulo guia)

  @override
  State<RecorteFotoScreen> createState() => _RecorteFotoScreenState();
}

class _RecorteFotoScreenState extends State<RecorteFotoScreen> {
  // Proporcion del recuadro (ancho / alto): 4:3 horizontal, o 1:1 si es de perfil
  double get _proporcion => widget.circular ? 1.0 : 4 / 3;

  final _controller = TransformationController();
  final _clave = GlobalKey();
  Size? _tamanoFoto; // ancho y alto reales de la foto
  bool _guardando = false;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _leerTamano();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leerTamano() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      final tam = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      if (!mounted) return;
      setState(() => _tamanoFoto = tam);
    } catch (_) {
      // Si no se puede leer, se usa la foto tal cual
      if (mounted) Navigator.pop(context, widget.bytes);
    }
  }

  Future<void> _recortar() async {
    final contexto = _clave.currentContext;
    if (contexto == null || _guardando) return;
    setState(() => _guardando = true);
    try {
      final caja = contexto.findRenderObject() as RenderRepaintBoundary;
      final ancho = caja.size.width;
      final lado = widget.circular ? 600 : 1200; // ancho final en pixeles
      final imagen = await caja.toImage(pixelRatio: lado / ancho);
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      if (datos == null) {
        Navigator.pop(context, widget.bytes);
        return;
      }
      Navigator.pop(context, datos.buffer.asUint8List());
    } catch (_) {
      if (mounted) Navigator.pop(context, widget.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = _tamanoFoto;
    final pantalla = MediaQuery.of(context).size.width;
    final ancho = (pantalla - 48).clamp(200.0, 460.0);
    final alto = ancho / _proporcion;

    return Scaffold(
      body: GradientBackground(
        plano: true,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.navy),
              ),
            ),
            Text('Encuadrar foto', style: AppText.title.copyWith(fontSize: 26)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.circular
                    ? 'Mueve la foto y haz zoom (pellizcando o con la rueda del '
                        'mouse) para dejar tu cara dentro del círculo.'
                    : 'Mueve la foto y haz zoom (pellizcando o con la rueda del '
                        'mouse) para dejar lo importante dentro del recuadro.',
                textAlign: TextAlign.center,
                style: AppText.input.copyWith(color: AppColors.navy),
              ),
            ),
            const SizedBox(height: 20),
            if (foto == null)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(color: AppColors.navy),
              )
            else
              _recuadro(foto, ancho, alto),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  OptimaButton(
                    text: _guardando ? 'Guardando...' : 'Recortar y usar',
                    onPressed: _recortar,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(context, widget.bytes),
                    child: Text(
                      'Usar sin recortar',
                      style: AppText.link.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _recuadro(Size foto, double ancho, double alto) {
    // Tamaño de la foto "cubriendo" el recuadro (como BoxFit.cover)
    final relacion = foto.width / foto.height;
    double cubreAncho;
    double cubreAlto;
    if (relacion > _proporcion) {
      cubreAlto = alto;
      cubreAncho = alto * relacion;
    } else {
      cubreAncho = ancho;
      cubreAlto = ancho / relacion;
    }

    // Arranca centrada
    if (!_inicializado) {
      _controller.value = Matrix4.translationValues(
        -(cubreAncho - ancho) / 2,
        -(cubreAlto - alto) / 2,
        0,
      );
      _inicializado = true;
    }

    return Container(
      width: ancho,
      height: alto,
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: AppColors.navy, width: 2),
        shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circular ? null : BorderRadius.circular(4),
      ),
      child: RepaintBoundary(
        key: _clave,
        child: InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 1,
          maxScale: 6,
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox(
            width: cubreAncho,
            height: cubreAlto,
            child: Image.memory(
              widget.bytes,
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}