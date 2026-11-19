import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_colors.dart';

// Avisa a los textos que estan dentro de una pantalla con fondo degradado
// (crema arriba, azul abajo) donde esta ese fondo. Lo pone GradientBackground.
class FondoInfo extends InheritedWidget {
  const FondoInfo({
    super.key,
    required this.clave,
    required this.degradado,
    required super.child,
  });

  final GlobalKey clave; // identifica la caja del fondo
  final bool degradado; // false = fondo crema liso, no hay que cambiar nada

  static FondoInfo? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FondoInfo>();

  @override
  bool updateShouldNotify(FondoInfo old) =>
      clave != old.clave || degradado != old.degradado;
}

// Un texto que cambia de color segun lo que tiene detras: sobre el crema se ve
// con el color "oscuro" (azul) y, cuando queda sobre la parte azul del fondo,
// pasa a crema para que siempre se lea. Se actualiza solo al hacer scroll.
// Uso:  TextoSobreFondo(builder: (context, color) => Text('Hola', style: ...copyWith(color: color)))
class TextoSobreFondo extends StatefulWidget {
  const TextoSobreFondo({
    super.key,
    required this.builder,
    this.oscuro = AppColors.navy,
    this.claro = AppColors.cream,
  });

  final Widget Function(BuildContext context, Color color) builder;
  final Color oscuro; // color sobre el fondo crema
  final Color claro; // color sobre el fondo azul

  @override
  State<TextoSobreFondo> createState() => _TextoSobreFondoState();
}

class _TextoSobreFondoState extends State<TextoSobreFondo> {
  // Pasada esta altura del fondo (0 = arriba, 1 = abajo) ya es bastante azul
  static const double _limite = 0.68;

  late Color _color = widget.oscuro;
  FondoInfo? _fondo;
  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fondo = FondoInfo.of(context);
    final nuevo = Scrollable.maybeOf(context)?.position;
    if (nuevo != _scroll) {
      _scroll?.removeListener(_medir);
      _scroll = nuevo;
      _scroll?.addListener(_medir);
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_medir);
    super.dispose();
  }

  void _medir() {
    if (!mounted) return;
    // Si se llama en medio de dibujar la pantalla, se espera a que termine
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
      return;
    }
    var nuevo = widget.oscuro;
    final fondo = _fondo;
    if (fondo != null && fondo.degradado) {
      final cajaFondo = fondo.clave.currentContext?.findRenderObject();
      final cajaTexto = context.findRenderObject();
      if (cajaFondo is RenderBox &&
          cajaTexto is RenderBox &&
          cajaFondo.attached &&
          cajaTexto.attached &&
          cajaFondo.hasSize &&
          cajaTexto.hasSize &&
          cajaFondo.size.height > 0) {
        final y = cajaTexto
            .localToGlobal(Offset(0, cajaTexto.size.height / 2),
                ancestor: cajaFondo)
            .dy;
        if (y / cajaFondo.size.height > _limite) nuevo = widget.claro;
      }
    }
    if (nuevo != _color) setState(() => _color = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    // Despues de dibujar se vuelve a medir (el contenido pudo moverse)
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
    return widget.builder(context, _color);
  }
}