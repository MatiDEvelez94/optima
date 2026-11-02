import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cuenta.dart';
import '../models/evento.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';

// Datos de un puesto mientras se completa la pantalla
class _PuestoForm {
  _PuestoForm(this.nombre, {this.nombreEditable = false});

  final String nombre;
  final bool nombreEditable; // true solo para "Otro"
  bool activo = false;
  final nombreCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController();
  final pagoCtrl = TextEditingController();

  int get cantidad => int.tryParse(cantidadCtrl.text.trim()) ?? 0;
  int get pagoHora => int.tryParse(pagoCtrl.text.trim()) ?? 0;

  void dispose() {
    nombreCtrl.dispose();
    cantidadCtrl.dispose();
    pagoCtrl.dispose();
  }
}

// Paso 2 de 2: que puestos se buscan, cuantas personas y el pago por hora
class SeBuscaScreen extends StatefulWidget {
  const SeBuscaScreen({
    super.key,
    required this.tipo,
    required this.fecha,
    required this.inicio,
    required this.fin,
    required this.invitados,
    required this.notas,
    this.editar,
  });

  final Evento? editar; // si viene, se modifica ese evento
  final String tipo;
  final DateTime fecha;
  final TimeOfDay inicio;
  final TimeOfDay fin;
  final int invitados;
  final String notas;

  @override
  State<SeBuscaScreen> createState() => _SeBuscaScreenState();
}

class _SeBuscaScreenState extends State<SeBuscaScreen> {
  final List<_PuestoForm> _forms = [
    _PuestoForm('Mozo'),
    _PuestoForm('Bachero'),
    _PuestoForm('Cocinero'),
    _PuestoForm('Limpieza'),
    _PuestoForm('Animación'),
    _PuestoForm('Bartender'),
    _PuestoForm('Decorador'),
    _PuestoForm('Otro', nombreEditable: true),
  ];

  bool get _editando => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    if (e == null) return;
    // Marca los puestos que el evento ya buscaba, con sus numeros
    for (final p in e.puestos) {
      var f = _forms.last; // "Otro"
      for (final candidato in _forms) {
        if (!candidato.nombreEditable &&
            candidato.nombre.toLowerCase() == p.profesion.toLowerCase()) {
          f = candidato;
        }
      }
      f.activo = true;
      if (f.nombreEditable) f.nombreCtrl.text = p.profesion;
      f.cantidadCtrl.text = '${p.cantidad}';
      f.pagoCtrl.text = '${p.pagoHora}';
    }
  }

  @override
  void dispose() {
    for (final f in _forms) {
      f.dispose();
    }
    super.dispose();
  }

  double get _horas => Evento.calcularHoras(widget.inicio, widget.fin);

  int _costo(_PuestoForm f) => (f.cantidad * _horas * f.pagoHora).round();

  int get _costoTotal => _forms
      .where((f) => f.activo)
      .fold<int>(0, (suma, f) => suma + _costo(f));

  bool get _hayPuestos => _forms.any((f) => f.activo);

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void _publicar() {
    final puestos = <Puesto>[];
    for (final f in _forms) {
      if (!f.activo) continue;
      final nombre = f.nombreEditable ? f.nombreCtrl.text.trim() : f.nombre;
      if (nombre.isEmpty) {
        _aviso('Escribe el nombre del puesto en "Otro"');
        return;
      }
      if (f.cantidad < 1 || f.pagoHora < 1) {
        _aviso('Completa cantidad y pago por hora de $nombre');
        return;
      }
      puestos.add(
        Puesto(profesion: nombre, cantidad: f.cantidad, pagoHora: f.pagoHora),
      );
    }
    if (puestos.isEmpty) {
      _aviso('Marca al menos un puesto');
      return;
    }

    final editado = widget.editar;
    if (editado != null) {
      // Se modifica el mismo evento (se conservan los confirmados)
      editado
        ..tipo = widget.tipo
        ..fecha = widget.fecha
        ..inicio = widget.inicio
        ..fin = widget.fin
        ..invitados = widget.invitados
        ..puestos = puestos
        ..notas = widget.notas;
      final dueno = UserSession.cuentaActual;
      if (dueno != null) Cuenta.sincronizarEvento(dueno, editado);
    } else {
      Evento.publicados.add(
        Evento(
          tipo: widget.tipo,
          fecha: widget.fecha,
          inicio: widget.inicio,
          fin: widget.fin,
          invitados: widget.invitados,
          puestos: puestos,
          notas: widget.notas,
        ),
      );
    }

    // Vuelve al inicio y avisa
    final messenger = ScaffoldMessenger.of(context);
    Navigator.popUntil(context, (route) => route.isFirst);
    messenger.showSnackBar(
      SnackBar(
        content: Text(_editando ? 'Evento actualizado' : 'Evento publicado'),
      ),
    );
  }

  Widget _numero({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      style: AppText.input.copyWith(color: Colors.black87),
      decoration: optimaDecoration(hint),
    );
  }

  Widget _buildPuesto(_PuestoForm f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: f.activo,
            onChanged: (v) => setState(() => f.activo = v ?? false),
            activeColor: AppColors.navy,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              f.nombre,
              style: AppText.input.copyWith(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (f.activo) ...[
            if (f.nombreEditable) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: TextField(
                  controller: f.nombreCtrl,
                  style: AppText.input.copyWith(color: Colors.black87),
                  decoration: optimaDecoration('nombre del puesto'),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _numero(
                      controller: f.cantidadCtrl,
                      hint: 'cantidad',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numero(
                      controller: f.pagoCtrl,
                      hint: '\$ por hora',
                    ),
                  ),
                ],
              ),
            ),
            if (f.cantidad > 0 && f.pagoHora > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Text(
                  'Subtotal ${Evento.formatoDinero(_costo(f))}  '
                  '(${f.cantidad} x ${Evento.formatoHoras(_horas)} x '
                  '${Evento.formatoDinero(f.pagoHora)})',
                  style: AppText.input.copyWith(fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _editando ? 'Editar puestos' : 'Se busca',
                  style: AppText.title,
                ),
              ),
              Center(
                child: Text(
                  'Paso 2 de 2',
                  style: AppText.input.copyWith(color: AppColors.navy),
                ),
              ),
              const Divider(color: Colors.black87),
              const SizedBox(height: 8),

              // Resumen del paso anterior
              Text(
                '${widget.tipo} - ${Evento.formatoFecha(widget.fecha)}\n'
                '${Evento.formatoHora(widget.inicio)} a '
                '${Evento.formatoHora(widget.fin)} '
                '(${Evento.formatoHoras(_horas)})',
                style: AppText.input.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              Text(
                'Marca los puestos que necesitas y completa cuántas '
                'personas y cuánto pagas por hora.',
                style: AppText.subtitle.copyWith(fontSize: 14, letterSpacing: 0.3),
              ),
              const SizedBox(height: 16),

              for (final f in _forms) _buildPuesto(f),

              if (_hayPuestos && _costoTotal > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Costo total estimado', style: AppText.eventText),
                      Text(
                        Evento.formatoDinero(_costoTotal),
                        style: AppText.banner,
                      ),
                      Text(
                        'cantidad x horas x pago por hora',
                        style: AppText.eventText.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: _publicar,
                  child: Text(
                    _editando ? 'Guardar cambios' : 'Publicar evento',
                    style: AppText.link.copyWith(
                      color: AppColors.cream,
                      decorationColor: AppColors.cream,
                    ),
                  ),
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
