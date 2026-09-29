import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
      Text(label, style: AppText.label),
      const SizedBox(height: 6),
      field,
    ],
  );
}

class OptimaTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _withLabel(
      label,
      TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: AppText.input.copyWith(color: Colors.black87),
        decoration: optimaDecoration(hint),
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
  });

  final String hint;
  final String? label;
  final List<T> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _withLabel(
      label,
      DropdownButtonFormField<T>(
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