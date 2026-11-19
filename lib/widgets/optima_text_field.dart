import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'texto_sobre_fondo.dart';

OutlineInputBorder _border(double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.navy, width: width),
    );

InputDecoration optimaDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppText.input,
      filled: true,
      fillColor: AppColors.field,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: _border(1),
      enabledBorder: _border(1),
      focusedBorder: _border(2),
    );

Widget _withLabel(String? label, Widget field) {
  if (label == null) return field;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // El nombre del campo cambia a crema si queda sobre la parte azul del fondo
      TextoSobreFondo(
        builder: (context, color) =>
            Text(label, style: AppText.campo.copyWith(color: color)),
      ),
      const SizedBox(height: 6),
      field,
    ],
  );
}

class OptimaTextField extends StatefulWidget {
  const OptimaTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.obscure = false,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
  });

  final String hint;
  final String? label;
  final TextEditingController? controller;
  final bool obscure;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;

  @override
  State<OptimaTextField> createState() => _OptimaTextFieldState();
}

class _OptimaTextFieldState extends State<OptimaTextField> {
  // En los campos de contraseña: true = se ven los puntitos, false = se ve el texto
  late bool _oculta = widget.obscure;

  @override
  Widget build(BuildContext context) {
    var decoracion = optimaDecoration(widget.hint);
    if (widget.obscure) {
      // Ojo tachado = contraseña oculta (al tocarlo se muestra); ojo abierto = visible
      decoracion = decoracion.copyWith(
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            _oculta ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.navy,
            size: 22,
          ),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      );
    }
    return _withLabel(
      widget.label,
      TextField(
        controller: widget.controller,
        obscureText: _oculta,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        keyboardType: widget.keyboardType,
        style: AppText.input.copyWith(color: Colors.black87),
        decoration: decoracion,
      ),
    );
  }
}

class OptimaDropdown<T> extends StatelessWidget {
  const OptimaDropdown({
    super.key,
    required this.hint,
    required this.items,
    this.label,
    this.onChanged,
    this.initialValue,
  });

  final String hint;
  final String? label;
  final List<T> items;
  final T? initialValue; // opcion elegida al abrir (para editar)
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _withLabel(
      label,
      DropdownButtonFormField<T>(
        value: initialValue, // en Flutter nuevo avisa "deprecated", pero funciona
        isExpanded: true,
        icon: const Icon(Icons.arrow_downward, color: Colors.black, size: 20),
        hint: Text(hint, style: AppText.input),
        decoration: optimaDecoration(''),
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text('$e',
                      style: AppText.input.copyWith(color: Colors.black87)),
                ))
            .toList(),
        onChanged: onChanged ?? (_) {},
      ),
    );
  }
}