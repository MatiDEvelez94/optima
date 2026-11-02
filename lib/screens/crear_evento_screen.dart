import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/evento.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'se_busca_screen.dart';

// Pone las barras solas mientras se escribe la fecha: 22112026 -> 22/11/2026
class _FechaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);

    final buf = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digitos[i]);
    }
    final texto = buf.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

// Paso 1 de 2: datos generales del evento
// Si recibe un evento (editar), los campos vienen completos y se modifica ese
// mismo evento en vez de crear uno nuevo.
class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key, this.editar});

  final Evento? editar;

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  static const _tipos = [
    'Casamiento',
    'Cumpleaños',
    'Corporativo',
    'Egresados',
    'Otro',
  ];

  final _tipoOtroCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _inicioCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _invitadosCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String? _tipo;

  bool get _editando => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    if (e == null) return;
    // Completa los campos con los datos actuales del evento
    if (_tipos.contains(e.tipo)) {
      _tipo = e.tipo;
    } else {
      _tipo = 'Otro';
      _tipoOtroCtrl.text = e.tipo;
    }
    _fechaCtrl.text = '${e.fecha.day.toString().padLeft(2, '0')}/'
        '${e.fecha.month.toString().padLeft(2, '0')}/${e.fecha.year}';
    _inicioCtrl.text = Evento.formatoHora(e.inicio);
    _finCtrl.text = Evento.formatoHora(e.fin);
    _invitadosCtrl.text = e.invitados > 0 ? '${e.invitados}' : '';
    _notasCtrl.text = e.notas;
  }

  @override
  void dispose() {
    _tipoOtroCtrl.dispose();
    _fechaCtrl.dispose();
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    _invitadosCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  // ---------- lectura de lo que escribio la persona ----------

  // "22/11/2026" -> fecha (o null si no es una fecha real, ej: 31/02/2026)
  DateTime? _parseFecha(String texto) {
    final partes = texto.trim().split('/');
    if (partes.length != 3 || partes[2].length != 4) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);
    if (dia == null || mes == null || anio == null) return null;
    final fecha = DateTime(anio, mes, dia);
    if (fecha.day != dia || fecha.month != mes || fecha.year != anio) {
      return null;
    }
    return fecha;
  }

  // "19:00" o "5:00" -> hora (o null si no es valida)
  TimeOfDay? _parseHora(String texto) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(texto.trim());
    if (m == null) return null;
    final hora = int.parse(m.group(1)!);
    final minuto = int.parse(m.group(2)!);
    if (hora > 23 || minuto > 59) return null;
    return TimeOfDay(hour: hora, minute: minuto);
  }

  DateTime? get _fecha => _parseFecha(_fechaCtrl.text);
  TimeOfDay? get _inicio => _parseHora(_inicioCtrl.text);
  TimeOfDay? get _fin => _parseHora(_finCtrl.text);

  // Texto con la duracion; avisa si el evento termina al dia siguiente
  String? get _duracionTexto {
    final inicio = _inicio;
    final fin = _fin;
    if (inicio == null || fin == null || inicio == fin) return null;
    final base = 'Duración: ${Evento.formatoHoras(Evento.calcularHoras(inicio, fin))}';
    final alDiaSiguiente =
        fin.hour * 60 + fin.minute < inicio.hour * 60 + inicio.minute;
    return alDiaSiguiente ? '$base (termina al día siguiente)' : base;
  }

  // ---------- acciones ----------

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void _continuar() {
    final tipo = _tipo == 'Otro' ? _tipoOtroCtrl.text.trim() : _tipo;
    final fecha = _fecha;
    final inicio = _inicio;
    final fin = _fin;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    String? error;
    if (tipo == null || tipo.isEmpty) {
      error = _tipo == 'Otro'
          ? 'Escribe el tipo de evento'
          : 'Elige el tipo de evento';
    } else if (fecha == null) {
      error = 'Escribe la fecha así: 22/11/2026';
    } else if (fecha.isBefore(hoySinHora) &&
        !(_editando && fecha == widget.editar!.fecha)) {
      error = 'La fecha no puede ser anterior a hoy';
    } else if (inicio == null) {
      error = 'Escribe la hora de inicio, por ejemplo 19:00';
    } else if (fin == null) {
      error = 'Escribe la hora de fin, por ejemplo 5:00';
    } else if (inicio == fin) {
      error = 'La hora de fin no puede ser igual a la de inicio';
    }
    if (error != null) {
      _aviso(error);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeBuscaScreen(
          tipo: tipo!,
          fecha: fecha!,
          inicio: inicio!,
          fin: fin!,
          invitados: int.tryParse(_invitadosCtrl.text.trim()) ?? 0,
          notas: _notasCtrl.text.trim(),
          editar: widget.editar,
        ),
      ),
    );
  }

  // ---------- pantalla ----------

  // Campo de texto con su titulo, igual que los otros formularios
  Widget _campo({
    required String label,
    required String hint,
    required TextEditingController controller,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.campo),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: AppText.input.copyWith(color: Colors.black87),
          decoration: optimaDecoration(hint),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fecha = _fecha;
    final fechaCompleta = _fechaCtrl.text.length == 10;
    final duracion = _duracionTexto;
    final horaFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
      LengthLimitingTextInputFormatter(5),
    ];

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(
                child: Text(
                  _editando ? 'Editar evento' : 'Crear evento',
                  style: AppText.title,
                ),
              ),
              Center(
                child: Text(
                  'Paso 1 de 2',
                  style: AppText.input.copyWith(color: AppColors.navy),
                ),
              ),
              const Divider(color: Colors.black87),
              const SizedBox(height: 12),

              OptimaDropdown<String>(
                label: 'Tipo de evento',
                hint: 'Elige un tipo',
                items: _tipos,
                initialValue: _tipo,
                onChanged: (v) => setState(() => _tipo = v),
              ),
              if (_tipo == 'Otro') ...[
                const SizedBox(height: 14),
                _campo(
                  label: 'Escribe el tipo de evento',
                  hint: 'ej: bautismo',
                  controller: _tipoOtroCtrl,
                ),
              ],
              const SizedBox(height: 14),

              _campo(
                label: 'Fecha',
                hint: '22/11/2026',
                controller: _fechaCtrl,
                keyboardType: TextInputType.datetime,
                formatters: [_FechaFormatter()],
              ),
              if (fecha != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Evento.formatoFecha(fecha),
                    style: AppText.input.copyWith(color: AppColors.navy),
                  ),
                )
              else if (fechaCompleta)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Esa fecha no existe',
                    style: AppText.input.copyWith(color: Colors.red.shade800),
                  ),
                ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _campo(
                      label: 'Hora de inicio',
                      hint: '19:00',
                      controller: _inicioCtrl,
                      keyboardType: TextInputType.datetime,
                      formatters: horaFormatters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(
                      label: 'Hora de fin',
                      hint: '5:00',
                      controller: _finCtrl,
                      keyboardType: TextInputType.datetime,
                      formatters: horaFormatters,
                    ),
                  ),
                ],
              ),
              if (duracion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    duracion,
                    style: AppText.input.copyWith(color: AppColors.navy),
                  ),
                ),
              const SizedBox(height: 14),

              _campo(
                label: 'Cantidad de invitados',
                hint: 'cantidad de personas',
                controller: _invitadosCtrl,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 14),

              _campo(
                label: 'Vestimenta u observaciones (opcional)',
                hint: 'ej: camisa blanca y pantalón negro',
                controller: _notasCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 28),
              Center(
                child: OptimaLink(text: 'Continuar', onPressed: _continuar),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}